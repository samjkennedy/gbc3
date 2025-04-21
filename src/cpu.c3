module cpu;

import std::io;
import std::core::string;

import mmu;

struct Cpu {
    ulong clk; //Clock

    //registers
    ushort af; //Accumulator & Flags
    ushort bc;
    ushort de;
    ushort hl;
    ushort sp; //Stack Pointer
    ushort pc; //Program Counter

    //state
    CpuState state;
    char remaining_cycles;

    bool ime_ready; //Maybe needs a better name, set by EI to trigger ime on the next instruction
    bool ime; //Interrupt Master Enable
}

fn Cpu init() {
    return (Cpu) {
        0,      //clk
        0x01B0, //af
        0x0013, //bc
        0x00D8, //de
        0x014D, //hl
        0xFFFE, //sp
        0x0100, //pc
        CpuState.FETCH, //state
        0,      //cycles
        false,  //ime ready
        false   //ime
    };
}

enum Register: char {
    A,
    B,
    C,
    D,
    E,
    H,
    L,
}

enum WideRegister: char {
    AF,
    BC,
    DE,
    HL,
    SP,
}

enum Flag: char {
    Z,
    N,
    H,
    C,
}

enum CpuState: char {
    FETCH,
    EXECUTE,
    HALT,
}

//Fetches the byte at the stack pointer and advances the stack pointer
fn char Cpu.fetch_byte(&self, Mmu* mmu) {
    char byte = mmu.read(self.pc);

    self.pc += 1;
    self.remaining_cycles += 4;

    return byte;
}

//Fetches the next two bytes [lo hi] at the stack pointer and advances the stack pointer by 2
fn ushort Cpu.fetch_word(&self, Mmu* mmu) {
    ushort lo = (ushort) self.fetch_byte(mmu);
    ushort hi = (ushort) self.fetch_byte(mmu);

    return (hi << 8) | lo;
}

fn char get_bit(char value, char bit) {
    return (char) ((value & (1 << bit)) != 0);
}

const ulong DIV_FREQUENCY = 16384; //TODO: different on SGB

fn void? Cpu.tick(&self, Mmu* mmu) {

    //handle registers
    //update DIV register
    if (self.clk % DIV_FREQUENCY == 0) {
        char div = mmu.read(mmu::DIV_REGISTER);
        mmu.write_unchecked(mmu::DIV_REGISTER, div + 1);
    }

    //update TIMA register
    {
        char tac = mmu.read(mmu::TAC_REGISTER);
        char input_clock_select = (get_bit(tac, 1) << 1) | get_bit(tac, 1);
        bool timer_enable = get_bit(tac, 2) > 0;
        
        uint timer_frequency = 0;
        switch (input_clock_select) {
            case 0b00: timer_frequency = 4096;
            case 0b01: timer_frequency = 262144;
            case 0b10: timer_frequency = 65536;
            case 0b11: timer_frequency = 16384;
        }

        if (timer_enable && self.clk % timer_frequency == 0) {            
            //This timer is incremented at the clock frequency specified by the TAC register ($FF07).
            //When the value overflows (exceeds $FF) it is reset to the value specified in TMA (FF06) and an interrupt is requested
            char tima = mmu.read(mmu::TIMA_REGISTER);

            if (tima == 0xFF) {
                //TODO: set interrupt flag
                mmu.set_interrupt_flag(mmu::Interrupt.TIMER);
                mmu.write_unchecked(mmu::TIMA_REGISTER, mmu.read(mmu::TMA_REGISTER));
            } else {
                mmu.write_unchecked(mmu::TIMA_REGISTER, tima + 1);
            }
        }
    }

    //handle interrupts
    //I believe interrupts are actioned 1 tick before the next fetch
    if (self.remaining_cycles % 4 == 1) {
        self.handle_interrupts(mmu);
    }

    //OAM DMA Transfer
    //I'm not entirely happy with this being how I do it, but I can't think of anything better right now
    // if (mmu.dma_transfer_cycles_remaining > 0) {
    //     if (mmu.dma_transfer_cycles_remaining % 4 == 0) {
    //         mmu.oam_dma_transfer_cycle();
    //     }
    //     mmu.dma_transfer_cycles_remaining--;
    // }

    //fetch-decode-execute
    switch (self.state) {
        case FETCH:
            self.execute(mmu)!!;
            self.state = EXECUTE;

        case EXECUTE:
            self.remaining_cycles--;
            if (self.remaining_cycles == 0) {
                self.state = FETCH;
            }

        case HALT:
            if (self.remaining_cycles != 0) {
                self.remaining_cycles--;
            } else {
                if (mmu.read(mmu::IE_REGISTER) & mmu.read(mmu::IF_REGISTER) > 0) {
                    self.state = FETCH;
                }
            }
    }

    self.clk++;
}

fn void Cpu.handle_interrupts(&self, Mmu* mmu) {
       
    self.handle_interrupt(mmu::Interrupt.V_BLANK, mmu);
    self.handle_interrupt(mmu::Interrupt.STAT, mmu);
    self.handle_interrupt(mmu::Interrupt.TIMER, mmu);
    self.handle_interrupt(mmu::Interrupt.SERIAL, mmu);
    self.handle_interrupt(mmu::Interrupt.JOYPAD, mmu);
}

fn void Cpu.handle_interrupt(&self, mmu::Interrupt interrupt, Mmu* mmu) {

    if (!self.ime) {
        return;
    }
    if (!mmu.get_interrupt_flag(interrupt)) {
        return;
    }

    //The CPU automatically disables all the other interrupts by setting IME=0 when it services an interrupt.
    self.ime = false;

    mmu.clear_interrupt_flag(interrupt);
    
    self.sp -= 2;
    mmu.write_unchecked(self.sp, (char) (self.pc & 0x00FF));
    mmu.write_unchecked(self.sp + 1, (char) ((self.pc & 0xFF00) >> 8));

    self.pc = interrupt.vector;
    self.remaining_cycles = 20;
    self.state = FETCH;
}

faultdef NOT_IMPLEMENTED, BAD_INSTRUCTION;

