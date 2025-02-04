module ppu;

import mmu;
import util;

import std::io;

struct Ppu {
    uint[256 * 256] pixels;
    ushort[10] object_buffer;
    char[8] bg_tile;
    char scroll_x;
    char scroll_y;
    //Throw some state here, figure out a better setup later
    PpuMode mode;
    uint remaining_dots;
    char current_x;
}

fn Ppu init() {
    return Ppu {
        .pixels = {},
        .object_buffer = {},
        .bg_tile = {},
        .scroll_x = 0,
        .scroll_y = 0,
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
    char lcdc = mmu.read(mmu::LCDC_REGISTER);

    switch (self.mode) {
        case OAM_SCAN: {
            //Probably not the smartest way but once we've had 80 dots just do the whole scan in one
            // this might cause timing issues with the cpu though...
            if (self.remaining_dots == 0) {
                self.oam_scan(mmu, ly);
                self.set_mode(mmu, DRAWING);
                self.current_x = 0;
            }
        }
        case DRAWING: {

            //TODO: Have a char[8] tile buffer updated on each fetch?

            //The scroll registers are re-read on each tile fetch, 
            if (self.current_x % 8 == 0) { //crude approximation of tile fetching, in future fetch for self.bg_tile
                self.scroll_y = mmu.read_unchecked(mmu::SCY_REGISTER);
                self.scroll_x = mmu.read_unchecked(mmu::SCX_REGISTER);
            }

            if (!util::is_bit_set(lcdc, 7)) {
                
                ushort offset = (((ushort)ly ) * 256u16) + self.current_x;
                self.pixels[offset] = DEFAULT_GB_PALETTE.white;

            } else if (self.current_x == 160) {

                self.draw_scanline(mmu, ly);
                self.set_mode(mmu, H_BLANK);
            }
            self.current_x++;
        }
        case H_BLANK: {

            self.current_x++;
            if (self.remaining_dots == 0) {

                self.current_x = 0;

                char scanline = (ly + 1) % 154;
                mmu.write_unchecked(mmu::LY_REGISTER, scanline);

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
            
            if (self.remaining_dots % 456 == 0 || self.remaining_dots == 0) {

                char scanline = (ly + 1) % 154;
                mmu.write_unchecked(mmu::LY_REGISTER, scanline);
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

            if (util::is_bit_set(mmu.read_unchecked(mmu::LCD_STAT_REGISTER), 3)) {
                mmu.set_interrupt_flag(mmu::Interrupt.STAT);
            }

            mmu.video_access = mmu::VideoAccess.EVERYTHING;
        }
        case V_BLANK: {
            //Set LCD STAT to mode 1
            mmu.write_bit(mmu::LCD_STAT_REGISTER, 0, true);
            mmu.write_bit(mmu::LCD_STAT_REGISTER, 1, false);

            //Disable PPU + LCD

            if (util::is_bit_set(mmu.read_unchecked(mmu::LCD_STAT_REGISTER), 4)) {
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

    bool is16x8 = util::is_bit_set(mmu.read_unchecked(mmu::LCDC_REGISTER), 2);

    short last_x = -1;
    for (ushort addr = 0xFE00; addr <= 0xFE9F; addr += 4) {
        
        // The amount of sprites already stored in the OAM Buffer must be less than 10
        if (buffer_object_count >= 10) {
            return;
        }

        char y_pos = mmu.read_unchecked(addr + 0);
        char x_pos = mmu.read_unchecked(addr + 1);

        //An object is only added to the buffer if all of the following conditions apply:

        // Sprite X-Position must be greater than 0
        //This can't happen with an unsigned char anyway

        //Overlapping x priority
        if (last_x == x_pos) {
            continue;
        }
        last_x = x_pos;
 
        // LY + 16 must be greater than or equal to Sprite Y-Position
        if (scanline + 16 < y_pos) {
            continue;
        }

        // LY + 16 must be less than Sprite Y-Position + Sprite Height (8 in Normal Mode, 16 in Tall-Sprite-Mode)
        if (scanline + 16 >= y_pos + (is16x8 ? 16 : 8)) {
            continue;
        }

        self.object_buffer[buffer_object_count] = addr;
        buffer_object_count++;
    }
}

fn void Ppu.draw_scanline(&self, Mmu* mmu, char ly) {

    bool background = false;
    bool window = true;
    bool obj = false;

    char lcdc = mmu.read_unchecked(mmu::LCDC_REGISTER);

    if (background && util::is_bit_set(lcdc, 0)) {
        self.draw_bg_line(mmu, ly);
    }

    if (window && util::is_bit_set(lcdc, 0) && util::is_bit_set(lcdc, 5)) {
        self.draw_window_line(mmu, ly);
    }
    
    if (obj && util::is_bit_set(lcdc, 1)) {
        self.draw_objects(mmu, ly);
    }
}

fn void Ppu.draw_bg_line(&self, Mmu* mmu, ushort screen_y) {

    char lcdc = mmu.read_unchecked(mmu::LCDC_REGISTER);
    
    AddressingMode addressing_mode = util::is_bit_set(lcdc, 4)
        ? MODE_8000 
        : MODE_8800;

    char palette_data = mmu.read_unchecked(mmu::BGP_REGISTER);

    const char TILE_LENGTH = 8;
    const char TILES_PER_LINE = 32;

    for (ushort screen_x = 0; screen_x < 256; screen_x += 8) {
        //Scroll the screen
        char scrolled_y = (char)screen_y + self.scroll_y;
        char scrolled_x = (char)screen_x + self.scroll_x;

        char tile_row = scrolled_y / TILE_LENGTH; //row of the tile on the screen
        char tile_col = scrolled_x / TILE_LENGTH; //col of the tile on the screen

        char tile_y = scrolled_y % TILE_LENGTH; //the row of pixels in the tile itself

        //Get address index of the current tile
        ushort bg_tile_data_area_start = util::is_bit_set(lcdc, 3)
            ? 0x9C00
            : 0x9800;
        ushort tile_idx = ((ushort)tile_row * TILES_PER_LINE) + tile_col;

        ushort address = bg_tile_data_area_start + tile_idx;

        //Get the tile index
        char tile_id = mmu.read_unchecked(address);

        char[8] pixel_row = get_tile_row(mmu, addressing_mode, tile_id, tile_y);

        for (char x = 0; x < 8; x++) {

            ushort offset = (screen_y * 256u16) + screen_x + x;

            // if (x == 0 || screen_y % 8 == 0) {
            //     self.pixels[offset] = 0xFFFF00FF;
            //     continue;
            // }

            char pixel = pixel_row[x];
            char value = (palette_data & (0b11 << (2 * pixel))) >> (2 * pixel);

            switch (value) {
                case 0: self.pixels[offset] = DEFAULT_GB_PALETTE.white;
                case 1: self.pixels[offset] = DEFAULT_GB_PALETTE.light;
                case 2: self.pixels[offset] = DEFAULT_GB_PALETTE.dark;
                case 3: self.pixels[offset] = DEFAULT_GB_PALETTE.black;
                default: self.pixels[offset] = 0xFFFF00FF;
            }
            
        } 
    }
}


fn void Ppu.draw_window_line(&self, Mmu* mmu, ushort screen_y) {

    char lcdc = mmu.read_unchecked(mmu::LCDC_REGISTER);
    
    AddressingMode addressing_mode = util::is_bit_set(lcdc, 4)
        ? MODE_8000 
        : MODE_8800;

    char palette_data = mmu.read_unchecked(mmu::BGP_REGISTER);

    const char TILE_LENGTH = 8;
    const char TILES_PER_LINE = 32;

    char wy = mmu.read_unchecked(mmu::WY_REGISTER);
    char wx = mmu.read_unchecked(mmu::WX_REGISTER);

    if (wx > 166 || wy > 143) {
        return;
    }

    for (ushort screen_x = 0; screen_x < 256; screen_x += 8) {
        //Scroll the screen
        char scrolled_y = (char)screen_y - wy;
        char scrolled_x = (char)screen_x - wx - 7;

        char tile_row = scrolled_y / TILE_LENGTH; //row of the tile on the screen
        char tile_col = scrolled_x / TILE_LENGTH; //col of the tile on the screen

        char tile_y = scrolled_y % TILE_LENGTH; //the row of pixels in the tile itself

        //Get address index of the current tile
        ushort window_tile_data_area_start = util::is_bit_set(lcdc, 6)
            ? 0x9C00
            : 0x9800;
        ushort tile_idx = ((ushort)tile_row * TILES_PER_LINE) + tile_col;

        ushort address = window_tile_data_area_start + tile_idx;

        //Get the tile index
        char tile_id = mmu.read_unchecked(address);

        char[8] pixel_row = get_tile_row(mmu, addressing_mode, tile_id, tile_y);

        for (char x = 0; x < 8; x++) {

            ushort offset = (screen_y * 256u16) + screen_x + x;

            // if (x == 0 || screen_y % 8 == 0) {
            //     self.pixels[offset] = 0xFFFF00FF;
            //     continue;
            // }

            char pixel = pixel_row[x];
            char value = (palette_data & (0b11 << (2 * pixel))) >> (2 * pixel);

            switch (value) {
                case 0: self.pixels[offset] = DEFAULT_GB_PALETTE.white;
                case 1: self.pixels[offset] = DEFAULT_GB_PALETTE.light;
                case 2: self.pixels[offset] = DEFAULT_GB_PALETTE.dark;
                case 3: self.pixels[offset] = DEFAULT_GB_PALETTE.black;
                default: self.pixels[offset] = 0xFFFF00FF;
            }
            
        } 
    }
}

//TODO: This isn't how the gameboy does it, but this produces better visuals for now
fn void Ppu.draw_objects(&self, Mmu* mmu, char scanline) {

    char lcdc = mmu.read_unchecked(mmu::LCDC_REGISTER);

    bool is16x8 = util::is_bit_set(lcdc, 2);

    //search the object buffer for any suitable objs
    foreach (address: self.object_buffer) {
        if (address == 0) break; //reached the end of the buffer, no more objects to render

        char y_pos      = mmu.read_unchecked(address + 0);
        char x_pos      = mmu.read_unchecked(address + 1);
        char tile_index = mmu.read_unchecked(address + 2);
        char attributes = mmu.read_unchecked(address + 3);

        if (is16x8) {
            //Bit 0 of tile index for 8x16 objects should be ignored
            tile_index &= 0b1111_1110;
            if (scanline >= y_pos) {
                tile_index++;
            }
        }

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
        
        char y = scanline - (y_pos - 16);
        char row = y_flip ? is16x8 ? 15 - y : 7 - y : y;

        char[8] tile_row = get_tile_row(mmu, AddressingMode.MODE_8000, tile_index, row);
        
        bool priority = util::is_bit_set(attributes, 7);

        for (char x = 0; x < 8; x ++) {

            ushort offset = scanline * 256u16 + (x_pos - 8) + x;

            char col = x_flip ? 7 - x : x;
            
            uint pixel = palette[tile_row[col]];
            if (pixel != 0) {
                if (!priority || self.pixels[offset] == DEFAULT_GB_PALETTE.white) {
                    self.pixels[offset] = pixel;
                }
            }
        }
    }
}

fn uint Ppu.get_obj_pixel(&self, Mmu* mmu, char y, char x) {
    //search the object buffer for any suitable objs

    uint pixel = 0;
    foreach (address: self.object_buffer) { //TODO: this could be more efficient than searching the whole array each pixel...
        if (address == 0) return pixel; //reached the end of the buffer, no object to render

        char x_pos      = mmu.read_unchecked(address + 1);
        //is the obj captured in the current x pixel? y is true since oam scan returned it
        if (x_pos < x || x_pos >= x + 8) continue;

        char y_pos      = mmu.read_unchecked(address + 0);
        char tile_index = mmu.read_unchecked(address + 2);
        char attributes = mmu.read_unchecked(address + 3);

        //TODO: Get correct VRAM bank from attribute bit 3
        bool y_flip = util::is_bit_set(attributes, 6);
        bool x_flip = util::is_bit_set(attributes, 5);
        
        // char priority = util::get_bit(attributes, 7);
        // if (priority == 1) {
        //     //BG and Window colors 1–3 are drawn over this OBJ
        //     return 0;
        // }
        
        char obj_y = y - (y_pos - 16);
        char row = y_flip ? 7 - obj_y : obj_y;

        char[8] tile_row = get_tile_row(mmu, AddressingMode.MODE_8000, tile_index, row);

        char obj_x = 7 - (x_pos - x);

        char col = x_flip ? 7 - obj_x : obj_x;

        ushort palette_register = util::is_bit_set(attributes, 4)
            ? mmu::OBP1_REGISTER
            : mmu::OBP0_REGISTER;

        char pixel_id = tile_row[col];
        if (pixel_id == 0) {
            continue;
        }

        char palette_data = mmu.read_unchecked(palette_register);
        char value = (palette_data & (0b11 << (2 * pixel_id))) >> (2 * pixel_id);
        switch (value) {
            case 0: pixel = DEFAULT_GB_PALETTE.white;
            case 1: pixel = DEFAULT_GB_PALETTE.light;
            case 2: pixel = DEFAULT_GB_PALETTE.dark;
            case 3: pixel = DEFAULT_GB_PALETTE.black;
            default: return 0xFFFF00FF;
        }
    }
    return pixel;
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