module ppu;

import mmu;
import util;

import std::io;
// import raylib5::rl; //I wish the ppu were rendering agnostic but raylib does some wonky stuff with the image data

struct Ppu {
    uint[256 * 256] pixels;
    ushort[10] object_buffer;
    PpuMode mode;
    //Throw some state here, figure out a better setup later
    uint remaining_dots;
    char current_x;
}

fn Ppu init() {
    return Ppu {
        .pixels = {},
        .object_buffer = {},
        .mode = PpuMode.OAM_SCAN,
        .remaining_dots = 80,
        .current_x = 0,
    };
}

struct Palette {
    uint black;
    uint dark;
    uint light;
    uint white;
}

//TODO: allow custom palettes from the user
const Palette DEFAULT_GB_PALETTE = Palette {
    .white  = 0xFFD0F8E0,
    .light  = 0xFF90D4AC,
    .dark   = 0xFF566834,
    .black  = 0xFF201808,
};

enum PpuMode: char (ushort dots_per_mode) {
    H_BLANK = 204,
    V_BLANK = 4560,
    OAM_SCAN = 80,
    DRAWING = 172,
}

enum AddressingMode: char {
    MODE_8000,
    MODE_8800,
}

fn void Ppu.dot(&self, Mmu* mmu) {
    //https://hacktix.github.io/GBEDG/ppu/#v-blank-mode-1
    
    char ly = mmu.read_unchecked(mmu::LY_REGISTER);

    // io::printfn("scanline: %d", ly);

    switch (self.mode) {
        case OAM_SCAN: {
            //Probably not the smartest way but once we've had 80 dots just do the whole scan in one
            // this might cause timing issues with the cpu though...
            // need a "futures" library
            if (self.remaining_dots == 0) {
                self.oam_scan(mmu, ly);
                self.set_mode(mmu, DRAWING);
                self.current_x = 0;
            }
        }
        case DRAWING: {        

            self.draw(mmu, ly);
            self.current_x++;

            if (self.remaining_dots == 0) {
                self.draw_objects(mmu, ly);
                self.set_mode(mmu, H_BLANK);
            }
        }
        case H_BLANK: {

            self.current_x++;
            if (self.remaining_dots == 0) {

                self.current_x = 0;

                char lyc = mmu.read_unchecked(mmu::LYC_REGISTER);

                //LYC == LY (Read-only): Set when LY contains the same value as LYC; it is constantly updated.
                if (lyc == ly) {
                    mmu.write_bit(mmu::LCD_STAT_REGISTER, 2, true);

                    //LYC int select (Read/Write): If set, selects the LYC == LY condition for the STAT interrupt.
                    if (util::is_bit_set(mmu.read(mmu::LCD_STAT_REGISTER), 6)) {
                        mmu.set_interrupt_flag(mmu::Interrupt.STAT);
                    }
                } else {
                    mmu.write_bit(mmu::LCD_STAT_REGISTER, 2, false);
                }

                char scanline = (ly + 1) % 154;
                mmu.write(mmu::LY_REGISTER, scanline);

                if (scanline == 144) {
                    mmu.set_interrupt_flag(mmu::Interrupt.V_BLANK);

                    self.set_mode(mmu, V_BLANK);
                    self.current_x = 0;
                } else {
                    self.set_mode(mmu, OAM_SCAN);
                }
            }
        }
        case V_BLANK: {
            
            self.current_x++;
            
            if (self.remaining_dots % 456 == 0) {
                char scanline = (ly + 1) % 154;
                mmu.write(mmu::LY_REGISTER, scanline);
            }

            if (self.remaining_dots == 0) {
                char scanline = (ly + 1) % 154;
                mmu.write(mmu::LY_REGISTER, scanline);
                self.current_x = 0;

                if (scanline == 0) {
                    self.set_mode(mmu, OAM_SCAN);
                }
            }
        }
    }
    self.remaining_dots -= 1;
}