fn void? Cpu.execute(&self, Mmu* mmu) {

    char code = self.fetch_byte(mmu);

    switch (code) {
        case 0x00: break;
        case 0x01: self.load_n16(mmu, WideRegister.BC);
        case 0x02: self.load_r16_a(mmu, WideRegister.BC);
        case 0x03: self.inc_wide(WideRegister.BC);
        case 0x04: self.inc(Register.B);
        case 0x05: self.dec(Register.B);
        case 0x06: self.load_n8(mmu, Register.B);
        case 0x07: self.rlca();
        case 0x08: self.ld_a16_sp(mmu);
        case 0x09: self.add_hl(WideRegister.BC);
        case 0x0A: self.ld_a_wide(mmu, WideRegister.BC);
        case 0x0B: self.dec_wide(WideRegister.BC);
        case 0x0C: self.inc(Register.C);
        case 0x0D: self.dec(Register.C);
        case 0x0E: self.load_n8(mmu, Register.C);
        case 0x0F: self.rrca();

        case 0x10: break; //TODO: what to do?
        case 0x11: self.load_n16(mmu, WideRegister.DE);
        case 0x12: self.load_r16_a(mmu, WideRegister.DE);
        case 0x13: self.inc_wide(WideRegister.DE);
        case 0x14: self.inc(Register.D);
        case 0x15: self.dec(Register.D);
        case 0x16: self.load_n8(mmu, Register.D);
        case 0x17: self.rla();
        case 0x18: self.jr(mmu);
        case 0x19: self.add_hl(WideRegister.DE);
        case 0x1A: self.ld_a_wide(mmu, WideRegister.DE);
        case 0x1B: self.dec_wide(WideRegister.DE);
        case 0x1C: self.inc(Register.E);
        case 0x1D: self.dec(Register.E);
        case 0x1E: self.load_n8(mmu, Register.E);
        case 0x1F: self.rra();

        case 0x20: self.jr_cc(mmu, Flag.Z, false);
        case 0x21: self.load_n16(mmu, WideRegister.HL);
        case 0x22: self.ldi_hl_a(mmu);
        case 0x23: self.inc_wide(WideRegister.HL);
        case 0x24: self.inc(Register.H);
        case 0x25: self.dec(Register.H);
        case 0x26: self.load_n8(mmu, Register.H);
        case 0x27: self.daa();
        case 0x28: self.jr_cc(mmu, Flag.Z, true);
        case 0x29: self.add_hl(WideRegister.HL);
        case 0x2A: self.ldi_a_hl(mmu);
        case 0x2B: self.dec_wide(WideRegister.HL);
        case 0x2C: self.inc(Register.L);
        case 0x2D: self.dec(Register.L);
        case 0x2E: self.load_n8(mmu, Register.L);
        case 0x2F: self.cpl();

        case 0x30: self.jr_cc(mmu, Flag.C, false);
        case 0x31: self.load_n16(mmu, WideRegister.SP);
        case 0x32: self.ldd_hl_a(mmu);
        case 0x33: self.inc_wide(WideRegister.SP);
        case 0x34: self.inc_hl_ind(mmu);
        case 0x35: self.dec_hl_ind(mmu);
        case 0x36: self.load_hl_n8(mmu);
        case 0x37: self.scf();
        case 0x38: self.jr_cc(mmu, Flag.C, true);
        case 0x39: self.add_hl(WideRegister.SP);
        case 0x3A: self.ldd_a_hl(mmu);
        case 0x3B: self.dec_wide(WideRegister.SP);
        case 0x3C: self.inc(Register.A);
        case 0x3D: self.dec(Register.A);
        case 0x3E: self.load_n8(mmu, Register.A);
        case 0x3F: self.ccf();

        case 0x40: self.load(Register.B, Register.B);
        case 0x41: self.load(Register.B, Register.C);
        case 0x42: self.load(Register.B, Register.D);
        case 0x43: self.load(Register.B, Register.E);
        case 0x44: self.load(Register.B, Register.H);
        case 0x45: self.load(Register.B, Register.L);
        case 0x46: self.load_hl(mmu, Register.B);
        case 0x47: self.load(Register.B, Register.A);
        case 0x48: self.load(Register.C, Register.B);
        case 0x49: self.load(Register.C, Register.C);
        case 0x4A: self.load(Register.C, Register.D);
        case 0x4B: self.load(Register.C, Register.E);
        case 0x4C: self.load(Register.C, Register.H);
        case 0x4D: self.load(Register.C, Register.L);
        case 0x4E: self.load_hl(mmu, Register.C);
        case 0x4F: self.load(Register.C, Register.A);

        case 0x50: self.load(Register.D, Register.B);
        case 0x51: self.load(Register.D, Register.C);
        case 0x52: self.load(Register.D, Register.D);
        case 0x53: self.load(Register.D, Register.E);
        case 0x54: self.load(Register.D, Register.H);
        case 0x55: self.load(Register.D, Register.L);
        case 0x56: self.load_hl(mmu, Register.D);
        case 0x57: self.load(Register.D, Register.A);
        case 0x58: self.load(Register.E, Register.B);
        case 0x59: self.load(Register.E, Register.C);
        case 0x5A: self.load(Register.E, Register.D);
        case 0x5B: self.load(Register.E, Register.E);
        case 0x5C: self.load(Register.E, Register.H);
        case 0x5D: self.load(Register.E, Register.L);
        case 0x5E: self.load_hl(mmu, Register.E);
        case 0x5F: self.load(Register.E, Register.A);

        case 0x60: self.load(Register.H, Register.B);
        case 0x61: self.load(Register.H, Register.C);
        case 0x62: self.load(Register.H, Register.D);
        case 0x63: self.load(Register.H, Register.E);
        case 0x64: self.load(Register.H, Register.H);
        case 0x65: self.load(Register.H, Register.L);
        case 0x66: self.load_hl(mmu, Register.H);
        case 0x67: self.load(Register.H, Register.A);
        case 0x68: self.load(Register.L, Register.B);
        case 0x69: self.load(Register.L, Register.C);
        case 0x6A: self.load(Register.L, Register.D);
        case 0x6B: self.load(Register.L, Register.E);
        case 0x6C: self.load(Register.L, Register.H);
        case 0x6D: self.load(Register.L, Register.L);
        case 0x6E: self.load_hl(mmu, Register.L);
        case 0x6F: self.load(Register.L, Register.A);

        case 0x70: self.load_hl_r(mmu, Register.B);
        case 0x71: self.load_hl_r(mmu, Register.C);
        case 0x72: self.load_hl_r(mmu, Register.D);
        case 0x73: self.load_hl_r(mmu, Register.E);
        case 0x74: self.load_hl_r(mmu, Register.H);
        case 0x75: self.load_hl_r(mmu, Register.L);
        case 0x76: self.state = HALT;
        case 0x77: self.load_hl_r(mmu, Register.A);
        case 0x78: self.load(Register.A, Register.B);
        case 0x79: self.load(Register.A, Register.C);
        case 0x7A: self.load(Register.A, Register.D);
        case 0x7B: self.load(Register.A, Register.E);
        case 0x7C: self.load(Register.A, Register.H);
        case 0x7D: self.load(Register.A, Register.L);
        case 0x7E: self.load_hl(mmu, Register.A);
        case 0x7F: self.load(Register.A, Register.A);

        case 0x80: self.add(Register.B);
        case 0x81: self.add(Register.C);
        case 0x82: self.add(Register.D);
        case 0x83: self.add(Register.E);
        case 0x84: self.add(Register.H);
        case 0x85: self.add(Register.L);
        case 0x86: self.add_a_hl(mmu);
        case 0x87: self.add(Register.A);
        case 0x88: self.adc(Register.B);
        case 0x89: self.adc(Register.C);
        case 0x8A: self.adc(Register.D);
        case 0x8B: self.adc(Register.E);
        case 0x8C: self.adc(Register.H);
        case 0x8D: self.adc(Register.L);
        case 0x8E: self.adc_a_hl(mmu);
        case 0x8F: self.adc(Register.A);
        
        case 0x90: self.sub(Register.B);
        case 0x91: self.sub(Register.C);
        case 0x92: self.sub(Register.D);
        case 0x93: self.sub(Register.E);
        case 0x94: self.sub(Register.H);
        case 0x95: self.sub(Register.L);
        case 0x96: self.sub_hl(mmu);
        case 0x97: self.sub(Register.A);
        case 0x98: self.sbc(Register.B);
        case 0x99: self.sbc(Register.C);
        case 0x9A: self.sbc(Register.D);
        case 0x9B: self.sbc(Register.E);
        case 0x9C: self.sbc(Register.H);
        case 0x9D: self.sbc(Register.L);
        case 0x9E: self.sbc_hl(mmu);
        case 0x9F: self.sbc(Register.A);

        case 0xA0: self.and(Register.B);
        case 0xA1: self.and(Register.C);
        case 0xA2: self.and(Register.D);
        case 0xA3: self.and(Register.E);
        case 0xA4: self.and(Register.H);
        case 0xA5: self.and(Register.L);
        case 0xA6: self.and_hl(mmu);
        case 0xA7: self.and(Register.A);
        case 0xA8: self.xor(Register.B);
        case 0xA9: self.xor(Register.C);
        case 0xAA: self.xor(Register.D);
        case 0xAB: self.xor(Register.E);
        case 0xAC: self.xor(Register.H);
        case 0xAD: self.xor(Register.L);
        case 0xAE: self.xor_hl(mmu);
        case 0xAF: self.xor(Register.A);

        case 0xB0: self.or(Register.B);
        case 0xB1: self.or(Register.C);
        case 0xB2: self.or(Register.D);
        case 0xB3: self.or(Register.E);
        case 0xB4: self.or(Register.H);
        case 0xB5: self.or(Register.L);
        case 0xB6: self.or_hl(mmu);
        case 0xB7: self.or(Register.A);
        case 0xB8: self.cp(Register.B);
        case 0xB9: self.cp(Register.C);
        case 0xBA: self.cp(Register.D);
        case 0xBB: self.cp(Register.E);
        case 0xBC: self.cp(Register.H);
        case 0xBD: self.cp(Register.L);
        case 0xBE: self.cp_hl(mmu);
        case 0xBF: self.cp(Register.A);

        case 0xC0: self.ret_cc(mmu, Flag.Z, false);
        case 0xC1: self.pop(mmu, WideRegister.BC);
        case 0xC2: self.jp_cc(mmu, Flag.Z, false);
        case 0xC3: self.pc = self.fetch_word(mmu);
        case 0xC4: self.call_cc(mmu, Flag.Z, false);
        case 0xC5: self.push(mmu, WideRegister.BC);
        case 0xC6: self.add_a_n8(mmu);
        case 0xC7: self.reset(mmu, 0x00);
        case 0xC8: self.ret_cc(mmu, Flag.Z, true);
        case 0xC9: self.ret(mmu);
        case 0xCA: self.jp_cc(mmu, Flag.Z, true);
        case 0xCB: self.prefix(mmu);
        case 0xCC: self.call_cc(mmu, Flag.Z, true);
        case 0xCD: self.call(mmu);
        case 0xCE: self.adc_a_n8(mmu);
        case 0xCF: self.reset(mmu, 0x08);

        case 0xD0: self.ret_cc(mmu, Flag.C, false);
        case 0xD1: self.pop(mmu, WideRegister.DE);
        case 0xD2: self.jp_cc(mmu, Flag.C, false);

        case 0xD4: self.call_cc(mmu, Flag.C, false);
        case 0xD5: self.push(mmu, WideRegister.DE);
        case 0xD6: self.sub_a_n8(mmu);
        case 0xD7: self.reset(mmu, 0x10);
        case 0xD8: self.ret_cc(mmu, Flag.C, true);
        case 0xD9: self.reti(mmu);
        case 0xDA: self.jp_cc(mmu, Flag.C, true);

        case 0xDC: self.call_cc(mmu, Flag.C, true);

        case 0xDE: self.sbc_a_n8(mmu);
        case 0xDF: self.reset(mmu, 0x18);

        case 0xE0: self.load_a8_a(mmu);
        case 0xE1: self.pop(mmu, WideRegister.HL);
        case 0xE2: self.load_c_a(mmu);


        case 0xE5: self.push(mmu, WideRegister.HL);
        case 0xE6: self.and_a_n8(mmu);
        case 0xE7: self.reset(mmu, 0x20);
        case 0xE8: self.add_sp_s8(mmu);
        case 0xE9: self.pc = self.get_wide_register(WideRegister.HL);
        case 0xEA: self.load_a16_a(mmu);



        case 0xEE: self.xor_a_n8(mmu);
        case 0xEF: self.reset(mmu, 0x28);
        
        case 0xF0: self.load_a_a8(mmu);
        case 0xF1: self.pop(mmu, WideRegister.AF);
        case 0xF2: self.load_a_c(mmu);
        case 0xF3: self.di();

        case 0xF5: self.push(mmu, WideRegister.AF);
        case 0xF6: self.or_a_n8(mmu);
        case 0xF7: self.reset(mmu, 0x30);
        case 0xF8: self.ld_hl_sp_s8(mmu);
        case 0xF9: self.set_wide_register(WideRegister.SP, self.get_wide_register(WideRegister.HL));
        case 0xFA: self.load_a_a16(mmu);
        case 0xFB: self.ei();


        case 0xFE: self.cp_n8(mmu);
        case 0xFF: self.reset(mmu, 0x38);

        default:
        io::printfn("executing opcode %s is not implemented", code);
            return NOT_IMPLEMENTED?;
    }

    //The effect of ei is delayed by one instruction.
    if (code != 0xFB && self.ime_ready) {
        self.ime_ready = false;
        self.ime = true;
    }
}

