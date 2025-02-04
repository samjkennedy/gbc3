module mmu;

import cartridge;
import joypad;
import util;

import std::io;

struct Mmu {
    Cartridge cartridge;
    char[0x8000] ram;
    //state
    VideoAccess video_access;

    Joypad* joypad; //TODO: I don't like this here, maybe have a BUS or something everything can route through?
}

enum VideoAccess {
    EVERYTHING,
    VRAM_INACCESSIBLE,
    OAM_INACCESSIBLE,
}

fn Mmu init(Cartridge cartridge, Joypad* joypad) {
    Mmu mmu = {};

    mmu.cartridge = cartridge;
    mmu.ram = {};
    mmu.ram[0xFF40 - RAM_START] = 0x91; //LCDC
    mmu.ram[0xFF41 - RAM_START] = 0x85; //LCD STAT
    mmu.ram[0xFFFF - RAM_START] = 1; //interrupt enable

    mmu.joypad = joypad;
    mmu.video_access = EVERYTHING;

    return mmu;
}

const ushort RAM_START = 0x8000;
const ushort VRAM_START = 0x8000;
const ushort VRAM_END = 0x9FFF;
const ushort OAM_START = 0xFE00;

const ushort JOYPAD_REGISTER = 0xFF00;

const ushort DIV_REGISTER = 0xFF04; //Divider register
const ushort TIMA_REGISTER = 0xFF05; //Timer counter
const ushort TMA_REGISTER = 0xFF06; //Timer modulo
const ushort TAC_REGISTER = 0xFF07; //Timer control
const ushort IF_REGISTER = 0xFF0F;
const ushort IE_REGISTER = 0xFFFF;

//ppu specific registers, maybe move these consts there?
const ushort LCDC_REGISTER = 0xFF40;
const ushort LCD_STAT_REGISTER = 0xFF41;
const ushort SCY_REGISTER = 0xFF42;
const ushort SCX_REGISTER = 0xFF43;
const ushort LY_REGISTER = 0xFF44;
const ushort LYC_REGISTER = 0xFF45;
const ushort OAM_DMA_REGISTER = 0xFF46;
const ushort BGP_REGISTER = 0xFF47;
const ushort OBP0_REGISTER = 0xFF48;
const ushort OBP1_REGISTER = 0xFF49;
const ushort WY_REGISTER = 0xFF4A;
const ushort WX_REGISTER = 0xFF4B;


enum Interrupt: char (char bit, ushort vector) {
    V_BLANK = {0, 0x0040},
    STAT = {1, 0x0048},
    TIMER = {2, 0x0050},
    SERIAL = {3, 0x0058},
    JOYPAD = {4, 0x0060},
}

//This function is used to write to the memory without any restrictions the GB would apply, e.g. not writing to specific addresses during drawing
fn void Mmu.write_unchecked(&self, ushort address, char value) {
    if (address < RAM_START) {
        return;
    } else {
        if (address == LY_REGISTER) {

            self.ram[address - RAM_START] = value;

            char lyc = self.read_unchecked(LYC_REGISTER);
            char ly = self.read_unchecked(LY_REGISTER);
            self.lyc_ly_interrupt(lyc, ly);
            return;
        }

        self.ram[address - RAM_START] = value;
    }
}

fn char Mmu.read_unchecked(&self, ushort address) {
    if (address < RAM_START) {
        return self.cartridge.read(address);
    } else {
        return self.ram[address - RAM_START];
    }
}

fn char Mmu.read(&self, ushort address) {

    if (address < RAM_START) {
        return self.cartridge.read(address);
    }

    // if (self.dma_transfer_cycles_remaining > 0 && address >= RAM_START) {
    //     if (address < 0xFF80 || address > 0xFFFE) {
    //         return 0x00;
    //     }
    // }

    if (self.video_access == VRAM_INACCESSIBLE && ((address >= 0x8000 && address <= 0x9FFF) || (address >= 0xFE00 && address <= 0xFE9F))) {
        return 0xFF;
    }
    if (self.video_access == OAM_INACCESSIBLE && address >= 0xFE00 && address <= 0xFE9F) {
        return 0xFF;
    }

    if (address == JOYPAD_REGISTER) {
        char select = self.ram[JOYPAD_REGISTER - RAM_START];

        if (util::get_bit(select, 4) == 0) {
            return self.joypad.read(ButtonMode.D_PAD);
        } 
        if (util::get_bit(select, 5) == 0) {
            return self.joypad.read(ButtonMode.BUTTONS);
        } 
        return 0x0F;
    }

    return self.ram[address - RAM_START];
}

