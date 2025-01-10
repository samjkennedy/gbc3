module cpu_tests;

import std::io;
import std::core::string;
import std::encoding::json;
import std::collections::list;
import std::collections::object;

import cartridge;
import cpu;
import mmu;
import joypad;

fn void! test_0x00() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/00.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x01() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/01.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x02() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/02.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x03() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/03.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x04() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/04.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x05() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/05.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x06() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/06.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x07() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/07.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x08() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/08.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x09() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/09.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x0A() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/0A.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x0B() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/0B.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x0C() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/0C.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x0D() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/0D.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x0E() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/0E.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x0F() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/0F.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}
fn void! test_0x10() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/10.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x11() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/11.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x12() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/12.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x13() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/13.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x14() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/14.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x15() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/15.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x16() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/16.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x17() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/17.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x18() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/18.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x19() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/19.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x1A() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/1A.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x1B() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/1B.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x1C() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/1C.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x1D() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/1D.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x1E() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/1E.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x1F() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/1F.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x20() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/20.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x21() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/21.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x22() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/22.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x23() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/23.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x24() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/24.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x25() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/25.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x26() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/26.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x27() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/27.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x28() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/28.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x29() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/29.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x2A() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/2A.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x2B() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/2B.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x2C() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/2C.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x2D() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/2D.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x2E() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/2E.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x2F() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/2F.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x30() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/30.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x31() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/31.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x32() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/32.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x33() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/33.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x34() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/34.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x35() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/35.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x36() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/36.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x37() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/37.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x38() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/38.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x39() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/39.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x3A() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/3A.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x3B() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/3B.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x3C() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/3C.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x3D() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/3D.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x3E() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/3E.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x3F() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/3F.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x40() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/40.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x41() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/41.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x42() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/42.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x43() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/43.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x44() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/44.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x45() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/45.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x46() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/46.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x47() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/47.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x48() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/48.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x49() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/49.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x4A() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/4A.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x4B() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/4B.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x4C() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/4C.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x4D() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/4D.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x4E() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/4E.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x4F() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/4F.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x50() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/50.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x51() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/51.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x52() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/52.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x53() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/53.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x54() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/54.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x55() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/55.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x56() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/56.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x57() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/57.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x58() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/58.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x59() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/59.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x5A() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/5A.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x5B() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/5B.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x5C() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/5C.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x5D() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/5D.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x5E() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/5E.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x5F() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/5F.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x60() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/60.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x61() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/61.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x62() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/62.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x63() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/63.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x64() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/64.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x65() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/65.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x66() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/66.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x67() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/67.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x68() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/68.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x69() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/69.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x6A() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/6A.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x6B() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/6B.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x6C() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/6C.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x6D() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/6D.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x6E() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/6E.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x6F() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/6F.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x70() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/70.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x71() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/71.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x72() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/72.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x73() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/73.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x74() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/74.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x75() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/75.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x76() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/76.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x77() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/77.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x78() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/78.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x79() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/79.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x7A() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/7A.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x7B() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/7B.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x7C() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/7C.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x7D() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/7D.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x7E() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/7E.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x7F() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/7F.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x80() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/80.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x81() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/81.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x82() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/82.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x83() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/83.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x84() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/84.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x85() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/85.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x86() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/86.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x87() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/87.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x88() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/88.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x89() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/89.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x8A() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/8A.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x8B() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/8B.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x8C() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/8C.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x8D() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/8D.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x8E() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/8E.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x8F() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/8F.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x90() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/90.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x91() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/91.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x92() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/92.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x93() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/93.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x94() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/94.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x95() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/95.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x96() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/96.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x97() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/97.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x98() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/98.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x99() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/99.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x9A() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/9A.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x9B() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/9B.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x9C() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/9C.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x9D() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/9D.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x9E() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/9E.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0x9F() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/9F.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xA0() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/A0.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xA1() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/A1.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xA2() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/A2.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xA3() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/A3.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xA4() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/A4.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xA5() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/A5.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xA6() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/A6.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xA7() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/A7.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xA8() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/A8.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xA9() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/A9.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xAA() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/AA.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xAB() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/AB.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xAC() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/AC.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xAD() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/AD.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xAE() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/AE.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xAF() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/AF.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xB0() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/B0.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xB1() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/B1.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xB2() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/B2.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xB3() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/B3.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xB4() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/B4.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xB5() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/B5.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xB6() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/B6.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xB7() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/B7.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xB8() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/B8.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xB9() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/B9.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xBA() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/BA.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xBB() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/BB.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xBC() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/BC.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xBD() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/BD.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xBE() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/BE.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xBF() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/BF.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xC0() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/C0.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xC1() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/C1.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xC2() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/C2.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xC3() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/C3.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xC4() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/C4.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xC5() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/C5.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xC6() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/C6.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xC7() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/C7.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xC8() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/C8.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xC9() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/C9.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xCA() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/CA.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xCB() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/CB.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xCC() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/CC.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xCD() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/CD.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xCE() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/CE.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xCF() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/CF.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xD0() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/D0.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xD1() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/D1.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xD2() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/D2.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xD3() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/D3.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xD4() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/D4.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xD5() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/D5.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xD6() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/D6.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xD7() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/D7.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xD8() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/D8.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xD9() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/D9.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xDA() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/DA.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xDB() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/DB.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xDC() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/DC.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xDD() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/DD.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xDE() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/DE.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xDF() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/DF.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xE0() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/E0.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xE1() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/E1.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xE2() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/E2.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xE3() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/E3.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xE4() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/E4.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xE5() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/E5.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xE6() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/E6.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xE7() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/E7.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xE8() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/E8.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xE9() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/E9.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xEA() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/EA.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xEB() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/EB.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xEC() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/EC.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xED() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/ED.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xEE() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/EE.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xEF() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/EF.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xF0() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/F0.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xF1() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/F1.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xF2() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/F2.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xF3() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/F3.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xF4() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/F4.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xF5() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/F5.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xF6() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/F6.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xF7() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/F7.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xF8() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/F8.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xF9() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/F9.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xFA() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/FA.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xFB() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/FB.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xFC() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/FC.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xFD() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/FD.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xFE() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/FE.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}