fn char Cpu.get_register(&self, Register reg) {

    switch (reg) {
        case A: return (char) ((self.af & 0xFF00) >> 8);
        case B: return (char) ((self.bc & 0xFF00) >> 8);
        case C: return (char) (self.bc & 0x00FF);
        case D: return (char) ((self.de & 0xFF00) >> 8);
        case E: return (char) (self.de & 0x00FF);
        case H: return (char) ((self.hl & 0xFF00) >> 8);
        case L: return (char) (self.hl & 0x00FF);
    }
}

fn void Cpu.set_register(&self, Register reg, char value) {

    switch (reg) {
        case A: self.af = (self.af & 0x00FF) | (((ushort)value) << 8);
        case B: self.bc = (self.bc & 0x00FF) | (((ushort)value) << 8);
        case C: self.bc = (self.bc & 0xFF00) | (ushort)value;
        case D: self.de = (self.de & 0x00FF) | (((ushort)value) << 8);
        case E: self.de = (self.de & 0xFF00) | (ushort)value;
        case H: self.hl = (self.hl & 0x00FF) | (((ushort)value) << 8);
        case L: self.hl = (self.hl & 0xFF00) | (ushort)value;
    }
}

fn ushort Cpu.get_wide_register(&self, WideRegister wide_register) {
    switch (wide_register) {
        case AF: return self.af;
        case BC: return self.bc;
        case DE: return self.de;
        case HL: return self.hl;
        case SP: return self.sp;
    }
}

fn void Cpu.set_wide_register(&self, WideRegister wide_register, ushort value) {
    switch (wide_register) {
        case AF: self.af = value & 0xFFF0; //bottom 4 bits of F are always 0
        case BC: self.bc = value;
        case DE: self.de = value;
        case HL: self.hl = value;
        case SP: self.sp = value;
    }
}

fn bool Cpu.get_flag(&self, Flag flag) {
    char f = (char) (self.af & 0x00FF);
    switch (flag) {
        case Z: return f & 0b10000000 != 0;
        case N: return f & 0b01000000 != 0;
        case H: return f & 0b00100000 != 0;
        case C: return f & 0b00010000 != 0;
    }
}

fn void Cpu.set_flag(&self, Flag flag, bool value) {
    switch (flag) {
        case Z: {
            if (value) {
                self.af |= (ushort)0b00000000_10000000;
            } else {
                self.af &= (ushort)~0b00000000_10000000;
            }
        }
        case N: {
            if (value) {
                self.af |= (ushort)0b00000000_01000000;
            } else {
                self.af &= (ushort)~0b00000000_01000000;
            }
        }
        case H: {
            if (value) {
                self.af |= (ushort)0b00000000_00100000;
            } else {
                self.af &= (ushort)~0b00000000_00100000;
            }
        }
        case C: {
            if (value) {
                self.af |= (ushort)0b00000000_00010000;
            } else {
                self.af &= (ushort)~0b00000000_00010000;
            }
        }
    }
}

fn void Cpu.inc(&self, Register reg) {
    
    char r = self.get_register(reg);

    char value = r + 1;

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, (r ^ 1 ^ value) & 0x10 == 0x10);
    self.set_register(reg, value);
}

fn void Cpu.dec(&self, Register reg) {
    
    char r = self.get_register(reg);

    char value = r - 1;

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, true);
    self.set_flag(Flag.H, ((r & 0xf) - (1 & 0xf)) & 0x10 == 0x10);

    self.set_register(reg, value);
}

fn void Cpu.inc_wide(&self, WideRegister reg) {
    
    ushort r = self.get_wide_register(reg);

    ushort value = r + 1;

    self.set_wide_register(reg, value);
}

fn void Cpu.inc_hl_ind(&self, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);

    char r = mmu.read(addr);
    char value = r + 1;
    
    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, (r ^ 1 ^ value) & 0x10 == 0x10);

    mmu.write(addr, value);
}

fn void Cpu.dec_hl_ind(&self, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);

    char r = mmu.read(addr);
    char value = r - 1;
    
    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, true);
    self.set_flag(Flag.H, (r ^ 1 ^ value) & 0x10 == 0x10);

    mmu.write(addr, value);
}

fn void Cpu.dec_wide(&self, WideRegister wide_register) {
    
    ushort r = self.get_wide_register(wide_register);

    ushort value = r - 1;

    self.set_wide_register(wide_register, value);
}

fn void Cpu.load(&self, Register dst, Register src) {

    char value = self.get_register(src);
    
    self.set_register(dst, value);
}

fn void Cpu.load_hl(&self, Mmu* mmu, Register dst) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char value = mmu.read(addr);
    
    self.set_register(dst, value);
}

fn void Cpu.load_hl_r(&self, Mmu* mmu, Register src) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char value = self.get_register(src);
    
    mmu.write(addr, value);
}

