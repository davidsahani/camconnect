/**************************************************************************

    AVStream Simulated Hardware Sample

    Copyright (c) 2001, Microsoft Corporation.

    File:

        image.cpp

    Abstract:

        The image synthesis and overlay code.  These objects provide image
        synthesis (pixel, color-bar, etc...) onto RGB24 and UYVY buffers as
        well as software string overlay into these buffers.

	This entire file, data and all, must be in locked segments.

    History:

        created 1/16/2001

**************************************************************************/

#include "common.h"

/**************************************************************************

    Constants

**************************************************************************/

//
// g_FontData:
//
// The following is an 8x8 bitmapped font for use in the text overlay
// code.
//
UCHAR g_FontData [256][8] = {
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
    {0x7e, 0x81, 0xa5, 0x81, 0xbd, 0x99, 0x81, 0x7e},
    {0x7e, 0xff, 0xdb, 0xff, 0xc3, 0xe7, 0xff, 0x7e},
    {0x6c, 0xfe, 0xfe, 0xfe, 0x7c, 0x38, 0x10, 0x00},
    {0x10, 0x38, 0x7c, 0xfe, 0x7c, 0x38, 0x10, 0x00},
    {0x38, 0x7c, 0x38, 0xfe, 0xfe, 0x7c, 0x38, 0x7c},
    {0x10, 0x10, 0x38, 0x7c, 0xfe, 0x7c, 0x38, 0x7c},
    {0x00, 0x00, 0x18, 0x3c, 0x3c, 0x18, 0x00, 0x00},
    {0xff, 0xff, 0xe7, 0xc3, 0xc3, 0xe7, 0xff, 0xff},
    {0x00, 0x3c, 0x66, 0x42, 0x42, 0x66, 0x3c, 0x00},
    {0xff, 0xc3, 0x99, 0xbd, 0xbd, 0x99, 0xc3, 0xff},
    {0x0f, 0x07, 0x0f, 0x7d, 0xcc, 0xcc, 0xcc, 0x78},
    {0x3c, 0x66, 0x66, 0x66, 0x3c, 0x18, 0x7e, 0x18},
    {0x3f, 0x33, 0x3f, 0x30, 0x30, 0x70, 0xf0, 0xe0},
    {0x7f, 0x63, 0x7f, 0x63, 0x63, 0x67, 0xe6, 0xc0},
    {0x99, 0x5a, 0x3c, 0xe7, 0xe7, 0x3c, 0x5a, 0x99},
    {0x80, 0xe0, 0xf8, 0xfe, 0xf8, 0xe0, 0x80, 0x00},
    {0x02, 0x0e, 0x3e, 0xfe, 0x3e, 0x0e, 0x02, 0x00},
    {0x18, 0x3c, 0x7e, 0x18, 0x18, 0x7e, 0x3c, 0x18},
    {0x66, 0x66, 0x66, 0x66, 0x66, 0x00, 0x66, 0x00},
    {0x7f, 0xdb, 0xdb, 0x7b, 0x1b, 0x1b, 0x1b, 0x00},
    {0x3e, 0x63, 0x38, 0x6c, 0x6c, 0x38, 0xcc, 0x78},
    {0x00, 0x00, 0x00, 0x00, 0x7e, 0x7e, 0x7e, 0x00},
    {0x18, 0x3c, 0x7e, 0x18, 0x7e, 0x3c, 0x18, 0xff},
    {0x18, 0x3c, 0x7e, 0x18, 0x18, 0x18, 0x18, 0x00},
    {0x18, 0x18, 0x18, 0x18, 0x7e, 0x3c, 0x18, 0x00},
    {0x00, 0x18, 0x0c, 0xfe, 0x0c, 0x18, 0x00, 0x00},
    {0x00, 0x30, 0x60, 0xfe, 0x60, 0x30, 0x00, 0x00},
    {0x00, 0x00, 0xc0, 0xc0, 0xc0, 0xfe, 0x00, 0x00},
    {0x00, 0x24, 0x66, 0xff, 0x66, 0x24, 0x00, 0x00},
    {0x00, 0x18, 0x3c, 0x7e, 0xff, 0xff, 0x00, 0x00},
    {0x00, 0xff, 0xff, 0x7e, 0x3c, 0x18, 0x00, 0x00},
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
    {0x30, 0x78, 0x78, 0x30, 0x30, 0x00, 0x30, 0x00},
    {0x6c, 0x6c, 0x6c, 0x00, 0x00, 0x00, 0x00, 0x00},
    {0x6c, 0x6c, 0xfe, 0x6c, 0xfe, 0x6c, 0x6c, 0x00},
    {0x30, 0x7c, 0xc0, 0x78, 0x0c, 0xf8, 0x30, 0x00},
    {0x00, 0xc6, 0xcc, 0x18, 0x30, 0x66, 0xc6, 0x00},
    {0x38, 0x6c, 0x38, 0x76, 0xdc, 0xcc, 0x76, 0x00},
    {0x60, 0x60, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00},
    {0x18, 0x30, 0x60, 0x60, 0x60, 0x30, 0x18, 0x00},
    {0x60, 0x30, 0x18, 0x18, 0x18, 0x30, 0x60, 0x00},
    {0x00, 0x66, 0x3c, 0xff, 0x3c, 0x66, 0x00, 0x00},
    {0x00, 0x30, 0x30, 0xfc, 0x30, 0x30, 0x00, 0x00},
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x30, 0x60},
    {0x00, 0x00, 0x00, 0xfc, 0x00, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x30, 0x00},
    {0x06, 0x0c, 0x18, 0x30, 0x60, 0xc0, 0x80, 0x00},
    {0x7c, 0xc6, 0xce, 0xde, 0xf6, 0xe6, 0x7c, 0x00},
    {0x30, 0x70, 0x30, 0x30, 0x30, 0x30, 0xfc, 0x00},
    {0x78, 0xcc, 0x0c, 0x38, 0x60, 0xcc, 0xfc, 0x00},
    {0x78, 0xcc, 0x0c, 0x38, 0x0c, 0xcc, 0x78, 0x00},
    {0x1c, 0x3c, 0x6c, 0xcc, 0xfe, 0x0c, 0x1e, 0x00},
    {0xfc, 0xc0, 0xf8, 0x0c, 0x0c, 0xcc, 0x78, 0x00},
    {0x38, 0x60, 0xc0, 0xf8, 0xcc, 0xcc, 0x78, 0x00},
    {0xfc, 0xcc, 0x0c, 0x18, 0x30, 0x30, 0x30, 0x00},
    {0x78, 0xcc, 0xcc, 0x78, 0xcc, 0xcc, 0x78, 0x00},
    {0x78, 0xcc, 0xcc, 0x7c, 0x0c, 0x18, 0x70, 0x00},
    {0x00, 0x30, 0x30, 0x00, 0x00, 0x30, 0x30, 0x00},
    {0x00, 0x30, 0x30, 0x00, 0x00, 0x30, 0x30, 0x60},
    {0x18, 0x30, 0x60, 0xc0, 0x60, 0x30, 0x18, 0x00},
    {0x00, 0x00, 0xfc, 0x00, 0x00, 0xfc, 0x00, 0x00},
    {0x60, 0x30, 0x18, 0x0c, 0x18, 0x30, 0x60, 0x00},
    {0x78, 0xcc, 0x0c, 0x18, 0x30, 0x00, 0x30, 0x00},
    {0x7c, 0xc6, 0xde, 0xde, 0xde, 0xc0, 0x78, 0x00},
    {0x30, 0x78, 0xcc, 0xcc, 0xfc, 0xcc, 0xcc, 0x00},
    {0xfc, 0x66, 0x66, 0x7c, 0x66, 0x66, 0xfc, 0x00},
    {0x3c, 0x66, 0xc0, 0xc0, 0xc0, 0x66, 0x3c, 0x00},
    {0xf8, 0x6c, 0x66, 0x66, 0x66, 0x6c, 0xf8, 0x00},
    {0xfe, 0x62, 0x68, 0x78, 0x68, 0x62, 0xfe, 0x00},
    {0xfe, 0x62, 0x68, 0x78, 0x68, 0x60, 0xf0, 0x00},
    {0x3c, 0x66, 0xc0, 0xc0, 0xce, 0x66, 0x3e, 0x00},
    {0xcc, 0xcc, 0xcc, 0xfc, 0xcc, 0xcc, 0xcc, 0x00},
    {0x78, 0x30, 0x30, 0x30, 0x30, 0x30, 0x78, 0x00},
    {0x1e, 0x0c, 0x0c, 0x0c, 0xcc, 0xcc, 0x78, 0x00},
    {0xe6, 0x66, 0x6c, 0x78, 0x6c, 0x66, 0xe6, 0x00},
    {0xf0, 0x60, 0x60, 0x60, 0x62, 0x66, 0xfe, 0x00},
    {0xc6, 0xee, 0xfe, 0xfe, 0xd6, 0xc6, 0xc6, 0x00},
    {0xc6, 0xe6, 0xf6, 0xde, 0xce, 0xc6, 0xc6, 0x00},
    {0x38, 0x6c, 0xc6, 0xc6, 0xc6, 0x6c, 0x38, 0x00},
    {0xfc, 0x66, 0x66, 0x7c, 0x60, 0x60, 0xf0, 0x00},
    {0x78, 0xcc, 0xcc, 0xcc, 0xdc, 0x78, 0x1c, 0x00},
    {0xfc, 0x66, 0x66, 0x7c, 0x6c, 0x66, 0xe6, 0x00},
    {0x78, 0xcc, 0xe0, 0x70, 0x1c, 0xcc, 0x78, 0x00},
    {0xfc, 0xb4, 0x30, 0x30, 0x30, 0x30, 0x78, 0x00},
    {0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xfc, 0x00},
    {0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0x78, 0x30, 0x00},
    {0xc6, 0xc6, 0xc6, 0xd6, 0xfe, 0xee, 0xc6, 0x00},
    {0xc6, 0xc6, 0x6c, 0x38, 0x38, 0x6c, 0xc6, 0x00},
    {0xcc, 0xcc, 0xcc, 0x78, 0x30, 0x30, 0x78, 0x00},
    {0xfe, 0xc6, 0x8c, 0x18, 0x32, 0x66, 0xfe, 0x00},
    {0x78, 0x60, 0x60, 0x60, 0x60, 0x60, 0x78, 0x00},
    {0xc0, 0x60, 0x30, 0x18, 0x0c, 0x06, 0x02, 0x00},
    {0x78, 0x18, 0x18, 0x18, 0x18, 0x18, 0x78, 0x00},
    {0x10, 0x38, 0x6c, 0xc6, 0x00, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff},
    {0x30, 0x30, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0x78, 0x0c, 0x7c, 0xcc, 0x76, 0x00},
    {0xe0, 0x60, 0x60, 0x7c, 0x66, 0x66, 0xdc, 0x00},
    {0x00, 0x00, 0x78, 0xcc, 0xc0, 0xcc, 0x78, 0x00},
    {0x1c, 0x0c, 0x0c, 0x7c, 0xcc, 0xcc, 0x76, 0x00},
    {0x00, 0x00, 0x78, 0xcc, 0xfc, 0xc0, 0x78, 0x00},
    {0x38, 0x6c, 0x60, 0xf0, 0x60, 0x60, 0xf0, 0x00},
    {0x00, 0x00, 0x76, 0xcc, 0xcc, 0x7c, 0x0c, 0xf8},
    {0xe0, 0x60, 0x6c, 0x76, 0x66, 0x66, 0xe6, 0x00},
    {0x30, 0x00, 0x70, 0x30, 0x30, 0x30, 0x78, 0x00},
    {0x0c, 0x00, 0x0c, 0x0c, 0x0c, 0xcc, 0xcc, 0x78},
    {0xe0, 0x60, 0x66, 0x6c, 0x78, 0x6c, 0xe6, 0x00},
    {0x70, 0x30, 0x30, 0x30, 0x30, 0x30, 0x78, 0x00},
    {0x00, 0x00, 0xcc, 0xfe, 0xfe, 0xd6, 0xc6, 0x00},
    {0x00, 0x00, 0xf8, 0xcc, 0xcc, 0xcc, 0xcc, 0x00},
    {0x00, 0x00, 0x78, 0xcc, 0xcc, 0xcc, 0x78, 0x00},
    {0x00, 0x00, 0xdc, 0x66, 0x66, 0x7c, 0x60, 0xf0},
    {0x00, 0x00, 0x76, 0xcc, 0xcc, 0x7c, 0x0c, 0x1e},
    {0x00, 0x00, 0xdc, 0x76, 0x66, 0x60, 0xf0, 0x00},
    {0x00, 0x00, 0x7c, 0xc0, 0x78, 0x0c, 0xf8, 0x00},
    {0x10, 0x30, 0x7c, 0x30, 0x30, 0x34, 0x18, 0x00},
    {0x00, 0x00, 0xcc, 0xcc, 0xcc, 0xcc, 0x76, 0x00},
    {0x00, 0x00, 0xcc, 0xcc, 0xcc, 0x78, 0x30, 0x00},
    {0x00, 0x00, 0xc6, 0xd6, 0xfe, 0xfe, 0x6c, 0x00},
    {0x00, 0x00, 0xc6, 0x6c, 0x38, 0x6c, 0xc6, 0x00},
    {0x00, 0x00, 0xcc, 0xcc, 0xcc, 0x7c, 0x0c, 0xf8},
    {0x00, 0x00, 0xfc, 0x98, 0x30, 0x64, 0xfc, 0x00},
    {0x1c, 0x30, 0x30, 0xe0, 0x30, 0x30, 0x1c, 0x00},
    {0x18, 0x18, 0x18, 0x00, 0x18, 0x18, 0x18, 0x00},
    {0xe0, 0x30, 0x30, 0x1c, 0x30, 0x30, 0xe0, 0x00},
    {0x76, 0xdc, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
    {0x00, 0x10, 0x38, 0x6c, 0xc6, 0xc6, 0xfe, 0x00},
    {0x78, 0xcc, 0xc0, 0xcc, 0x78, 0x18, 0x0c, 0x78},
    {0x00, 0xcc, 0x00, 0xcc, 0xcc, 0xcc, 0x7e, 0x00},
    {0x1c, 0x00, 0x78, 0xcc, 0xfc, 0xc0, 0x78, 0x00},
    {0x7e, 0xc3, 0x3c, 0x06, 0x3e, 0x66, 0x3f, 0x00},
    {0xcc, 0x00, 0x78, 0x0c, 0x7c, 0xcc, 0x7e, 0x00},
    {0xe0, 0x00, 0x78, 0x0c, 0x7c, 0xcc, 0x7e, 0x00},
    {0x30, 0x30, 0x78, 0x0c, 0x7c, 0xcc, 0x7e, 0x00},
    {0x00, 0x00, 0x78, 0xc0, 0xc0, 0x78, 0x0c, 0x38},
    {0x7e, 0xc3, 0x3c, 0x66, 0x7e, 0x60, 0x3c, 0x00},
    {0xcc, 0x00, 0x78, 0xcc, 0xfc, 0xc0, 0x78, 0x00},
    {0xe0, 0x00, 0x78, 0xcc, 0xfc, 0xc0, 0x78, 0x00},
    {0xcc, 0x00, 0x70, 0x30, 0x30, 0x30, 0x78, 0x00},
    {0x7c, 0xc6, 0x38, 0x18, 0x18, 0x18, 0x3c, 0x00},
    {0xe0, 0x00, 0x70, 0x30, 0x30, 0x30, 0x78, 0x00},
    {0xc6, 0x38, 0x6c, 0xc6, 0xfe, 0xc6, 0xc6, 0x00},
    {0x30, 0x30, 0x00, 0x78, 0xcc, 0xfc, 0xcc, 0x00},
    {0x1c, 0x00, 0xfc, 0x60, 0x78, 0x60, 0xfc, 0x00},
    {0x00, 0x00, 0x7f, 0x0c, 0x7f, 0xcc, 0x7f, 0x00},
    {0x3e, 0x6c, 0xcc, 0xfe, 0xcc, 0xcc, 0xce, 0x00},
    {0x78, 0xcc, 0x00, 0x78, 0xcc, 0xcc, 0x78, 0x00},
    {0x00, 0xcc, 0x00, 0x78, 0xcc, 0xcc, 0x78, 0x00},
    {0x00, 0xe0, 0x00, 0x78, 0xcc, 0xcc, 0x78, 0x00},
    {0x78, 0xcc, 0x00, 0xcc, 0xcc, 0xcc, 0x7e, 0x00},
    {0x00, 0xe0, 0x00, 0xcc, 0xcc, 0xcc, 0x7e, 0x00},
    {0x00, 0xcc, 0x00, 0xcc, 0xcc, 0x7c, 0x0c, 0xf8},
    {0xc3, 0x18, 0x3c, 0x66, 0x66, 0x3c, 0x18, 0x00},
    {0xcc, 0x00, 0xcc, 0xcc, 0xcc, 0xcc, 0x78, 0x00},
    {0x18, 0x18, 0x7e, 0xc0, 0xc0, 0x7e, 0x18, 0x18},
    {0x38, 0x6c, 0x64, 0xf0, 0x60, 0xe6, 0xfc, 0x00},
    {0xcc, 0xcc, 0x78, 0xfc, 0x30, 0xfc, 0x30, 0x30},
    {0xf8, 0xcc, 0xcc, 0xfa, 0xc6, 0xcf, 0xc6, 0xc7},
    {0x0e, 0x1b, 0x18, 0x3c, 0x18, 0x18, 0xd8, 0x70},
    {0x1c, 0x00, 0x78, 0x0c, 0x7c, 0xcc, 0x7e, 0x00},
    {0x38, 0x00, 0x70, 0x30, 0x30, 0x30, 0x78, 0x00},
    {0x00, 0x1c, 0x00, 0x78, 0xcc, 0xcc, 0x78, 0x00},
    {0x00, 0x1c, 0x00, 0xcc, 0xcc, 0xcc, 0x7e, 0x00},
    {0x00, 0xf8, 0x00, 0xf8, 0xcc, 0xcc, 0xcc, 0x00},
    {0xfc, 0x00, 0xcc, 0xec, 0xfc, 0xdc, 0xcc, 0x00},
    {0x3c, 0x6c, 0x6c, 0x3e, 0x00, 0x7e, 0x00, 0x00},
    {0x38, 0x6c, 0x6c, 0x38, 0x00, 0x7c, 0x00, 0x00},
    {0x30, 0x00, 0x30, 0x60, 0xc0, 0xcc, 0x78, 0x00},
    {0x00, 0x00, 0x00, 0xfc, 0xc0, 0xc0, 0x00, 0x00},
    {0x00, 0x00, 0x00, 0xfc, 0x0c, 0x0c, 0x00, 0x00},
    {0xc3, 0xc6, 0xcc, 0xde, 0x33, 0x66, 0xcc, 0x0f},
    {0xc3, 0xc6, 0xcc, 0xdb, 0x37, 0x6f, 0xcf, 0x03},
    {0x18, 0x18, 0x00, 0x18, 0x18, 0x18, 0x18, 0x00},
    {0x00, 0x33, 0x66, 0xcc, 0x66, 0x33, 0x00, 0x00},
    {0x00, 0xcc, 0x66, 0x33, 0x66, 0xcc, 0x00, 0x00},
    {0x22, 0x88, 0x22, 0x88, 0x22, 0x88, 0x22, 0x88},
    {0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa},
    {0xdb, 0x77, 0xdb, 0xee, 0xdb, 0x77, 0xdb, 0xee},
    {0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18},
    {0x18, 0x18, 0x18, 0x18, 0xf8, 0x18, 0x18, 0x18},
    {0x18, 0x18, 0xf8, 0x18, 0xf8, 0x18, 0x18, 0x18},
    {0x36, 0x36, 0x36, 0x36, 0xf6, 0x36, 0x36, 0x36},
    {0x00, 0x00, 0x00, 0x00, 0xfe, 0x36, 0x36, 0x36},
    {0x00, 0x00, 0xf8, 0x18, 0xf8, 0x18, 0x18, 0x18},
    {0x36, 0x36, 0xf6, 0x06, 0xf6, 0x36, 0x36, 0x36},
    {0x36, 0x36, 0x36, 0x36, 0x36, 0x36, 0x36, 0x36},
    {0x00, 0x00, 0xfe, 0x06, 0xf6, 0x36, 0x36, 0x36},
    {0x36, 0x36, 0xf6, 0x06, 0xfe, 0x00, 0x00, 0x00},
    {0x36, 0x36, 0x36, 0x36, 0xfe, 0x00, 0x00, 0x00},
    {0x18, 0x18, 0xf8, 0x18, 0xf8, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0x00, 0x00, 0xf8, 0x18, 0x18, 0x18},
    {0x18, 0x18, 0x18, 0x18, 0x1f, 0x00, 0x00, 0x00},
    {0x18, 0x18, 0x18, 0x18, 0xff, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0x00, 0x00, 0xff, 0x18, 0x18, 0x18},
    {0x18, 0x18, 0x18, 0x18, 0x1f, 0x18, 0x18, 0x18},
    {0x00, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00},
    {0x18, 0x18, 0x18, 0x18, 0xff, 0x18, 0x18, 0x18},
    {0x18, 0x18, 0x1f, 0x18, 0x1f, 0x18, 0x18, 0x18},
    {0x36, 0x36, 0x36, 0x36, 0x37, 0x36, 0x36, 0x36},
    {0x36, 0x36, 0x37, 0x30, 0x3f, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0x3f, 0x30, 0x37, 0x36, 0x36, 0x36},
    {0x36, 0x36, 0xf7, 0x00, 0xff, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0xff, 0x00, 0xf7, 0x36, 0x36, 0x36},
    {0x36, 0x36, 0x37, 0x30, 0x37, 0x36, 0x36, 0x36},
    {0x00, 0x00, 0xff, 0x00, 0xff, 0x00, 0x00, 0x00},
    {0x36, 0x36, 0xf7, 0x00, 0xf7, 0x36, 0x36, 0x36},
    {0x18, 0x18, 0xff, 0x00, 0xff, 0x00, 0x00, 0x00},
    {0x36, 0x36, 0x36, 0x36, 0xff, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0xff, 0x00, 0xff, 0x18, 0x18, 0x18},
    {0x00, 0x00, 0x00, 0x00, 0xff, 0x36, 0x36, 0x36},
    {0x36, 0x36, 0x36, 0x36, 0x3f, 0x00, 0x00, 0x00},
    {0x18, 0x18, 0x1f, 0x18, 0x1f, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0x1f, 0x18, 0x1f, 0x18, 0x18, 0x18},
    {0x00, 0x00, 0x00, 0x00, 0x3f, 0x36, 0x36, 0x36},
    {0x36, 0x36, 0x36, 0x36, 0xff, 0x36, 0x36, 0x36},
    {0x18, 0x18, 0xff, 0x18, 0xff, 0x18, 0x18, 0x18},
    {0x18, 0x18, 0x18, 0x18, 0xf8, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0x00, 0x00, 0x1f, 0x18, 0x18, 0x18},
    {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff},
    {0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff},
    {0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0},
    {0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f},
    {0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0x76, 0xdc, 0xc8, 0xdc, 0x76, 0x00},
    {0x00, 0x78, 0xcc, 0xf8, 0xcc, 0xf8, 0xc0, 0xc0},
    {0x00, 0xfc, 0xcc, 0xc0, 0xc0, 0xc0, 0xc0, 0x00},
    {0x00, 0xfe, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x00},
    {0xfc, 0xcc, 0x60, 0x30, 0x60, 0xcc, 0xfc, 0x00},
    {0x00, 0x00, 0x7e, 0xd8, 0xd8, 0xd8, 0x70, 0x00},
    {0x00, 0x66, 0x66, 0x66, 0x66, 0x7c, 0x60, 0xc0},
    {0x00, 0x76, 0xdc, 0x18, 0x18, 0x18, 0x18, 0x00},
    {0xfc, 0x30, 0x78, 0xcc, 0xcc, 0x78, 0x30, 0xfc},
    {0x38, 0x6c, 0xc6, 0xfe, 0xc6, 0x6c, 0x38, 0x00},
    {0x38, 0x6c, 0xc6, 0xc6, 0x6c, 0x6c, 0xee, 0x00},
    {0x1c, 0x30, 0x18, 0x7c, 0xcc, 0xcc, 0x78, 0x00},
    {0x00, 0x00, 0x7e, 0xdb, 0xdb, 0x7e, 0x00, 0x00},
    {0x06, 0x0c, 0x7e, 0xdb, 0xdb, 0x7e, 0x60, 0xc0},
    {0x38, 0x60, 0xc0, 0xf8, 0xc0, 0x60, 0x38, 0x00},
    {0x78, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0x00},
    {0x00, 0xfc, 0x00, 0xfc, 0x00, 0xfc, 0x00, 0x00},
    {0x30, 0x30, 0xfc, 0x30, 0x30, 0x00, 0xfc, 0x00},
    {0x60, 0x30, 0x18, 0x30, 0x60, 0x00, 0xfc, 0x00},
    {0x18, 0x30, 0x60, 0x30, 0x18, 0x00, 0xfc, 0x00},
    {0x0e, 0x1b, 0x1b, 0x18, 0x18, 0x18, 0x18, 0x18},
    {0x18, 0x18, 0x18, 0x18, 0x18, 0xd8, 0xd8, 0x70},
    {0x30, 0x30, 0x00, 0xfc, 0x00, 0x30, 0x30, 0x00},
    {0x00, 0x76, 0xdc, 0x00, 0x76, 0xdc, 0x00, 0x00},
    {0x38, 0x6c, 0x6c, 0x38, 0x00, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00},
    {0x0f, 0x0c, 0x0c, 0x0c, 0xec, 0x6c, 0x3c, 0x1c},
    {0x78, 0x6c, 0x6c, 0x6c, 0x6c, 0x00, 0x00, 0x00},
    {0x70, 0x18, 0x30, 0x60, 0x78, 0x00, 0x00, 0x00},
    {0x00, 0x00, 0x3c, 0x3c, 0x3c, 0x3c, 0x00, 0x00},
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
};

