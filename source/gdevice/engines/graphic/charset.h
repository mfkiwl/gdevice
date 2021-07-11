#pragma once

const unsigned char charset6x8[][8+2] = {
	{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0,5}, // space
	{0x00,0x20,0x00,0x20,0x20,0x20,0x20,0x20,2,2}, // !
	{0x00,0x00,0x00,0x00,0x00,0x00,0x50,0x50,1,4}, // "
	{0x00,0x50,0x50,0xf8,0x50,0xf8,0x50,0x50,0,6}, // #
	{0x00,0x20,0x70,0x28,0x70,0xa0,0x70,0x20,0,6}, // $
	{0x00,0x98,0x58,0x40,0x20,0x10,0xd0,0xc8,0,6}, // %
	{0x00,0x68,0x90,0xa8,0x40,0xa0,0x90,0x60,0,6}, // &
	{0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x20,1,3}, // '
	{0x00,0x20,0x40,0x40,0x40,0x40,0x40,0x20,1,3}, // (
	{0x00,0x20,0x10,0x10,0x10,0x10,0x10,0x20,2,3}, // )
	{0x00,0x00,0x20,0xa8,0x70,0xa8,0x20,0x00,0,6}, // *
	{0x00,0x00,0x20,0x20,0xf8,0x20,0x20,0x00,0,6}, // +
	{0x40,0x20,0x00,0x00,0x00,0x00,0x00,0x00,1,3}, // ,
	{0x00,0x00,0x00,0x00,0xf8,0x00,0x00,0x00,0,6}, // -
	{0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0,3}, // .
	{0x00,0x40,0x40,0x20,0x20,0x20,0x10,0x10,1,4}, // /
	{0x00,0x70,0x88,0xc8,0xa8,0x98,0x88,0x70,0,6}, // 0
	{0x00,0x70,0x20,0x20,0x20,0x20,0x60,0x20,0,6}, // 1
	{0x00,0xf8,0x80,0x40,0x30,0x08,0x88,0x70,0,6}, // 2
	{0x00,0xf0,0x08,0x08,0x70,0x08,0x08,0xf0,0,6}, // 3
	{0x00,0x10,0x10,0xf8,0x90,0x50,0x30,0x10,0,6}, // 4
	{0x00,0xf0,0x08,0x08,0x70,0x80,0x80,0xf0,0,6}, // 5
	{0x00,0x70,0x88,0x88,0xf0,0x80,0x80,0x70,0,6}, // 6
	{0x00,0x40,0x40,0x40,0x20,0x10,0x08,0xf8,0,6}, // 7
	{0x00,0x70,0x88,0x88,0x70,0x88,0x88,0x70,0,6}, // 8
	{0x00,0x70,0x08,0x08,0x78,0x88,0x88,0x70,0,6}, // 9
	{0x00,0x60,0x00,0x00,0x60,0x00,0x00,0x00,1,3}, // :
	{0x40,0x20,0x00,0x00,0x60,0x00,0x00,0x00,1,3}, // ;
	{0x00,0x08,0x10,0x20,0x40,0x20,0x10,0x08,1,5}, // <
	{0x00,0x00,0xf8,0x00,0x00,0xf8,0x00,0x00,0,6}, // =
	{0x00,0x40,0x20,0x10,0x08,0x10,0x20,0x40,1,5}, // >
	{0x20,0x00,0x20,0x20,0x10,0x08,0x88,0x70,0,6}, // ?
	{0x00,0x70,0x08,0xe8,0xa8,0x88,0x88,0x70,0,6}, // @
	{0x00,0x88,0x88,0x70,0x50,0x50,0x20,0x20,0,6}, // A
	{0x00,0xf0,0x88,0x88,0xf0,0x88,0x88,0xf0,0,6}, // B
	{0x00,0x78,0x80,0x80,0x80,0x80,0x80,0x78,0,6}, // C
	{0x00,0xf0,0x88,0x88,0x88,0x88,0x88,0xf0,0,6}, // D
	{0x00,0xf8,0x80,0x80,0xf0,0x80,0x80,0xf8,0,6}, // E
	{0x00,0x80,0x80,0x80,0xf0,0x80,0x80,0xf8,0,6}, // F
	{0x00,0x78,0x88,0x88,0x88,0x80,0x80,0x78,0,6}, // G
	{0x00,0x88,0x88,0x88,0xf8,0x88,0x88,0x88,0,6}, // H
	{0x00,0x20,0x20,0x20,0x20,0x20,0x20,0x20,2,2}, // I
	{0x00,0xf0,0x08,0x08,0x08,0x08,0x08,0x08,0,6}, // J
	{0x00,0x88,0x90,0xa0,0xc0,0xa0,0x90,0x88,0,6}, // K
	{0x00,0xf8,0x80,0x80,0x80,0x80,0x80,0x80,0,6}, // L
	{0x00,0x88,0xa8,0xa8,0xd8,0xd8,0x88,0x88,0,6}, // M
	{0x00,0x88,0x98,0x98,0xa8,0xc8,0xc8,0x88,0,6}, // N
	{0x00,0x70,0x88,0x88,0x88,0x88,0x88,0x70,0,6}, // O
	{0x00,0x80,0x80,0x80,0xf0,0x88,0x88,0xf0,0,6}, // P
	{0x00,0x18,0x70,0x88,0x88,0x88,0x88,0x70,0,6}, // Q
	{0x00,0x88,0x88,0x88,0xf0,0x88,0x88,0xf0,0,6}, // R
	{0x00,0xf0,0x08,0x08,0x70,0x80,0x80,0x70,0,6}, // S
	{0x00,0x20,0x20,0x20,0x20,0x20,0x20,0xf8,0,6}, // T
	{0x00,0x70,0x88,0x88,0x88,0x88,0x88,0x88,0,6}, // U
	{0x00,0x20,0x20,0x50,0x50,0x88,0x88,0x88,0,6}, // V
	{0x00,0x50,0x50,0xa8,0xa8,0xa8,0xa8,0x88,0,6}, // W
	{0x00,0x88,0x88,0x50,0x20,0x50,0x88,0x88,0,6}, // X
	{0x00,0x20,0x20,0x20,0x50,0x50,0x88,0x88,0,6}, // Y
	{0x00,0xf8,0x80,0x40,0x20,0x10,0x08,0xf8,0,6}, // Z
	{0x00,0x60,0x40,0x40,0x40,0x40,0x40,0x60,1,3}, // [
	{0x00,0x10,0x10,0x20,0x20,0x20,0x40,0x40,1,4}, // BACKSLASH
	{0x00,0x30,0x10,0x10,0x10,0x10,0x10,0x30,2,3}, // ]
	{0x00,0x00,0x00,0x00,0x00,0x88,0x50,0x20,0,6}, // ^
	{0x00,0xfe,0x00,0x00,0x00,0x00,0x00,0x00,0,6}, // _
	{0x00,0x00,0x00,0x00,0x00,0x00,0x20,0x40,1,3}, // `
	{0x00,0x78,0x88,0x78,0x08,0x70,0x00,0x00,0,6}, // a
	{0x00,0xf0,0x88,0x88,0x88,0xf0,0x80,0x00,0,6}, // b
	{0x00,0x78,0x80,0x80,0x80,0x78,0x00,0x00,0,6}, // c
	{0x00,0x78,0x88,0x88,0x88,0x78,0x08,0x00,0,6}, // d
	{0x00,0x70,0x80,0xf8,0x88,0x70,0x00,0x00,0,6}, // e
	{0x00,0x40,0x40,0x40,0xf0,0x40,0x38,0x00,0,6}, // f
	{0x70,0x08,0x78,0x88,0x88,0x70,0x00,0x00,0,6}, // g
	{0x00,0x88,0x88,0x88,0xf0,0x80,0x80,0x00,0,6}, // h
	{0x00,0x20,0x20,0x20,0x20,0x00,0x20,0x00,2,2}, // i
	{0xe0,0x10,0x10,0x10,0x10,0x00,0x10,0x00,0,5}, // j
	{0x00,0x88,0x90,0xa0,0xc0,0xa0,0x90,0x00,0,6}, // k
	{0x00,0x30,0x40,0x40,0x40,0x40,0x40,0x00,1,4}, // l
	{0x00,0xa8,0xa8,0xa8,0xa8,0x50,0x00,0x00,0,6}, // m
	{0x00,0x88,0x88,0x88,0x88,0x70,0x00,0x00,0,6}, // n
	{0x00,0x70,0x88,0x88,0x88,0x70,0x00,0x00,0,6}, // o
	{0x80,0x80,0xf0,0x88,0x88,0x70,0x00,0x00,0,6}, // p
	{0x08,0x08,0x78,0x88,0x88,0x70,0x00,0x00,0,6}, // q
	{0x00,0x40,0x40,0x40,0x40,0x38,0x00,0x00,1,5}, // r
	{0x00,0xf0,0x08,0x70,0x80,0x70,0x00,0x00,0,6}, // s
	{0x00,0x30,0x40,0x40,0x40,0xf0,0x40,0x00,0,5}, // t
	{0x00,0x70,0x88,0x88,0x88,0x88,0x00,0x00,0,6}, // u
	{0x00,0x20,0x50,0x50,0x88,0x88,0x00,0x00,0,6}, // v
	{0x00,0x50,0x50,0xa8,0xa8,0x88,0x00,0x00,0,6}, // w
	{0x00,0x88,0x50,0x20,0x50,0x88,0x00,0x00,0,6}, // x
	{0x40,0x20,0x20,0x50,0x88,0x88,0x00,0x00,0,6}, // y
	{0x00,0xf8,0x40,0x20,0x10,0xf8,0x00,0x00,0,6}, // z
	{0x20,0x40,0x40,0x80,0x40,0x40,0x40,0x20,0,4}, // {
	{0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,2,2}, // |
	{0x20,0x10,0x10,0x08,0x10,0x10,0x10,0x20,2,4}, // }
	{0x00,0x00,0x00,0x90,0x68,0x00,0x00,0x00,0,6}, //
	{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0,6}  // empty
};