fn void Cpu.cpl(&self) {
    //A = A xor FF, or A = ~A

    char a = self.get_register(Register.A);
    self.set_register(Register.A, ~a);
    
    self.set_flag(Flag.N, true);
    self.set_flag(Flag.H, true);
}

fn void Cpu.add(&self, Register src) {
    //Always adds into A

    char a = self.get_register(Register.A);
    char r = self.get_register(src);

    char value = a + r;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, ((a & 0xf) + (r & 0xf)) & 0x10 == 0x10);
    self.set_flag(Flag.C, value < a);
}
fn void Cpu.add_a_hl(&self, Mmu* mmu) {
    //Always adds into A

    char a = self.get_register(Register.A);
    char r = mmu.read(self.get_wide_register(WideRegister.HL));

    char value = a + r;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, ((a & 0xf) + (r & 0xf)) & 0x10 == 0x10);
    self.set_flag(Flag.C, value < a);
}

fn void Cpu.add_a_n8(&self, Mmu* mmu) {

    char value = self.fetch_byte(mmu);

    char a = self.get_register(Register.A);

    char result = a + value;

    self.set_register(Register.A, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, ((a & 0xf) + (value & 0xf)) & 0x10 == 0x10);
    self.set_flag(Flag.C, result < a);
}

fn void Cpu.adc(&self, Register src) {
    //Always adds into A

    char a = self.get_register(Register.A);
    char r = self.get_register(src);
    char c = self.get_flag(Flag.C) ? 1 : 0;

    bool carry = false;
    char tmp_value = a + r;
    carry = tmp_value < a;
    char value = tmp_value + c;
    carry = carry || value < tmp_value;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, ((a & 0xf) + (r & 0xf) + c) > 0xF);
    self.set_flag(Flag.C, carry);
}

fn void Cpu.adc_a_hl(&self, Mmu* mmu) {
    //Always adds into A

    char a = self.get_register(Register.A);
    char r = mmu.read(self.get_wide_register(WideRegister.HL));
    char c = self.get_flag(Flag.C) ? 1 : 0;

    bool carry = false;
    char tmp_value = a + r;
    carry = tmp_value < a;
    char value = tmp_value + c;
    carry = carry || value < tmp_value;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, ((a & 0xf) + (r & 0xf) + c) > 0xF);
    self.set_flag(Flag.C, carry);
}

fn void Cpu.adc_a_n8(&self, Mmu* mmu) {
    //Always adds into A

    char a = self.get_register(Register.A);
    char r = self.fetch_byte(mmu);
    char c = self.get_flag(Flag.C) ? 1 : 0;

    bool carry = false;
    char tmp_value = a + r;
    carry = tmp_value < a;
    char value = tmp_value + c;
    carry = carry || value < tmp_value;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, ((a & 0xf) + (r & 0xf) + c) > 0xF);
    self.set_flag(Flag.C, carry);
}

fn void Cpu.sub(&self, Register src) {
    //Always subs into A

    char a = self.get_register(Register.A);
    char r = self.get_register(src);

    char result = a - r;

    self.set_register(Register.A, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, true);
    self.set_flag(Flag.H, ((a & 0xf) - (r & 0xf)) & 0x10 == 0x10);
    self.set_flag(Flag.C, result > a);
}

fn void Cpu.sub_a_n8(&self, Mmu* mmu) {
    //Always subs into A

    char a = self.get_register(Register.A);
    char value = self.fetch_byte(mmu);

    char result = a - value;

    self.set_register(Register.A, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, true);
    self.set_flag(Flag.H, ((a & 0xf) - (value & 0xf)) & 0x10 == 0x10);
    self.set_flag(Flag.C, result > a);
}

fn void Cpu.sub_hl(&self, Mmu* mmu) {
    //Always subs into A

    ushort addr = self.get_wide_register(WideRegister.HL);
    char a = self.get_register(Register.A);
    char r = mmu.read(addr);

    char value = a - r;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, true);
    self.set_flag(Flag.H, ((a & 0xf) - (r & 0xf)) & 0x10 == 0x10);
    self.set_flag(Flag.C, value > a);
}

fn void Cpu.sbc(&self, Register src) {
    //Always subs into A

    char a = self.get_register(Register.A);
    char r = self.get_register(src);
    char c = self.get_flag(Flag.C) ? 1 : 0;

    char value = a - r - c;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, true);
    self.set_flag(Flag.H, ((a & 0xf) - (r & 0xf) - (c & 0xF)) & 0x10 == 0x10);
    self.set_flag(Flag.C, value >= a && (r > 0 || c > 0));
}

fn void Cpu.sbc_hl(&self, Mmu* mmu) {
    //Always subs into A

    ushort addr = self.get_wide_register(WideRegister.HL);
    char a = self.get_register(Register.A);
    char r = mmu.read(addr);
    char c = self.get_flag(Flag.C) ? 1 : 0;

    char value = a - r - c;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, true);
    self.set_flag(Flag.H, ((a & 0xf) - (r & 0xf) - (c & 0xF)) & 0x10 == 0x10);
    self.set_flag(Flag.C, value >= a && (r > 0 || c > 0));
}

fn void Cpu.sbc_a_n8(&self, Mmu* mmu) {
    //Always subs into A

    char a = self.get_register(Register.A);
    char r = self.fetch_byte(mmu);
    char c = self.get_flag(Flag.C) ? 1 : 0;

    char value = a - r - c;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, true);
    self.set_flag(Flag.H, ((a & 0xf) - (r & 0xf) - (c & 0xF)) & 0x10 == 0x10);
    self.set_flag(Flag.C, value >= a && (r > 0 || c > 0));
}

fn void Cpu.and(&self, Register src) {
    //Always ands into A

    char a = self.get_register(Register.A);
    char r = self.get_register(src);

    char value = a & r;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, true);
    self.set_flag(Flag.C, false);
}

fn void Cpu.and_hl(&self, Mmu* mmu) {
    //Always ands into A

    char a = self.get_register(Register.A);
    char r = mmu.read(self.get_wide_register(WideRegister.HL));

    char value = a & r;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, true);
    self.set_flag(Flag.C, false);
}

fn void Cpu.and_a_n8(&self, Mmu* mmu) {
    //Always ands into A

    char a = self.get_register(Register.A);
    char r = self.fetch_byte(mmu);

    char value = a & r;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, true);
    self.set_flag(Flag.C, false);
}

fn void Cpu.xor(&self, Register src) {
    //Always xors into A

    char a = self.get_register(Register.A);
    char r = self.get_register(src);

    char value = a ^ r;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, false);
}

fn void Cpu.xor_hl(&self, Mmu* mmu) {
    //Always xors into A

    char a = self.get_register(Register.A);
    char r = mmu.read(self.get_wide_register(WideRegister.HL));

    char value = a ^ r;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, false);
}

fn void Cpu.or(&self, Register src) {
    //Always ors into A

    char a = self.get_register(Register.A);
    char r = self.get_register(src);

    char value = a | r;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, false);
}

fn void Cpu.or_hl(&self, Mmu* mmu) {
    //Always ors into A

    char a = self.get_register(Register.A);
    char r = mmu.read(self.get_wide_register(WideRegister.HL));

    char value = a | r;

    self.set_register(Register.A, value);

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, false);
}

fn void Cpu.or_a_n8(&self, Mmu* mmu) {
    //Always ors into A

    char a = self.get_register(Register.A);
    char value = self.fetch_byte(mmu);

    char result = a | value;

    self.set_register(Register.A, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, false);
}

fn void Cpu.cp(&self, Register src) {
    //Compare the contents of register B and the contents of register A by calculating A - B, and set the Z flag if they are equal.

    char a = self.get_register(Register.A);
    char r = self.get_register(src);

    char value = a - r;

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, true);
    self.set_flag(Flag.H, ((a & 0xf) - (r & 0xf)) & 0x10 == 0x10);
    self.set_flag(Flag.C, value > a);
}

fn void Cpu.cp_hl(&self, Mmu* mmu) {

    char a = self.get_register(Register.A);
    char r = mmu.read(self.get_wide_register(WideRegister.HL));

    char value = a - r;

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, true);
    self.set_flag(Flag.H, ((a & 0xf) - (r & 0xf)) & 0x10 == 0x10);
    self.set_flag(Flag.C, value > a);
}