fn void Ppu.set_mode(&self, Mmu* mmu, PpuMode mode) {

    self.mode = mode;
    self.remaining_dots = mode.dots_per_mode;

    switch (mode) {
        case H_BLANK: {
            //Set LCD STAT to mode 0
            mmu.write_bit(mmu::LCD_STAT_REGISTER, 0, false);
            mmu.write_bit(mmu::LCD_STAT_REGISTER, 1, false);

            if (util::is_bit_set(mmu.read(mmu::LCD_STAT_REGISTER), 3)) {
                mmu.set_interrupt_flag(mmu::Interrupt.STAT);
            }

            mmu.video_access = mmu::VideoAccess.EVERYTHING;
        }
        case V_BLANK: {
            //Set LCD STAT to mode 1
            mmu.write_bit(mmu::LCD_STAT_REGISTER, 0, true);
            mmu.write_bit(mmu::LCD_STAT_REGISTER, 1, false);

            if (util::is_bit_set(mmu.read(mmu::LCD_STAT_REGISTER), 4)) {
                mmu.set_interrupt_flag(mmu::Interrupt.STAT);
            }

            mmu.video_access = mmu::VideoAccess.EVERYTHING;
        }
        case OAM_SCAN: {
            //Set LCD STAT to mode 2
            mmu.write_bit(mmu::LCD_STAT_REGISTER, 0, false);
            mmu.write_bit(mmu::LCD_STAT_REGISTER, 1, true);

            if (util::is_bit_set(mmu.read(mmu::LCD_STAT_REGISTER), 5)) {
                mmu.set_interrupt_flag(mmu::Interrupt.STAT);
            }
            //Make OAM inaccessible
            mmu.video_access = mmu::VideoAccess.OAM_INACCESSIBLE;
        }
        case DRAWING: {
            //Set LCD STAT to mode 3
            mmu.write_bit(mmu::LCD_STAT_REGISTER, 0, true);
            mmu.write_bit(mmu::LCD_STAT_REGISTER, 1, true);
            mmu.video_access = mmu::VideoAccess.VRAM_INACCESSIBLE;
        }
    }
}

fn void Ppu.oam_scan(&self, Mmu* mmu, char scanline) {

    self.object_buffer = {};
    char buffer_object_count = 0;

    for (ushort addr = 0xFE00; addr <= 0xFE9F; addr += 4) {

        char y_pos = mmu.read_unchecked(addr + 0);
        char x_pos = mmu.read_unchecked(addr + 1);

        //An object is only added to the buffer if all of the following conditions apply:

        // Sprite X-Position must be greater than 0
        if (x_pos <= 8) {
            continue;
        }
        // LY + 16 must be greater than or equal to Sprite Y-Position
        if (scanline + 16 < y_pos) {
            continue;
        }

        // LY + 16 must be less than Sprite Y-Position + Sprite Height (8 in Normal Mode, 16 in Tall-Sprite-Mode)
        if (scanline + 16 >= y_pos + 8) { //TODO: 16 tall-sprite-mode
            continue;
        }
        // The amount of sprites already stored in the OAM Buffer must be less than 10
        if (buffer_object_count >= self.object_buffer.len) {
            return;
        }

        self.object_buffer[buffer_object_count] = addr;
        buffer_object_count++;
    }
}

fn void Ppu.draw(&self, Mmu* mmu, char scanline) {
    
    char lcdc = mmu.read(mmu::LCDC_REGISTER);

    //eventually use the pixel fetcher/mixer and buffers but for now do it slowly pixel by pixel inefficiently

    AddressingMode addressing_mode = util::is_bit_set(lcdc, 4)
        ? MODE_8000 
        : MODE_8800;
    
    //Background
    {
        char scroll_y = mmu.read(mmu::SCY_REGISTER);
        char scroll_x = mmu.read(mmu::SCX_REGISTER);

        uint bg_pixel = self.get_bg_pixel(mmu, addressing_mode, scanline + scroll_y, self.current_x + scroll_x);
        
        char y = scanline;
        char x = self.current_x;
        ushort offset = (((ushort)y ) * 256u16) + x;

        self.pixels[offset] = bg_pixel;
    }

    //Window
    {
        //TODO
    }
}

