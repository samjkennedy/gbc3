module util;

fn char get_bit(char value, char bit) {
    return (char) ((value & (1 << bit)) != 0);
}

fn bool is_bit_set(char value, char bit) {
    return (value & (1 << bit)) != 0;
}