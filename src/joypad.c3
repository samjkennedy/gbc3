module joypad;

import std::io;

import mmu;

struct Joypad {
    char state;
}

enum JoypadButton: char {
    START,
    SELECT,
    B,
    A, 
    DOWN,
    UP,
    LEFT,
    RIGHT,
}

enum ButtonMode {
    D_PAD,
    BUTTONS
}

fn void Joypad.press(&self, Mmu* mmu, JoypadButton button) {
    switch (button) {
        case START:     self.state &= (char)~0x80;
        case SELECT:    self.state &= (char)~0x40;
        case B:         self.state &= (char)~0x20;
        case A:         self.state &= (char)~0x10;
        case DOWN:      self.state &= (char)~0x08;
        case UP:        self.state &= (char)~0x04;
        case LEFT:      self.state &= (char)~0x02;
        case RIGHT:     self.state &= (char)~0x01;
    }
    // mmu.set_interrupt_flag(mmu::Interrupt.JOYPAD);
}

fn void Joypad.release(&self, JoypadButton button) {
    switch (button) {
        case START:     self.state |= 0x80;
        case SELECT:    self.state |= 0x40;
        case B:         self.state |= 0x20;
        case A:         self.state |= 0x10;
        case DOWN:      self.state |= 0x08;
        case UP:        self.state |= 0x04;
        case LEFT:      self.state |= 0x02;
        case RIGHT:     self.state |= 0x01;
    }
}

fn char Joypad.read(&self, ButtonMode mode) {
    
    switch (mode) {
        case D_PAD:   return self.state & 0x0F;
        case BUTTONS: return self.state >> 4;
    }
}