fn uint Ppu.get_bg_pixel(&self, Mmu* mmu, AddressingMode addressing_mode, char y, char x) {
    char row = y / 0x08;
    char tile_y = y % 0x08;
    ushort address_offset = ((ushort)row) * 0x20;

    ushort bg_tile_data_area_start = util::is_bit_set(mmu.read_unchecked(mmu::LCDC_REGISTER), 3)
        ? 0x9C00 + address_offset
        : 0x9800 + address_offset;

    char tile_x = x % 8;
    ushort address = bg_tile_data_area_start + (x / 8);

    char tile_idx = mmu.read_unchecked(address);
    char pixel = get_tile_pixel(mmu, addressing_mode, tile_idx, tile_y, tile_x);

    char palette_data = mmu.read_unchecked(mmu::BGP_REGISTER);

    char value = (palette_data & (0b11 << (2 * pixel))) >> (2 * pixel);
    switch (value) {
        case 0: return DEFAULT_GB_PALETTE.white;
        case 1: return DEFAULT_GB_PALETTE.light;
        case 2: return DEFAULT_GB_PALETTE.dark;
        case 3: return DEFAULT_GB_PALETTE.black;
        default: return 0xFFFF00FF;
    }
}

fn void Ppu.draw_objects(&self, Mmu* mmu, char scanline) {

    //search the object buffer for any suitable objs
    foreach (address: self.object_buffer) {

        if (address == 0) break; //reached the end of the buffer, no more objects to render

        char y_pos      = mmu.read_unchecked(address + 0);
        char x_pos      = mmu.read_unchecked(address + 1);
        char tile_index = mmu.read_unchecked(address + 2);
        char attributes = mmu.read_unchecked(address + 3);

        //Get palette info
        ushort palette_register = util::is_bit_set(attributes, 4)
            ? mmu::OBP1_REGISTER
            : mmu::OBP0_REGISTER;

        char palette_data = mmu.read_unchecked(palette_register);
        uint[4] palette = {};
        for (int id = 1; id < 4; id++) { //ignore 2 lower bits as colour index 0 is transparency for objects
            char value = (palette_data & (0b11 << (2 * id))) >> (2 * id);
            switch (value) {
                case 0: palette[id] = DEFAULT_GB_PALETTE.white;
                case 1: palette[id] = DEFAULT_GB_PALETTE.light;
                case 2: palette[id] = DEFAULT_GB_PALETTE.dark;
                case 3: palette[id] = DEFAULT_GB_PALETTE.black;
            }
        }

        //TODO: Get correct VRAM bank from attribute bit 3
        bool y_flip = util::is_bit_set(attributes, 6);
        bool x_flip = util::is_bit_set(attributes, 5);
        
        // char priority = util::get_bit(attributes, 7);
        // if (priority == 1) {
        //     //BG and Window colors 1–3 are drawn over this OBJ
        //     return 0;
        // }
        
        char y = scanline - (y_pos - 16);
        char row = y_flip ? 7 - y : y;

        char[8] tile_row = get_tile_row(mmu, AddressingMode.MODE_8000, tile_index, row);

        for (char x = 0; x < 8; x ++) {

            char col = x_flip ? 7 - x : x;
            
            uint pixel = palette[tile_row[col]];
            if (pixel != 0) {
                self.pixels[(y_pos - 16 + y) * 256u16 + (x_pos - 8) + x] = pixel;
            }
        }
    }
}

