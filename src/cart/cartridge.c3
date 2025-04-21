module cartridge;

import mbc1;

import std::io;
import std::core::mem;

interface Cartridge {
    fn String title();
    fn char read(ushort address);
    fn void write(ushort address, char value);
}

struct RomOnlyCartridge (Cartridge) {
    char[] rom;
}

fn String RomOnlyCartridge.title(&self) @dynamic {
    return (String) self.rom[0x0134..0x0143];
}

fn char RomOnlyCartridge.read(RomOnlyCartridge* self, ushort address) @dynamic {
    return self.rom[address];
}

fn void RomOnlyCartridge.write(RomOnlyCartridge* self, ushort address, char value) @dynamic {
    return; //Cannot write to a rom only cart
}

enum CartridgeType: char (char code) {
    ROM_ONLY = 0x0,
    MBC1 = 0x01,
    MBC1_RAM = 0x02,
    MBC1_RAM_BATTERY = 0x03,
    MBC2 = 0x05,
    MBC2_BATTERY = 0x06,
    ROM_RAM = 0x08,
    ROM_RAM_BATTERY = 0x09,
    MMM01 = 0x0B,
    MMM01_RAM = 0x0C,
    MMM01_RAM_BATTERY = 0x0D,
    MBC3_TIMER_BATTERY = 0x0F,
    MBC3_TIMER_RAM_BATTERY = 0x10,
    MBC3 = 0x11,
    MBC3_RAM = 0x12,
    MBC3_RAM_BATTERY = 0x13,
    MBC5 = 0x19,
    MBC5_RAM = 0x1A,
    MBC5_RAM_BATTERY = 0x1B,
    MBC5_RUMBLE = 0x1C,
    MBC5_RUMBLE_RAM = 0x1D,	
    MBC5_RUMBLE_RAM_BATTERY = 0x1E,
    MBC6 = 0x20,
    MBC7_SENSOR_RUMBLE_RAM_BATTERY = 0x22,
    POCKET_CAMERA = 0xFC,
    BANDAI_TAMA5 = 0xFD,
    HUC3 = 0xFE,
    HUC1_RAM_BATTERY = 0xFF,
}

faultdef UNSUPPORTED_CART_TYPE, BAD_CART_TYPE;

fn Cartridge? parse(File* file) {

    char[0x14F] header = {};
    file.read(&header)!!;
    
    CartridgeType type = @enum_from_value(CartridgeType, code, header[0x147])!!;


    uint rom_size = 0x8000 * (1 << header[0x148]);
    uint ram_size = parse_ram_size(header[0x149])!!;

    char[] rom = mem::new_array(char, rom_size);

    io::printfn("type: %s, rom: %db, ram: %db", type, rom_size, ram_size);

    file.seek(0)!!; //reset to read the header again
    file.read(rom)!!;

    switch (type) {
        case ROM_ONLY: return (Cartridge) mem::new(RomOnlyCartridge, { .rom = rom });
        case MBC1: return (Cartridge) mbc1::init(rom, 0);
        case MBC1_RAM: {
            return (Cartridge) mbc1::init(rom, ram_size);
        }
        case MBC1_RAM_BATTERY: {
            //TODO: init MBC1 with a save path
            return (Cartridge) mbc1::init(rom, ram_size);
        }
        default: {
            io::printfn("Unsupported cartridge type: %s", type);
            return UNSUPPORTED_CART_TYPE?;
        }
    }
}

fn uint? parse_ram_size(char code) {
    switch (code) {
        case 0x00: return 0x0000;
        case 0x02: return 0x2000;
        case 0x03: return 0x8000;
        case 0x04: return 0x20000;
        case 0x05: return 0x10000;
        default: 
            io::printfn("bad ram size code: 0x%02x", code);
            return BAD_CART_TYPE?;
    }
}