//
// Standard definition of EIA-189-A color bars.  The actual color definitions
// are either in CRGB24Synthesizer or CYUVSynthesizer.
//
const COLOR g_ColorBars[] = 
    {WHITE, YELLOW, CYAN, GREEN, MAGENTA, RED, BLUE, BLACK};

const UCHAR CRGB24Synthesizer::Colors [MAX_COLOR][3] = {
    {0, 0, 0},          // BLACK
    {255, 255, 255},    // WHITE
    {0, 255, 255},      // YELLOW
    {255, 255, 0},      // CYAN
    {0, 255, 0},        // GREEN
    {255, 0, 255},      // MAGENTA
    {0, 0, 255},        // RED
    {255, 0, 0},        // BLUE
    {128, 128, 128}     // GREY
};

const UCHAR CYUVSynthesizer::Colors [MAX_COLOR][3] = {
    {128, 16, 128},     // BLACK
    {128, 235, 128},    // WHITE
    {16, 211, 146},     // YELLOW
    {166, 170, 16},     // CYAN
    {54, 145, 34},      // GREEN
    {202, 106, 222},    // MAGENTA
    {90, 81, 240},      // RED
    {240, 41, 109},     // BLUE
    {128, 125, 128},    // GREY
};

/**************************************************************************

    LOCKED CODE

**************************************************************************/