fn void Ppu.draw_obj_pixel(&self, Mmu* mmu, char scanline) {

    //search the object buffer for any suitable objs
    foreach (address: self.object_buffer) {
        if (address == 0) break; //reached the end of the buffer, no more objects to render

        char y_pos      = mmu.read_unchecked(address + 0);
        char x_pos      = mmu.read_unchecked(address + 1);
        char tile_index = mmu.read_unchecked(address + 2);
        char attributes = mmu.read_unchecked(address + 3);

        //is the obj captured in the current x pixel? y is true since oam scan returned it
        if (x_pos < self.current_x || x_pos >= self.current_x + 8) continue;

        //TODO: Get correct VRAM bank from attribute bit 3
        bool y_flip = util::is_bit_set(attributes, 6);
        bool x_flip = util::is_bit_set(attributes, 5);
        
        // char priority = util::get_bit(attributes, 7);
        // if (priority == 1) {
        //     //BG and Window colors 1–3 are drawn over this OBJ
        //     return 0;
        // }
        
        char y = scanline - (y_pos - 16);
        char row = y_flip ? 7 - y : y;

        char[8] tile_row = get_tile_row(mmu, AddressingMode.MODE_8000, tile_index, row);

        char x = 7 - (x_pos - self.current_x);

        char col = x_flip ? 7 - x : x;

        ushort palette_register = util::is_bit_set(attributes, 4)
            ? mmu::OBP1_REGISTER
            : mmu::OBP0_REGISTER;

        char palette_data = mmu.read_unchecked(palette_register);
        uint[4] palette = {};
        for (int id = 1; id < 4; id++) { //ignore 2 lower bits as colour index 0 is transparency for objects
            char value = (palette_data & (0b11 << (2 * id))) >> (2 * id);
            switch (value) {
                case 0: palette[id] = DEFAULT_GB_PALETTE.white;
                case 1: palette[id] = DEFAULT_GB_PALETTE.light;
                case 2: palette[id] = DEFAULT_GB_PALETTE.dark;
                case 3: palette[id] = DEFAULT_GB_PALETTE.black;
            }
        }
        
        uint pixel = palette[tile_row[col]];
        if (pixel != 0) {
            self.pixels[(y_pos - 16 + y) * 256u16 + (x_pos - 8) + x] = pixel;
        }
    }
}

fn char get_tile_pixel(Mmu* mmu, AddressingMode addressing_mode, char tile_idx, char row_idx, char x) {
    ushort root_address;
    switch (addressing_mode) {
        //The “$8000 method” uses $8000 as its base pointer and uses an unsigned addressing, 
        //meaning that tiles 0-127 are in block 0, and tiles 128-255 are in block 1.
        case MODE_8000: root_address = 0x8000 + (tile_idx) * 0x10;
        //The “$8800 method” uses $9000 as its base pointer and uses a signed addressing, 
        //meaning that tiles 0-127 are in block 2, and tiles -128 to -1 are in block 1; 
        //or, to put it differently, “$8800 addressing” takes tiles 0-127 from block 2 and tiles 128-255 from block 1.
        case MODE_8800: root_address = 0x9000 + ((ichar)tile_idx) * 0x10;
    }

    ushort byte = ((ushort)row_idx) * 2;
    char lo = mmu.read_unchecked(root_address + byte);
    char hi = mmu.read_unchecked(root_address + byte + 1);

    return (util::get_bit(hi, 7 - x) << 1) | util::get_bit(lo, 7 - x);
}

fn char[8] get_tile_row(Mmu* mmu, AddressingMode addressing_mode, char tile_idx, char row_idx) {

    ushort root_address;
    switch (addressing_mode) {
        //The “$8000 method” uses $8000 as its base pointer and uses an unsigned addressing, 
        //meaning that tiles 0-127 are in block 0, and tiles 128-255 are in block 1.
        case MODE_8000: root_address = 0x8000 + (tile_idx) * 0x10;
        //The “$8800 method” uses $9000 as its base pointer and uses a signed addressing, 
        //meaning that tiles 0-127 are in block 2, and tiles -128 to -1 are in block 1; 
        //or, to put it differently, “$8800 addressing” takes tiles 0-127 from block 2 and tiles 128-255 from block 1.
        case MODE_8800: root_address = 0x9000 + ((ichar)tile_idx) * 0x10;
    }

    char[8] tile_row = {};

    ushort byte = ((ushort)row_idx) * 2;
    char lo = mmu.read_unchecked(root_address + byte);
    char hi = mmu.read_unchecked(root_address + byte + 1);

    for (ichar bit = 7; bit >= 0; bit--) {
        char pixel = (util::get_bit(hi, (char)bit) << 1) | util::get_bit(lo, (char)bit);
        tile_row[7 - bit] = pixel;
    }

    return tile_row;
}