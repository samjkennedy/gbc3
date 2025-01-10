module mbc1;

import cartridge;

import std::io;
import std::core::mem;

struct MBC1Cartridge (Cartridge) {
    char[] rom;
    //This 5-bit register (range $01-$1F) selects the ROM bank number for the 4000-7FFF region.
    char rom_bank; 
    //Enables the reading and writing of external RAM.
    bool ram_enable; 
    char[] ram;
    //This second 2-bit register can be used to select a RAM Bank in range from $00-$03 
    //(32 KiB ram carts only), or to specify the upper two bits (bits 5-6) of the ROM 
    //Bank number (1 MiB ROM or larger carts only).
    char ram_bank;
    //This 1-bit register selects between the two MBC1 banking modes, 
    //controlling the behaviour of the secondary 2-bit banking register (above).
    bool banking_mode;
}

fn String MBC1Cartridge.title(&self) @dynamic {
    return (String) self.rom[0x0134..0x0143];
}

fn MBC1Cartridge* init(char[] rom, uint ram_size) {
    return mem::new(MBC1Cartridge, {
        .rom = rom,
        .ram = mem::new_array(char, ram_size),
        .rom_bank = 1,
    });
}

fn char MBC1Cartridge.read(MBC1Cartridge* self, ushort address) @dynamic {

    switch (address) {
        //0000-3FFF - ROM Bank X0 (Read Only)
        case 0x0000..0x3FFF: return self.rom[address];
        //4000-7FFF - ROM Bank 01-7F (Read Only)
        case 0x4000..0x7FFF: {
            ushort offset = 0x4000 * self.rom_bank;
            // io::printfn("address: 0x%04X, offset: 0x%04X, index: 0x%04X", address, offset, offset + (address - 0x4000));
            return self.rom[offset + (address - 0x4000)];
        }
        //A000-BFFF - RAM Bank 00-03, if any (Read/Write)
        case 0xA000..0xBFFF: {
            if (self.ram_enable) {
                ushort offset = 0x2000 * self.ram_bank;
                return self.ram[offset + (address - 0xA000)];
            } else {
                return 0;
            }
        }
        default: return 0;
    }
}

fn void MBC1Cartridge.write(MBC1Cartridge* self, ushort address, char value) @dynamic {
    
    switch (address) {
        //Registers.
        //Any value with 0xa in the lower 4 bits enables ram.
        case 0x0000..0x1FFF: self.ram_enable = (value & 0x0F == 0x0A);
        //ROM bank number (write only) - lower 5 bits.
        case 0x2000..0x3FFF: {
            //If this register is set to $00, it behaves as if it is set to $01.
            if (value == 0) {
                value = 1;
            }
            self.rom_bank = (self.rom_bank & 0b0110_0000) | (value & 0b0001_1111);
        }
        //RAM Bank Number - or - Upper Bits of ROM Bank Number (Write Only)
        case 0x4000..0x5FFF: {
            if (self.banking_mode) {
                self.ram_bank = value & 0b11;
            } else {
                self.rom_bank = (self.rom_bank & 0b0001_1111) | ((value & 3) << 5);
            }
        }
        //Banking Mode Select (Write Only)
        case 0x6000..0x7FFF: self.banking_mode = value == 1;
    }
}