fn void Mmu.write(&self, ushort address, char value) {

    if (address < RAM_START) {
        self.cartridge.write(address, value);
        return;
    }
    if (address == IF_REGISTER) {
        return;
    }

    // if (self.dma_transfer_cycles_remaining > 0) {
    //     if (address < 0xFF80 || address > 0xFFFE) {
    //         return;
    //     }
    // }

    // if (self.video_access == VRAM_INACCESSIBLE && ((address >= 0x8000 && address <= 0x9FFF) || (address >= 0xFE00 && address <= 0xFE9F))) {
    //     return;
    // }
    if (self.video_access == OAM_INACCESSIBLE && address >= 0xFE00 && address <= 0xFE9F) {
        return;
    }

    if (address == JOYPAD_REGISTER) {
        //only write to high nibble
        self.ram[JOYPAD_REGISTER - RAM_START] = ((value & 0xF0) | (self.ram[JOYPAD_REGISTER - RAM_START] & 0x0F));
        return;
    }

    if (address == LCD_STAT_REGISTER) {
        //only write top 5 bits
        self.ram[LCD_STAT_REGISTER - RAM_START] = ((value & 0b11111000) | (self.ram[LCD_STAT_REGISTER - RAM_START] & 0b00000111));
        return;
    }

    if (address == LYC_REGISTER || address == LY_REGISTER) {

        self.ram[address - RAM_START] = value;

        char lyc = self.read_unchecked(LYC_REGISTER);
        char ly = self.read_unchecked(LY_REGISTER);
        self.lyc_ly_interrupt(lyc, ly);
        return;
    }

    if (address == OAM_DMA_REGISTER) {
        self.ram[address - RAM_START] = value;
        self.oam_dma_transfer();
        return;
    }

    //TODO: check destination is a legal write address / trigger interrupts

    self.ram[address - RAM_START] = value;

    // io::printfn("wrote 0x%02X to 0x%04X", value, address);
}

fn void Mmu.lyc_ly_interrupt(&self, char lyc, char ly) {
    if (lyc == ly) {
        self.write_bit(mmu::LCD_STAT_REGISTER, 2, true);

        //LYC int select (Read/Write): If set, selects the LYC == LY condition for the STAT interrupt.
        if (util::is_bit_set(self.read(mmu::LCD_STAT_REGISTER), 6)) {
            self.set_interrupt_flag(mmu::Interrupt.STAT);
        }
    } else {
        self.write_bit(mmu::LCD_STAT_REGISTER, 2, false);
    }
}

fn void Mmu.write_bit(&self, ushort address, char bit, bool value) {
    if (address < RAM_START) {
        return;
    }
    if (address == IF_REGISTER) {
        return;
    }
    if (value) {
        self.ram[address - RAM_START] |= (1 << bit);
    } else {
        self.ram[address - RAM_START] &= (char)~(1 << bit);
    }
}

//TODO: This should take 640 cycles
fn void Mmu.oam_dma_transfer(&self) {

    ushort start = ((ushort)self.read_unchecked(OAM_DMA_REGISTER)) << 8;

    for (char offset = 0x00; offset < 0x9F; offset++) {
        self.write_unchecked(0xFE00 + offset, self.read_unchecked(start + offset));
    }    
}

fn void Mmu.set_interrupt_flag(&self, Interrupt interrupt) {

    char mask = 1 << interrupt.bit;

    char interrupt_flag = self.read(IF_REGISTER);

    interrupt_flag |= mask;

    self.write_unchecked(IF_REGISTER, interrupt_flag);
}

fn bool Mmu.get_interrupt_flag(&self, Interrupt interrupt) {

    //Check master interrupt enable
    char ie = self.read(0xFFFF);
    char ie_mask = 1 << interrupt.bit;
    bool interrupt_enabled = (ie & ie_mask) > 0;

    //Check flag
    char mask = 1 << interrupt.bit;
    char interrupt_flag = self.read(IF_REGISTER);
    bool interrupt_flag_set = (interrupt_flag & mask) > 0;

    return interrupt_enabled && interrupt_flag_set;
}

fn void Mmu.clear_interrupt_flag(&self, Interrupt interrupt) {

    char mask = 1 << interrupt.bit;

    char interrupt_flag = self.read(IF_REGISTER);

    interrupt_flag &= ~mask;

    self.write_unchecked(IF_REGISTER, interrupt_flag);
}