fn void Cpu.cp_n8(&self, Mmu* mmu) {
    //Compare the contents of register B and the 8-bit immediate operand d8 by calculating A - d8, and set the Z flag if they are equal.

    char a = self.get_register(Register.A);
    char r = self.fetch_byte(mmu);

    char value = a - r;

    self.set_flag(Flag.Z, value == 0);
    self.set_flag(Flag.N, true);
    self.set_flag(Flag.H, ((a & 0xf) - (r & 0xf)) & 0x10 == 0x10);
    self.set_flag(Flag.C, value > a);
}

fn void Cpu.pop(&self, Mmu* mmu, WideRegister wide_register) {

    ushort lo = (ushort) mmu.read(self.sp);
    ushort hi = (ushort) mmu.read(self.sp + 1);
    self.sp += 2;

    ushort value = (hi << 8) | lo;

    self.set_wide_register(wide_register, value);
}

fn void Cpu.push(&self, Mmu* mmu,  WideRegister wide_register) {
    
    ushort value = self.get_wide_register(wide_register);
    
    char hi = (char) ((value & 0xFF00) >> 8);
    char lo = (char) (value & 0x00FF);

    mmu.write(self.sp - 1, hi);
    mmu.write(self.sp - 2, lo);

    self.sp -= 2;
}

fn void Cpu.ret(&self, Mmu* mmu) {

    ushort addr = mmu.read(self.sp) | (ushort) mmu.read(self.sp + 1) << 8;
    self.sp += 2;

    self.pc = addr;
}

fn void Cpu.reti(&self, Mmu* mmu) {
    self.ime = true;

    ushort addr = mmu.read(self.sp) | (ushort) mmu.read(self.sp + 1) << 8;
    self.sp += 2;

    self.pc = addr;
}

fn void Cpu.ret_cc(&self, Mmu* mmu, Flag flag, bool ret_if_set) {

    bool should_ret = false;

    switch (flag) {
        case Z: should_ret = ret_if_set == self.get_flag(Flag.Z);
        case N: should_ret = ret_if_set == self.get_flag(Flag.N);
        case H: should_ret = ret_if_set == self.get_flag(Flag.H);
        case C: should_ret = ret_if_set == self.get_flag(Flag.C);
    }

    if (should_ret) {

        ushort addr = mmu.read(self.sp) | (ushort) mmu.read(self.sp + 1) << 8;
        self.sp += 2;

        self.pc = addr;

        self.remaining_cycles += 12;
    }
}