#ifdef ALLOC_PRAGMA
#pragma code_seg()
#endif // ALLOC_PRAGMA


void
CImageSynthesizer::
SynthesizeBars (
    )

/*++

Routine Description:

    Synthesize EIA-189-A standard color bars onto the Image.  The image
    in question is the current synthesis buffer.

Arguments:

    None

Return Value:

    None

--*/

{
    const COLOR *CurColor = g_ColorBars;
    ULONG ColorCount = SIZEOF_ARRAY (g_ColorBars);

    //
    // Set the default cursor...
    //
    GetImageLocation (0, 0);

    //
    // Synthesize a single line.
    //
    PUCHAR ImageStart = m_Cursor;
    for (ULONG x = 0; x < m_Width; x++) 
        PutPixel (g_ColorBars [((x * ColorCount) / m_Width)]);

    PUCHAR ImageEnd = m_Cursor;
    
    //
    // Copy the synthesized line to all subsequent lines.
    //
    for (ULONG line = 1; line < m_Height; line++) {

        GetImageLocation (0, line);

        RtlCopyMemory (
            m_Cursor,
            ImageStart,
            ImageEnd - ImageStart
            );
    }
}

/*************************************************/


void 
CImageSynthesizer::
OverlayText (
    _In_ ULONG LocX,
    _In_ ULONG LocY,
    _In_ ULONG Scaling,
    _In_ LPSTR Text,
    _In_ COLOR BgColor,
    _In_ COLOR FgColor
    )