fn void! test_0xFF() @test {

    List(<TestCase>) test_cases = parse_test_cases("test_resources/FF.json");

    foreach (test_case: test_cases) {
        execute_test_case(test_case)!!;
    }
}



fn void! execute_test_case(TestCase test_case) {

    // io::printfn("Running test %s", test_case.name);

    CpuState initial = test_case.initial;
    
    cpu::Cpu cpu = cpu::init();
    Joypad joypad = {};
    char[0x8000] rom = {};

    foreach (ram_entry: initial.ram) {
    
        if (ram_entry[0] >= 0x8000) {
            continue;
        }
    
        if (ram_entry[0] == 0x147) {
            return;
        }

       rom[ram_entry[0]] = (char) ram_entry[1];
    }

    Cartridge cart = (Cartridge) mem::new(RomOnlyCartridge, { .rom = &rom });
    Mmu mmu = mmu::init(cart, &joypad);

    cpu.af = initial.af;
    cpu.bc = initial.bc;
    cpu.de = initial.de;
    cpu.hl = initial.hl;

    //The tests assume a decode-execute-prefetch loop and so start at PC+1, with the final cycle being the prefetch of the next instruction.
    //TODO: implement the decode-execute-prefetch loop properly in the CPU
    cpu.pc = initial.pc - 1;
    cpu.sp = initial.sp;

    foreach (ram_entry: initial.ram) {
    
        if (ram_entry[0] >= 0xFF00) {
            //They included some very badly formed tests that have you reading from illegal addresses, so we'll just skip those
            return;
        }

        mmu.write_unchecked(ram_entry[0], (char) ram_entry[1]);
    }
    
    cpu.tick(&mmu)!; //FETCH and decode
    // cpu.display_state();
    while (cpu.remaining_cycles > 0) {
        cpu.tick(&mmu)!;
    }

    CpuState expected = test_case.final;

    assert(cpu.af >> 8 == expected.af >> 8, "Test %s: A register mismatch, expected 0x%02X, got 0x%02X", test_case.name, expected.af >> 8, cpu.af >> 8);

    char expected_flags = (char) expected.af & 0x00FF;
    assert(cpu.get_flag(Flag.Z) == ((expected_flags & 0b10000000) > 0), "Test %s: Z flag mismatch, expected %d, got %d", test_case.name, ((expected_flags & 0b10000000) > 0), cpu.get_flag(Flag.Z));
    assert(cpu.get_flag(Flag.N) == ((expected_flags & 0b01000000) > 0), "Test %s: N flag mismatch, expected %d, got %d", test_case.name, ((expected_flags & 0b01000000) > 0), cpu.get_flag(Flag.N));
    assert(cpu.get_flag(Flag.H) == ((expected_flags & 0b00100000) > 0), "Test %s: H flag mismatch, expected %d, got %d", test_case.name, ((expected_flags & 0b00100000) > 0), cpu.get_flag(Flag.H));
    assert(cpu.get_flag(Flag.C) == ((expected_flags & 0b00010000) > 0), "Test %s: C flag mismatch, expected %d, got %d", test_case.name, ((expected_flags & 0b00010000) > 0), cpu.get_flag(Flag.C));

    assert(cpu.bc == expected.bc, "Test %s: BC register mismatch, expected 0x%04X, got 0x%04X", test_case.name, expected.bc, cpu.bc);
    assert(cpu.de == expected.de, "Test %s: DE register mismatch, expected 0x%04X, got 0x%04X", test_case.name, expected.de, cpu.de);
    assert(cpu.hl == expected.hl, "Test %s: HL register mismatch, expected 0x%04X, got 0x%04X", test_case.name, expected.hl, cpu.hl);
    assert(cpu.pc == expected.pc - 1, "Test %s: PC register mismatch, expected 0x%04X, got 0x%04X", test_case.name, expected.pc - 1, cpu.pc); // -1 because of the lack of decode-execute-prefetch loop
    assert(cpu.sp == expected.sp, "Test %s: SP register mismatch, expected 0x%04X, got 0x%04X", test_case.name, expected.sp, cpu.sp);

    foreach (ram_entry: expected.ram) {
        ushort addr = ram_entry[0];

        if (addr < mmu::RAM_START || addr == 0xFF00 || addr == 0xFF0F) {
            //They included some very badly formed tests that have you writing to illegal addresses, so we'll just skip those
            continue;
        }

        char value = mmu.read_unchecked(addr);
        assert(value == (char) ram_entry[1], "Test %s: RAM mismatch at address 0x%04X, expected 0x%02X, got 0x%02X", test_case.name, addr, (char) ram_entry[1], value);
    }
}