fn void Cpu.prefix(&self, Mmu* mmu) {

    char opcode = self.fetch_byte(mmu);

    switch (opcode) {
        case 0x00: self.rlc(Register.B);
        case 0x01: self.rlc(Register.C);
        case 0x02: self.rlc(Register.D);
        case 0x03: self.rlc(Register.E);
        case 0x04: self.rlc(Register.H);
        case 0x05: self.rlc(Register.L);
        case 0x06: self.rlc_hl(mmu);
        case 0x07: self.rlc(Register.A);
        case 0x08: self.rrc(Register.B);
        case 0x09: self.rrc(Register.C);
        case 0x0A: self.rrc(Register.D);
        case 0x0B: self.rrc(Register.E);
        case 0x0C: self.rrc(Register.H);
        case 0x0D: self.rrc(Register.L);
        case 0x0E: self.rrc_hl(mmu);
        case 0x0F: self.rrc(Register.A);
        case 0x10: self.rl(Register.B);
        case 0x11: self.rl(Register.C);
        case 0x12: self.rl(Register.D);
        case 0x13: self.rl(Register.E);
        case 0x14: self.rl(Register.H);
        case 0x15: self.rl(Register.L);
        case 0x16: self.rl_hl(mmu);
        case 0x17: self.rl(Register.A);
        case 0x18: self.rr(Register.B);
        case 0x19: self.rr(Register.C);
        case 0x1A: self.rr(Register.D);
        case 0x1B: self.rr(Register.E);
        case 0x1C: self.rr(Register.H);
        case 0x1D: self.rr(Register.L);
        case 0x1E: self.rr_hl(mmu);
        case 0x1F: self.rr(Register.A);
        case 0x20: self.sla(Register.B);
        case 0x21: self.sla(Register.C);
        case 0x22: self.sla(Register.D);
        case 0x23: self.sla(Register.E);
        case 0x24: self.sla(Register.H);
        case 0x25: self.sla(Register.L);
        case 0x26: self.sla_hl(mmu);
        case 0x27: self.sla(Register.A);
        case 0x28: self.sra(Register.B);
        case 0x29: self.sra(Register.C);
        case 0x2A: self.sra(Register.D);
        case 0x2B: self.sra(Register.E);
        case 0x2C: self.sra(Register.H);
        case 0x2D: self.sra(Register.L);
        case 0x2E: self.sra_hl(mmu);
        case 0x2F: self.sra(Register.A);
        
        case 0x30: self.swap(Register.B);
        case 0x31: self.swap(Register.C);
        case 0x32: self.swap(Register.D);
        case 0x33: self.swap(Register.E);
        case 0x34: self.swap(Register.H);
        case 0x35: self.swap(Register.L);
        case 0x36: self.swap_hl(mmu);
        case 0x37: self.swap(Register.A);
        case 0x38: self.srl(Register.B);
        case 0x39: self.srl(Register.C);
        case 0x3A: self.srl(Register.D);
        case 0x3B: self.srl(Register.E);
        case 0x3C: self.srl(Register.H);
        case 0x3D: self.srl(Register.L);
        case 0x3E: self.srl_hl(mmu);
        case 0x3F: self.srl(Register.A);

        case 0x40: self.bit(0, Register.B);
        case 0x41: self.bit(0, Register.C);
        case 0x42: self.bit(0, Register.D);
        case 0x43: self.bit(0, Register.E);
        case 0x44: self.bit(0, Register.H);
        case 0x45: self.bit(0, Register.L);
        case 0x46: self.bit_hl(0, mmu);
        case 0x47: self.bit(0, Register.A);
        case 0x48: self.bit(1, Register.B);
        case 0x49: self.bit(1, Register.C);
        case 0x4A: self.bit(1, Register.D);
        case 0x4B: self.bit(1, Register.E);
        case 0x4C: self.bit(1, Register.H);
        case 0x4D: self.bit(1, Register.L);
        case 0x4E: self.bit_hl(1, mmu);
        case 0x4F: self.bit(1, Register.A);
        case 0x50: self.bit(2, Register.B);
        case 0x51: self.bit(2, Register.C);
        case 0x52: self.bit(2, Register.D);
        case 0x53: self.bit(2, Register.E);
        case 0x54: self.bit(2, Register.H);
        case 0x55: self.bit(2, Register.L);
        case 0x56: self.bit_hl(2, mmu);
        case 0x57: self.bit(2, Register.A);
        case 0x58: self.bit(3, Register.B);
        case 0x59: self.bit(3, Register.C);
        case 0x5A: self.bit(3, Register.D);
        case 0x5B: self.bit(3, Register.E);
        case 0x5C: self.bit(3, Register.H);
        case 0x5D: self.bit(3, Register.L);
        case 0x5E: self.bit_hl(3, mmu);
        case 0x5F: self.bit(3, Register.A);
        case 0x60: self.bit(4, Register.B);
        case 0x61: self.bit(4, Register.C);
        case 0x62: self.bit(4, Register.D);
        case 0x63: self.bit(4, Register.E);
        case 0x64: self.bit(4, Register.H);
        case 0x65: self.bit(4, Register.L);
        case 0x66: self.bit_hl(4, mmu);
        case 0x67: self.bit(4, Register.A);
        case 0x68: self.bit(5, Register.B);
        case 0x69: self.bit(5, Register.C);
        case 0x6A: self.bit(5, Register.D);
        case 0x6B: self.bit(5, Register.E);
        case 0x6C: self.bit(5, Register.H);
        case 0x6D: self.bit(5, Register.L);
        case 0x6E: self.bit_hl(5, mmu);
        case 0x6F: self.bit(5, Register.A);
        case 0x70: self.bit(6, Register.B);
        case 0x71: self.bit(6, Register.C);
        case 0x72: self.bit(6, Register.D);
        case 0x73: self.bit(6, Register.E);
        case 0x74: self.bit(6, Register.H);
        case 0x75: self.bit(6, Register.L);
        case 0x76: self.bit_hl(6, mmu);
        case 0x77: self.bit(6, Register.A);
        case 0x78: self.bit(7, Register.B);
        case 0x79: self.bit(7, Register.C);
        case 0x7A: self.bit(7, Register.D);
        case 0x7B: self.bit(7, Register.E);
        case 0x7C: self.bit(7, Register.H);
        case 0x7D: self.bit(7, Register.L);
        case 0x7E: self.bit_hl(7, mmu);
        case 0x7F: self.bit(7, Register.A);
        case 0x80: self.res(0, Register.B);
        case 0x81: self.res(0, Register.C);
        case 0x82: self.res(0, Register.D);
        case 0x83: self.res(0, Register.E);
        case 0x84: self.res(0, Register.H);
        case 0x85: self.res(0, Register.L);
        case 0x86: self.res_hl(mmu, 0);
        case 0x87: self.res(0, Register.A);
        case 0x88: self.res(1, Register.B);
        case 0x89: self.res(1, Register.C);
        case 0x8A: self.res(1, Register.D);
        case 0x8B: self.res(1, Register.E);
        case 0x8C: self.res(1, Register.H);
        case 0x8D: self.res(1, Register.L);
        case 0x8E: self.res_hl(mmu, 1);
        case 0x8F: self.res(1, Register.A);
        case 0x90: self.res(2, Register.B);
        case 0x91: self.res(2, Register.C);
        case 0x92: self.res(2, Register.D);
        case 0x93: self.res(2, Register.E);
        case 0x94: self.res(2, Register.H);
        case 0x95: self.res(2, Register.L);
        case 0x96: self.res_hl(mmu, 2);
        case 0x97: self.res(2, Register.A);
        case 0x98: self.res(3, Register.B);
        case 0x99: self.res(3, Register.C);
        case 0x9A: self.res(3, Register.D);
        case 0x9B: self.res(3, Register.E);
        case 0x9C: self.res(3, Register.H);
        case 0x9D: self.res(3, Register.L);
        case 0x9E: self.res_hl(mmu, 3);
        case 0x9F: self.res(3, Register.A);
        case 0xA0: self.res(4, Register.B);
        case 0xA1: self.res(4, Register.C);
        case 0xA2: self.res(4, Register.D);
        case 0xA3: self.res(4, Register.E);
        case 0xA4: self.res(4, Register.H);
        case 0xA5: self.res(4, Register.L);
        case 0xA6: self.res_hl(mmu, 4);
        case 0xA7: self.res(4, Register.A);
        case 0xA8: self.res(5, Register.B);
        case 0xA9: self.res(5, Register.C);
        case 0xAA: self.res(5, Register.D);
        case 0xAB: self.res(5, Register.E);
        case 0xAC: self.res(5, Register.H);
        case 0xAD: self.res(5, Register.L);
        case 0xAE: self.res_hl(mmu, 5);
        case 0xAF: self.res(5, Register.A);
        case 0xB0: self.res(6, Register.B);
        case 0xB1: self.res(6, Register.C);
        case 0xB2: self.res(6, Register.D);
        case 0xB3: self.res(6, Register.E);
        case 0xB4: self.res(6, Register.H);
        case 0xB5: self.res(6, Register.L);
        case 0xB6: self.res_hl(mmu, 6);
        case 0xB7: self.res(6, Register.A);
        case 0xB8: self.res(7, Register.B);
        case 0xB9: self.res(7, Register.C);
        case 0xBA: self.res(7, Register.D);
        case 0xBB: self.res(7, Register.E);
        case 0xBC: self.res(7, Register.H);
        case 0xBD: self.res(7, Register.L);
        case 0xBE: self.res_hl(mmu, 7);
        case 0xBF: self.res(7, Register.A);

        case 0xC0: self.set(0, Register.B);
        case 0xC1: self.set(0, Register.C);
        case 0xC2: self.set(0, Register.D);
        case 0xC3: self.set(0, Register.E);
        case 0xC4: self.set(0, Register.H);
        case 0xC5: self.set(0, Register.L);
        case 0xC6: self.set_hl(mmu, 0);
        case 0xC7: self.set(0, Register.A);
        case 0xC8: self.set(1, Register.B);
        case 0xC9: self.set(1, Register.C);
        case 0xCA: self.set(1, Register.D);
        case 0xCB: self.set(1, Register.E);
        case 0xCC: self.set(1, Register.H);
        case 0xCD: self.set(1, Register.L);
        case 0xCE: self.set_hl(mmu, 1);
        case 0xCF: self.set(1, Register.A);
        case 0xD0: self.set(2, Register.B);
        case 0xD1: self.set(2, Register.C);
        case 0xD2: self.set(2, Register.D);
        case 0xD3: self.set(2, Register.E);
        case 0xD4: self.set(2, Register.H);
        case 0xD5: self.set(2, Register.L);
        case 0xD6: self.set_hl(mmu, 2);
        case 0xD7: self.set(2, Register.A);
        case 0xD8: self.set(3, Register.B);
        case 0xD9: self.set(3, Register.C);
        case 0xDA: self.set(3, Register.D);
        case 0xDB: self.set(3, Register.E);
        case 0xDC: self.set(3, Register.H);
        case 0xDD: self.set(3, Register.L);
        case 0xDE: self.set_hl(mmu, 3);
        case 0xDF: self.set(3, Register.A);
        case 0xE0: self.set(4, Register.B);
        case 0xE1: self.set(4, Register.C);
        case 0xE2: self.set(4, Register.D);
        case 0xE3: self.set(4, Register.E);
        case 0xE4: self.set(4, Register.H);
        case 0xE5: self.set(4, Register.L);
        case 0xE6: self.set_hl(mmu, 4);
        case 0xE7: self.set(4, Register.A);
        case 0xE8: self.set(5, Register.B);
        case 0xE9: self.set(5, Register.C);
        case 0xEA: self.set(5, Register.D);
        case 0xEB: self.set(5, Register.E);
        case 0xEC: self.set(5, Register.H);
        case 0xED: self.set(5, Register.L);
        case 0xEE: self.set_hl(mmu, 5);
        case 0xEF: self.set(5, Register.A);
        case 0xF0: self.set(6, Register.B);
        case 0xF1: self.set(6, Register.C);
        case 0xF2: self.set(6, Register.D);
        case 0xF3: self.set(6, Register.E);
        case 0xF4: self.set(6, Register.H);
        case 0xF5: self.set(6, Register.L);
        case 0xF6: self.set_hl(mmu, 6);
        case 0xF7: self.set(6, Register.A);
        case 0xF8: self.set(7, Register.B);
        case 0xF9: self.set(7, Register.C);
        case 0xFA: self.set(7, Register.D);
        case 0xFB: self.set(7, Register.E);
        case 0xFC: self.set(7, Register.H);
        case 0xFD: self.set(7, Register.L);
        case 0xFE: self.set_hl(mmu, 7);
        case 0xFF: self.set(7, Register.A);
    }
}

fn void Cpu.rlc(&self, Register reg) {

    char r = self.get_register(reg);

    bool msb = (r & 0b10000000) > 0;

    char result = r << 1;
    result |= msb ? 1 : 0;

    self.set_register(reg, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, msb);

    self.remaining_cycles += 4;
}

fn void Cpu.rlc_hl(&self, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char r = mmu.read(addr);

    bool msb = (r & 0b10000000) > 0;

    char result = r << 1;
    result |= msb ? 1 : 0;

    mmu.write(addr, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, msb);

    self.remaining_cycles += 12;
}

fn void Cpu.rrc(&self, Register reg) {

    char r = self.get_register(reg);

    bool lsb = (r & 1) > 0;

    char result = r >> 1;
    result |= lsb ? 0b10000000 : 0;

    self.set_register(reg, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, lsb);

    self.remaining_cycles += 4;
}

fn void Cpu.rrc_hl(&self, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char r = mmu.read(addr);

    bool lsb = (r & 1) > 0;

    char result = r >> 1;
    result |= lsb ? 0b10000000 : 0;

    mmu.write(addr, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, lsb);

    self.remaining_cycles += 12;
}