/*++

Routine Description:

    Overlay text onto the synthesized image.  Clip to fit the image
    if the overlay does not fit.  The image buffer used is the set
    synthesis buffer.

Arguments:

    LocX -
        The X location on the image to begin the overlay.  This MUST
        be inside the image.  POSITION_CENTER may be used to indicate
        horizontal centering.

    LocY -
        The Y location on the image to begin the overlay.  This MUST
        be inside the image.  POSITION_CENTER may be used to indicate
        vertical centering.

    Scaling -
        Normally, the overlay is done in 8x8 font.  A scaling of
        2 indicates 16x16, 3 indicates 24x24 and so forth.

    Text -
        A character string containing the information to overlay

    BgColor -
        The background color of the overlay window.  For transparency,
        indicate TRANSPARENT here.

    FgColor -
        The foreground color for the text overlay.

Return Value:

    None

--*/

{

    NT_ASSERT ((LocX <= m_Width || LocX == POSITION_CENTER) &&
            (LocY <= m_Height || LocY == POSITION_CENTER));

    ULONG StrLen = 0;
    CHAR* CurChar;

    //
    // Determine the character length of the string.
    //
    for (CurChar = Text; CurChar && *CurChar; CurChar++)
        StrLen++;

    //
    // Determine the physical size of the string plus border.  There is
    // a definable NO_CHARACTER_SEPARATION.  If this is defined, there will
    // be no added space between font characters.  Otherwise, one empty pixel
    // column is added between characters.
    //
    #ifndef NO_CHARACTER_SEPARATION
        ULONG LenX = (StrLen * (Scaling << 3)) + 1 + StrLen;
    #else // NO_CHARACTER_SEPARATION
        ULONG LenX = (StrLen * (Scaling << 3)) + 2;
    #endif // NO_CHARACTER_SEPARATION

    ULONG LenY = 2 + (Scaling << 3);

    //
    // Adjust for center overlays.
    //
    // NOTE: If the overlay doesn't fit into the synthesis buffer, this
    // merely left aligns the overlay and clips off the right side.
    //
    if (LocX == POSITION_CENTER) {
        if (LenX >= m_Width) {
            LocX = 0;
        } else {
            LocX = (m_Width >> 1) - (LenX >> 1);
        }
    }

    if (LocY == POSITION_CENTER) {
        if (LenY >= m_Height) {
            LocY = 0;
        } else {
            LocY = (m_Height >> 1) - (LenY >> 1);
        }
    }

    //
    // Determine the amount of space available on the synthesis buffer.
    // We will clip anything that finds itself outside the synthesis buffer.
    //
    ULONG SpaceX = m_Width - LocX;
    ULONG SpaceY = m_Height - LocY;

    //
    // Set the default cursor position.
    //
    GetImageLocation (LocX, LocY);

    //
    // Overlay a background color row.
    //
    if (BgColor != TRANSPARENT && SpaceY) {
        for (ULONG x = 0; x < LenX && x < SpaceX; x++) {
            PutPixel (BgColor);
        }
    }
    LocY++;
    if (SpaceY) SpaceY--;

    //
    // Loop across each row of the image.
    //
    for (ULONG row = 0; row < 8 && SpaceY; row++) {
        //
        // Generate a line.
        //
        GetImageLocation (LocX, LocY++);

        PUCHAR ImageStart = m_Cursor;

        ULONG CurSpaceX = SpaceX;
        if (CurSpaceX) {
            PutPixel (BgColor);
            CurSpaceX--;
        }

        //
        // Generate the row'th row of the overlay.
        //
        CurChar = Text;
        while (CurChar && *CurChar) {
            
            UCHAR CharBase = g_FontData [*CurChar++][row];
            for (ULONG mask = 0x80; mask && CurSpaceX; mask >>= 1) {
                for (ULONG scale = 0; scale < Scaling && CurSpaceX; scale++) {
                    if (CharBase & mask) {
                        PutPixel (FgColor);
                    } else {
                        PutPixel (BgColor);
                    }
                    CurSpaceX--;
                }
            }

            // 
            // Separate each character by one space.  Account for the border
            // space at the end by placing the separator after the last 
            // character also.
            //
            #ifndef NO_CHARACTER_SEPARATION
                if (CurSpaceX) {
                    PutPixel (BgColor);
                    CurSpaceX--;
                }
            #endif // NO_CHARACTER_SEPARATION

        }

        //
        // If there is no separation character defined, account for the
        // border.
        // 
        #ifdef NO_CHARACTER_SEPARATION
            if (CurSpaceX) {
                PutPixel (BgColor);
                CurSpaceX--;
            }
        #endif // NO_CHARACTER_SEPARATION
            

        PUCHAR ImageEnd = m_Cursor;
        //
        // Copy the line downward scale times.
        //
        for (ULONG scale = 1; scale < Scaling && SpaceY; scale++) {
            GetImageLocation (LocX, LocY++);
            RtlCopyMemory (m_Cursor, ImageStart, ImageEnd - ImageStart);
            SpaceY--;
        }

    }

    //
    // Add the bottom section of the overlay.
    //
    GetImageLocation (LocX, LocY);
    if (BgColor != TRANSPARENT && SpaceY) {
        for (ULONG x = 0; x < LenX && x < SpaceX; x++) {
            PutPixel (BgColor);
        }
    }

}


void CImageSynthesizer::CopyBuffer(PVOID data, ULONG dataLength)
{

}