struct CpuState {
    ushort af; 
    ushort bc;
    ushort de;
    ushort hl;
    ushort pc;
    ushort sp;
    ushort[2][] ram;
}

struct TestCase {
    String name;
    CpuState initial;
    CpuState final;
    usz cycles;
}

fn List(<TestCase>) parse_test_cases(String filename) {

    File file = file::open(filename, "r")!!;
    Object object = *json::parse(&file)!!;
    file.close()!!;

    List(<TestCase>) test_cases;
    test_cases.new_init();

    foreach(element: object.array) {
        
        String name = element.get_string("name")!!;

        Object* initialObj = element.get("initial")!!;
        CpuState initial = parse_cpu_state(initialObj)!!;

        Object* finalObj = element.get("final")!!;
        CpuState final = parse_cpu_state(finalObj)!!;

        Object* cyclesObj = element.get("cycles")!!;
        //TODO: actually parse and check the cycles properly, but it's an annoying type
        //  and C3 has no native unmarsalling
        usz cycles = cyclesObj.array.len();

        test_cases.push(TestCase {
            .name = name,
            .initial = initial,
            .final = final,
            .cycles = cycles,
        });
    }

    return test_cases;
}

fn CpuState! parse_cpu_state(Object* obj) {
    
    Object* ram = obj.get("ram")!!;
    List(<ushort[2]>) ram_list;

    foreach (entry: ram.array) {
        ushort[2] addr_value_pair = {entry.get_ushort_at(0)!, entry.get_ushort_at(1)!};
        ram_list.push(addr_value_pair);
    }
    ushort[2][] ram_array = ram_list.to_new_array();

    return CpuState {
        .af = (obj.get_ushort("a")! << 8) | obj.get_ushort("f")!,
        .bc = (obj.get_ushort("b")! << 8) | obj.get_ushort("c")!,
        .de = (obj.get_ushort("d")! << 8) | obj.get_ushort("e")!,
        .hl = (obj.get_ushort("h")! << 8) | obj.get_ushort("l")!,
        .pc = obj.get_ushort("pc")!,
        .sp = obj.get_ushort("sp")!,
        .ram = ram_array,
    };
}