fn void Cpu.rl(&self, Register reg) {

    char r = self.get_register(reg);

    bool msb = (r & 0b10000000) > 0;

    char result = r << 1;
    if (self.get_flag(Flag.C)) {
        result |= 1;
    }

    self.set_register(reg, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, msb);

    self.remaining_cycles += 4;
}

fn void Cpu.rl_hl(&self, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char r = mmu.read(addr);

    bool msb = (r & 0b10000000) > 0;

    char result = r << 1;
    if (self.get_flag(Flag.C)) {
        result |= 1;
    }

    mmu.write(addr, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, msb);

    self.remaining_cycles += 12;
}

fn void Cpu.rr(&self, Register reg) {

    char r = self.get_register(reg);

    bool lsb = (r & 1) > 0;

    char result = r >> 1;
    if (self.get_flag(Flag.C)) {
        result |= 0x80;
    }

    self.set_register(reg, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, lsb);

    self.remaining_cycles += 4;
}

fn void Cpu.rr_hl(&self, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char r = mmu.read(addr);

    bool lsb = (r & 1) > 0;

    char result = r >> 1;
    if (self.get_flag(Flag.C)) {
        result |= 0x80;
    }

    mmu.write(addr, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, lsb);

    self.remaining_cycles += 12;
}

fn void Cpu.sla(&self, Register reg) {
    char r = self.get_register(reg);

    bool msb = (r & 0b10000000) > 0;

    char result = r << 1;

    self.set_register(reg, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, msb);

    self.remaining_cycles += 4;
}

fn void Cpu.sla_hl(&self, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char r = mmu.read(addr);

    bool msb = (r & 0b10000000) > 0;

    char result = r << 1;

    mmu.write(addr, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, msb);

    self.remaining_cycles += 12;
}

fn void Cpu.sra(&self, Register reg) {
    char r = self.get_register(reg);

    bool lsb = (r & 1) > 0;
    char msb = (r & 0b1000_0000);

    char result = (r >> 1) | msb;

    self.set_register(reg, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, lsb);

    self.remaining_cycles += 4;
}

fn void Cpu.sra_hl(&self, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char r = mmu.read(addr);

    bool lsb = (r & 1) > 0;
    char msb = (r & 0x80);

    char result = (r >> 1) | msb;

    mmu.write(addr, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, lsb);

    self.remaining_cycles += 12;
}

fn void Cpu.swap(&self, Register reg) {

    char r = self.get_register(reg);

    char hi = (r & 0xF0) >> 4;
    char lo = (r & 0x0F) << 4;

    char result = lo | hi;

    self.set_register(reg, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, false);

    self.remaining_cycles += 4;
}

fn void Cpu.swap_hl(&self, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char r = mmu.read(addr);

    char hi = (r & 0xF0) >> 4;
    char lo = (r & 0x0F) << 4;

    char result = lo | hi;

    mmu.write(addr, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, false);

    self.remaining_cycles += 12;
}

fn void Cpu.srl(&self, Register reg) {
    
    char r = self.get_register(reg);

    bool lsb = (r & 1) > 0;

    char result = r >> 1;

    self.set_register(reg, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, lsb);

    self.remaining_cycles += 4;
}

fn void Cpu.srl_hl(&self, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char r = mmu.read(addr);

    bool lsb = (r & 1) > 0;

    char result = r >> 1;

    mmu.write(addr, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, lsb);

    self.remaining_cycles += 12;
}

fn void Cpu.bit(&self, char bit, Register reg) {

    char r = self.get_register(reg);

    bool value = (r & (1 << bit)) > 0;

    self.set_flag(Flag.Z, !value);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, true);

    self.remaining_cycles += 4;
}

fn void Cpu.bit_hl(&self, char bit, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char r = mmu.read(addr);

    bool value = (r & (1 << bit)) > 0;

    self.set_flag(Flag.Z, !value);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, true);

    self.remaining_cycles += 8;
}

fn void Cpu.res(&self, char bit, Register reg) {

    char r = self.get_register(reg);

    char mask = ~(1 << bit);

    self.set_register(reg, r & mask);

    self.remaining_cycles += 4;
}

fn void Cpu.res_hl(&self, Mmu* mmu, char bit) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char value = mmu.read(addr);

    char mask = ~(1 << bit);

    mmu.write(addr, value & mask);

    self.remaining_cycles += 12;
}

fn void Cpu.set(&self, char bit, Register reg) {

    char r = self.get_register(reg);

    char mask = 1 << bit;

    self.set_register(reg, r | mask);
    
    self.remaining_cycles += 4;
}

fn void Cpu.set_hl(&self, Mmu* mmu, char bit) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char value = mmu.read(addr);

    char mask = 1 << bit;

    mmu.write(addr, value | mask);
    
    self.remaining_cycles += 12;
}

fn void Cpu.call(&self, Mmu* mmu) {

    ushort addr = self.fetch_word(mmu);

    ushort return_address = self.pc;
    
    self.sp -= 2;
    mmu.write(self.sp, (char) (return_address & 0x00FF));
    mmu.write(self.sp + 1, (char) ((return_address & 0xFF00) >> 8));

    self.pc = addr;
}

fn void Cpu.load_n16(&self, Mmu* mmu, WideRegister wide_register) {

    ushort value = self.fetch_word(mmu);

    self.set_wide_register(wide_register, value);
}

fn void Cpu.load_r16_a(&self, Mmu* mmu, WideRegister wide_register) {

    char value = self.get_register(Register.A);
    ushort addr = self.get_wide_register(wide_register);

    mmu.write(addr, value);
}

fn void Cpu.ldd_hl_a(&self, Mmu* mmu) {

    char value = self.get_register(Register.A);
    ushort addr = self.get_wide_register(WideRegister.HL);

    mmu.write(addr, value);
    self.set_wide_register(WideRegister.HL, addr - 1);
}

fn void Cpu.load_hl_n8(&self, Mmu* mmu) {

    char value = self.fetch_byte(mmu);

    ushort addr = self.get_wide_register(WideRegister.HL);

    mmu.write(addr, value);
}

fn void Cpu.ldi_hl_a(&self, Mmu* mmu) {

    char value = self.get_register(Register.A);
    ushort addr = self.get_wide_register(WideRegister.HL);

    mmu.write(addr, value);
    self.set_wide_register(WideRegister.HL, addr + 1);
}

fn void Cpu.ld_a_wide(&self, Mmu* mmu, WideRegister wide_register) {

    ushort addr = self.get_wide_register(wide_register);

    char value = mmu.read(addr);

    self.set_register(Register.A, value);
}

fn void Cpu.ldi_a_hl(&self, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char value = mmu.read(addr);

    self.set_register(Register.A, value);
    self.set_wide_register(WideRegister.HL, addr + 1);
}

fn void Cpu.ldd_a_hl(&self, Mmu* mmu) {

    ushort addr = self.get_wide_register(WideRegister.HL);
    char value = mmu.read(addr);

    self.set_register(Register.A, value);
    self.set_wide_register(WideRegister.HL, addr - 1);
}

fn void Cpu.daa(&self) {
    char a = self.get_register(Register.A);

    bool carry = false;
    if (!self.get_flag(Flag.N)) {
        if (self.get_flag(Flag.C) || a > 0x99) {
            a += 0x60;
            carry = true;
        }
        if (self.get_flag(Flag.H) || (a & 0x0F) > 0x09) {
            a += 0x06;
        }
    } else if (self.get_flag(Flag.C)) {
        carry = true;
        if (self.get_flag(Flag.H)) {
            a += 0x9A;
        } else {
            a += 0xA0;
        }
    } else if (self.get_flag(Flag.H)) {
        a += 0xFA;
    }

    self.set_register(Register.A, a);

    self.set_flag(Flag.Z, a == 0);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, carry);
}

fn void Cpu.scf(&self) {
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, true);
}

fn void Cpu.add_hl(&self, WideRegister reg) {

    ushort r = self.get_wide_register(reg);
    ushort hl = self.get_wide_register(WideRegister.HL);

    ushort result = r + hl;

    self.set_wide_register(WideRegister.HL, result);

    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, ((r & 0xfff) + (hl & 0xfff)) > 0xfff);
    self.set_flag(Flag.C, result < hl);
}

