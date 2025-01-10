module mmu;

import cartridge;
import joypad;
import util;

import std::io;

struct Mmu {
    Cartridge cartridge;
    char[0x8000] ram;
    Joypad* joypad; //TODO: I don't like this here, maybe have a BUS or something everything can route through?
    //state
    VideoAccess video_access;
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

//This function is used to write to the memory without any restrictions the GB would apply, e.g. not writing to specific addresses
fn void Mmu.write_unchecked(&self, ushort address, char value) {
    if (address < RAM_START) {
        return;
    } else {
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
    // if (self.video_access == VRAM_INACCESSIBLE && ((address >= 0x8000 && address <= 0x9FFF) || (address >= 0xFE00 && address <= 0xFE9F))) {
    //     return;
    // }
    // if (self.video_access == OAM_INACCESSIBLE && address >= 0xFE00 && address <= 0xFE9F) {
    //     return;
    // }

    if (address == JOYPAD_REGISTER) {
        //only write to high nibble
        self.ram[JOYPAD_REGISTER - RAM_START] = ((value & 0xF0) | (self.ram[JOYPAD_REGISTER - RAM_START] & 0x0F));
        return;
    }

    if (address == OAM_DMA_REGISTER) {
        self.oam_dma_transfer(value);
        return;
    }

    //TODO: check destination is a legal write address / trigger interrupts

    self.ram[address - RAM_START] = value;

    // io::printfn("wrote 0x%02X to 0x%04X", value, address);
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

//Big TODO: The MMU should be subject to TCycles as well, and also have a concept of a state
fn void Mmu.oam_dma_transfer(&self, char src_addr) {
    //this should take 160 MCycles...
    //and also block all reads/writes outside of HRAM 0xFF80-0xFFFE

    ushort start = src_addr << 8;
    for (ushort offset = 0; offset <= 0x9F; offset++) {
        //each one of these should take 4 t_cycles...
        if (start + offset < RAM_START) {
            self.ram[0xFE00 + offset - RAM_START] = self.cartridge.read(start + offset);
        } else {
            self.ram[0xFE00 + offset - RAM_START] = self.ram[start + offset - RAM_START];
        }
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