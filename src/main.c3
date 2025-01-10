module gbc3;

import std::io;
import std::core::string;
import std::core::mem;
import std::time;
import std::thread;

import cartridge;
import cpu;
import mmu;
import ppu;
import joypad;

import raylib5::rl;

//TODO: allow this to change at runtime
const int SCALE = 4;
const int SCREEN_WIDTH = 160;
const int SCREEN_HEIGHT = 144;
const int WINDOW_WIDTH = SCREEN_WIDTH * SCALE;
const int WINDOW_HEIGHT = SCREEN_HEIGHT * SCALE;

const int DOTS_PER_SCANLINE = 456;
const int DOTS_PER_FRAME = 70224;

fn void! main(String[] args)
{
    bool enable_logging = false;

    if (args.len < 2) {
        io::printfn("Usage: gbc3 <filename>");
        return;
    }
    String filename = args[1];


    File file = file::open(filename, "r")!!;
    Cartridge cartridge = cartridge::parse(&file)!!;
    file.close()!!;

    defer mem::free(cartridge);
    
    Joypad joypad = {};
    Mmu mmu = mmu::init(cartridge, &joypad);

    Ppu ppu = ppu::init();
    Cpu cpu = cpu::init();

    rl::initWindow(WINDOW_WIDTH, WINDOW_HEIGHT, (String)cartridge.title());

    rl::Image image = rl::Image {
        .data = (void*)&ppu.pixels,
        .width = 256,
        .height = 256,
        .format = rl::PixelFormat.UNCOMPRESSED_R8G8B8A8,
        .mipmaps = 1,
    };
    rl::Texture2D texture = rl::loadTextureFromImage(image);

    rl::setTargetFPS(60); //Technically should be 59.7 but we'll burn that bridge when we come to it
    for (int t = 0; !rl::windowShouldClose(); t++) @pool() {

        handle_inputs(&mmu, &joypad);

        cpu.tick(&mmu)!!;
        ppu.dot(&mmu);

        if (t % DOTS_PER_FRAME == 0) {
            rl::@drawing() {
                rl::clearBackground(rl::Color {0xE0, 0xF8, 0xD0, 0xFF});

                rl::updateTexture(texture, (void*)&ppu.pixels);

                char scroll_y = mmu.read(mmu::SCY_REGISTER);
                char scroll_x = mmu.read(mmu::SCX_REGISTER);

                rl::setTextureWrap(texture, 0);

                rl::drawTexturePro(
                    texture, 
                    rl::Rectangle { 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT}, //src resolution
                    rl::Rectangle { 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT}, //dst resolution
                    rl::Vector2 { 0, 0 }, //origin
                    0.0f, //rotation
                    rl::WHITE //tint
                );
                ppu.pixels = {};
                    
                //TODO: toggle this with a debug key/option
                if (false) {
                    rl::drawText(string::tformat_zstr("%d", rl::getFPS()), SCALE, SCALE, 8 * SCALE, rl::RED);
                }
            };
        }
    };

    rl::closeWindow();
}

fn void handle_inputs(Mmu* mmu, Joypad* joypad) {
    //TODO rebinding/controllers
    if (rl::isKeyDown(rl::KEY_LEFT)) {
        joypad.press(mmu, JoypadButton.LEFT);
    }
    if (rl::isKeyUp(rl::KEY_LEFT)) {
        joypad.release(JoypadButton.LEFT);
    }
    
    if (rl::isKeyDown(rl::KEY_RIGHT)) {
        joypad.press(mmu, JoypadButton.RIGHT);
    }
    if (rl::isKeyUp(rl::KEY_RIGHT)) {
        joypad.release(JoypadButton.RIGHT);
    }
    
    if (rl::isKeyDown(rl::KEY_UP)) {
        joypad.press(mmu, JoypadButton.UP);
    }
    if (rl::isKeyUp(rl::KEY_UP)) {
        joypad.release(JoypadButton.UP);
    }
    
    if (rl::isKeyDown(rl::KEY_DOWN)) {
        joypad.press(mmu, JoypadButton.DOWN);
    }
    if (rl::isKeyUp(rl::KEY_DOWN)) {
        joypad.release(JoypadButton.DOWN);
    }


    if (rl::isKeyDown(rl::KEY_Z)) {
        joypad.press(mmu, JoypadButton.B);
    }
    if (rl::isKeyUp(rl::KEY_Z)) {
        joypad.release(JoypadButton.B);
    }

    if (rl::isKeyDown(rl::KEY_X)) {
        joypad.press(mmu, JoypadButton.A);
    }
    if (rl::isKeyUp(rl::KEY_X)) {
        joypad.release(JoypadButton.A);
    }

    if (rl::isKeyDown(rl::KEY_ENTER)) {
        joypad.press(mmu, JoypadButton.START);
    }
    if (rl::isKeyUp(rl::KEY_ENTER)) {
        joypad.release(JoypadButton.START);
    }

    if (rl::isKeyDown(rl::KEY_BACKSPACE)) {
        joypad.press(mmu, JoypadButton.SELECT);
    }
    if (rl::isKeyUp(rl::KEY_BACKSPACE)) {
        joypad.release(JoypadButton.SELECT);
    }
}