fn void Cpu.load_n8(&self, Mmu* mmu, Register register) {

    char value = self.fetch_byte(mmu);

    self.set_register(register, value);
}

fn void Cpu.ccf(&self) {

    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, !self.get_flag(Flag.C));
}

fn void Cpu.rlca(&self) {

    char a = self.get_register(Register.A);

    char msb = a & 0x80;

    self.set_flag(Flag.Z, false);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, msb > 0);

    a = a << 1;
    a |= (msb >> 7);

    self.set_register(Register.A, a);
}

fn void Cpu.rrca(&self) {

    char a = self.get_register(Register.A);

    char lsb = a & 1;

    self.set_flag(Flag.Z, false);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, lsb > 0);

    a = a >> 1;
    a |= (lsb << 7);

    self.set_register(Register.A, a);
}

fn void Cpu.rla(&self) {

    char a = self.get_register(Register.A);

    char msb = a & 0x80;

    a = a << 1;
    
    if (self.get_flag(Flag.C)) {
        a |= 1;
    }

    self.set_register(Register.A, a);

    self.set_flag(Flag.Z, false);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, msb > 0);
}

fn void Cpu.rra(&self) {

    char a = self.get_register(Register.A);

    char lsb = a & 1;

    a = a >> 1;
    
    if (self.get_flag(Flag.C)) {
        a |= 0x80;
    }

    self.set_register(Register.A, a);

    self.set_flag(Flag.Z, false);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, lsb > 0);
}

fn void Cpu.ld_a16_sp(&self, Mmu* mmu) {

    ushort addr = self.fetch_word(mmu);

    mmu.write(addr, (char) (self.sp & 0x00FF));
    mmu.write(addr + 1, (char) ((self.sp & 0xFF00) >> 8));
}

fn void Cpu.jr(&self, Mmu* mmu) {
    ichar relative_jump = (ichar) self.fetch_byte(mmu);

    self.pc += relative_jump;
}

fn void Cpu.jr_cc(&self, Mmu* mmu, Flag flag, bool jump_if_set) {

    ichar offset = (ichar) self.fetch_byte(mmu);

    bool should_jump = false;

    switch (flag) {
        case Z: should_jump = jump_if_set == self.get_flag(Flag.Z);
        case N: should_jump = jump_if_set == self.get_flag(Flag.N);
        case H: should_jump = jump_if_set == self.get_flag(Flag.H);
        case C: should_jump = jump_if_set == self.get_flag(Flag.C);
    }

    if (should_jump) {
        self.pc += offset;
        self.remaining_cycles += 4; //extra cycles for the jump
    }
}

fn void Cpu.jp_cc(&self, Mmu* mmu, Flag flag, bool jump_if_set) {

    ushort addr = self.fetch_word(mmu);

    bool should_jump = false;

    switch (flag) {
        case Z: should_jump = jump_if_set == self.get_flag(Flag.Z);
        case C: should_jump = jump_if_set == self.get_flag(Flag.C);
        default: return; //won't happen, only jp_cc on Z and C
    }

    if (should_jump) {
        self.pc = addr;
        self.remaining_cycles += 4; //extra cycles for the jump
    }
}

fn void Cpu.call_cc(&self, Mmu* mmu, Flag flag, bool call_if_set) {

    ushort addr = self.fetch_word(mmu);

    bool should_call = false;

    switch (flag) {
        case Z: should_call = call_if_set == self.get_flag(Flag.Z);
        case C: should_call = call_if_set == self.get_flag(Flag.C);
        default: return; //won't happen, only call_cc on Z and C
    }

    if (should_call) {

        ushort return_address = self.pc;
    
        self.sp -= 2;
        mmu.write(self.sp, (char) (return_address & 0x00FF));
        mmu.write(self.sp + 1, (char) ((return_address & 0xFF00) >> 8));

        self.pc = addr;
        self.remaining_cycles += 12; //extra cycles for the jump
    }
}

fn void Cpu.load_a8_a(&self, Mmu* mmu) {
    //Store the contents of register A in the internal RAM, port register, or mode register 
    //at the address in the range 0xFF00-0xFFFF specified by the 8-bit immediate operand a8.

    char value = self.get_register(Register.A);

    ushort addr = 0xFF00 + (ushort) self.fetch_byte(mmu);

    mmu.write(addr, value);
}

fn void Cpu.add_sp_s8(&self, Mmu* mmu) {
    //Add the contents of the 8-bit signed (2's complement) immediate operand s8 and the stack pointer SP and store the results in SP.

    ushort sp = self.get_wide_register(WideRegister.SP);
    ichar s = (ichar) self.fetch_byte(mmu);

    ushort result = sp + s;

    self.set_wide_register(WideRegister.SP, result);

    self.set_flag(Flag.Z, false);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, ((sp & 0xf) + (((ushort)s) & 0xf)) & 0x10 == 0x10);
    self.set_flag(Flag.C, result & 0xFF < sp & 0xFF);
}

fn void Cpu.ld_hl_sp_s8(&self, Mmu* mmu) {
    //Add the contents of the 8-bit signed (2's complement) immediate operand s8 and the stack pointer SP and store the results in SP.

    ushort sp = self.get_wide_register(WideRegister.SP);
    ichar s = (ichar) self.fetch_byte(mmu);

    ushort result = sp + s;

    self.set_wide_register(WideRegister.HL, result);

    self.set_flag(Flag.Z, false);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, ((sp & 0xf) + (((ushort)s) & 0xf)) & 0x10 == 0x10);
    self.set_flag(Flag.C, result & 0xFF < sp & 0xFF);
}

fn void Cpu.load_c_a(&self, Mmu* mmu) {
    //Store the contents of register A in the internal RAM, port register, or mode register 
    //at the address specified by the contents of register C.

    char value = self.get_register(Register.A);

    ushort addr = 0xFF00 + (ushort) self.get_register(Register.C);

    mmu.write(addr, value);
}

fn void Cpu.load_a_c(&self, Mmu* mmu) {
    //Load into register A the contents of the internal RAM, port register, or mode register 
    //at the address in the range 0xFF00-0xFFFF specified by register C.

    ushort addr = 0xFF00 + (ushort) self.get_register(Register.C);

    char value = mmu.read(addr);

    self.set_register(Register.A, value);
}

fn void Cpu.load_a16_a(&self, Mmu* mmu) {
    //Store the contents of register A in the internal RAM, port register, or mode register 
    //at the address specified by the 16-bit immediate operand a16.

    char value = self.get_register(Register.A);

    ushort addr = self.fetch_word(mmu);

    mmu.write(addr, value);
}

fn void Cpu.xor_a_n8(&self, Mmu* mmu) {

    char n = self.fetch_byte(mmu);
    char a = self.get_register(Register.A);

    char result = a ^ n;

    self.set_register(Register.A, result);

    self.set_flag(Flag.Z, result == 0);
    self.set_flag(Flag.N, false);
    self.set_flag(Flag.H, false);
    self.set_flag(Flag.C, false);
}

fn void Cpu.load_a_a16(&self, Mmu* mmu) {
    //Load into register A the contents of the internal RAM or register specified by the 16-bit immediate operand a16.

    ushort addr = self.fetch_word(mmu);

    char value = mmu.read(addr);

    self.set_register(Register.A, value);
}

fn void Cpu.load_a_a8(&self, Mmu* mmu) {
    //Load into register A the contents of the internal RAM, port register, or mode register 
    //at the address in the range 0xFF00-0xFFFF specified by the 8-bit immediate operand a8.

    ushort addr = 0xFF00 + (ushort) self.fetch_byte(mmu);

    char value = mmu.read(addr);
    self.set_register(Register.A, value);
}

fn void Cpu.reset(&self, Mmu* mmu, char vector) {

    ushort return_address = self.pc;
    
    self.sp -= 2;
    mmu.write(self.sp, (char) (return_address & 0x00FF));
    mmu.write(self.sp + 1, (char) ((return_address & 0xFF00) >> 8));

    self.pc = vector; //-1 to counteract the PC advancing
}

fn void Cpu.di(&self) {
    //Disable Interrupts by clearing the IME flag.
    self.ime = false;
}

fn void Cpu.ei(&self) {
    //Enable Interrupts by setting the IME flag. The flag is only set after the instruction following EI.
    self.ime_ready = true;
}
