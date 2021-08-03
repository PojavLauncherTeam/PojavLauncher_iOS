#import "CustomControlsUtils.h"
#include "../glfw_keycodes.h"
#include "../utils.h"

#define BTN_RECT 80.0, 30.0
#define BTN_SQUARE 50.0, 50.0

NSMutableDictionary* createButton(NSString* name, int* keycodes, NSString* dynamicX, NSString* dynamicY, CGFloat width, CGFloat height) {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"name"] = name;
    dict[@"keycodes"] = [[NSMutableArray alloc] init];
    for (int i = 0; i < 4; i++) {
        [dict[@"keycodes"] addObject:@(keycodes[i])];
    }
    dict[@"dynamicX"] = dynamicX;
    dict[@"dynamicY"] = dynamicY;
    dict[@"width"] = @(width);
    dict[@"height"] = @(height);
    dict[@"opacity"] = @(100);
    dict[@"cornerRadius"] = @(0);
    dict[@"bgColor"] = @(convertUIColor2ARGB([UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]));
    return dict;
}

UIColor* convertARGB2UIColor(int argb) {
    return [UIColor 
        colorWithRed:((argb>>16)&0xFF)/255.0
               green:((argb>>8)&0xFF)/255.0
                blue:((argb>>0)&0xFF)/255.0
               alpha:((argb>>24)&0xFF)/255.0];
}

int convertUIColor2ARGB(UIColor* color) {
    const CGFloat *rgba = CGColorGetComponents(color.CGColor);
    int a = (int) (rgba[3] * 255);
    int r = (int) (rgba[0] * 255);
    int g = (int) (rgba[1] * 255);
    int b = (int) (rgba[2] * 255);
    return (a << 24)|
           (r << 16)|
           (g << 8) |
           (b << 0);
}

void convertV1ToV2(NSMutableDictionary* dict) {
    dict[@"opacity"] = @(100 - ((NSNumber *)dict[@"transparency"]).intValue);
}

void generateAndSaveDefaultControl() {
    // Generate a V2 control
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"version"] = @(2);
    dict[@"scaledAt"] = @(100);
    dict[@"mControlDataList"] = [[NSMutableArray alloc] init];
    [dict[@"mControlDataList"] addObject:createButton(@"Keyboard",
        (int[]){SPECIALBTN_KEYBOARD,0,0,0},
        @"${margin} * 3 + ${width} * 2",
        @"${margin}",
        BTN_RECT
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"GUI",
        (int[]){SPECIALBTN_TOGGLECTRL,0,0,0},
        @"${margin}",
        @"${bottom} - ${margin}",
        BTN_SQUARE
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"PRI",
        (int[]){SPECIALBTN_MOUSEPRI,0,0,0},
        @"${margin}",
        @"${screen_height} - ${margin} * 3 - ${height} * 3",
        BTN_SQUARE
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"SEC",
        (int[]){SPECIALBTN_MOUSESEC,0,0,0},
        @"${margin} * 3 + ${width} * 2",
        @"${screen_height} - ${margin} * 3 - ${height} * 3",
        BTN_SQUARE
    )];
/* // TODO: virtual mouse
    [dict[@"mControlDataList"] addObject:createButton(@"Mouse",
        (int[]){SPECIALBTN_VIRTUALMOUSE,0,0,0},
        @"${right}",
        @"${margin}",
        BTN_RECT
    )];
*/
    [dict[@"mControlDataList"] addObject:createButton(@"Debug",
        (int[]){GLFW_KEY_F3,0,0,0},
        @"${margin}",
        @"${margin}",
        BTN_RECT
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"Chat",
        (int[]){GLFW_KEY_T,0,0,0},
        @"${margin} * 2 + ${width}",
        @"${margin}",
        BTN_RECT
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"Tab",
        (int[]){GLFW_KEY_TAB,0,0,0},
        @"${margin} * 4 + ${width} * 3",
        @"${margin}",
        BTN_RECT
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"Opti-Zoom",
        (int[]){GLFW_KEY_C,0,0,0},
        @"${margin} * 5 + ${width} * 4",
        @"${margin}",
        BTN_RECT
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"Offhand",
        (int[]){GLFW_KEY_F,0,0,0},
        @"${margin} * 6 + ${width} * 5",
        @"${margin}",
        BTN_RECT
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"3rd",
        (int[]){GLFW_KEY_F5,0,0,0},
        @"${margin}",
        @"${margin} * 2 + ${height}",
        BTN_RECT
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"▲",
        (int[]){GLFW_KEY_W,0,0,0},
        @"${margin} * 2 + ${width}",
        @"${bottom} - ${margin} * 3 - ${height} * 2",
        BTN_SQUARE
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"◀",
        (int[]){GLFW_KEY_A,0,0,0},
        @"${margin}",
        @"${bottom} - ${margin} * 2 - ${height}",
        BTN_SQUARE
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"▼",
        (int[]){GLFW_KEY_S,0,0,0},
        @"${margin} * 2 + ${width}",
        @"${bottom} - ${margin}",
        BTN_SQUARE
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"▶",
        (int[]){GLFW_KEY_D,0,0,0},
        @"${margin} * 3 + ${width} * 2",
        @"${bottom} - ${margin} * 2 - ${height}",
        BTN_SQUARE
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"Inv",
        (int[]){GLFW_KEY_E,0,0,0},
        @"${margin} * 3 + ${width} * 2",
        @"${bottom} - ${margin}",
        BTN_SQUARE
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"◇",
        (int[]){GLFW_KEY_LEFT_SHIFT,0,0,0},
        @"${margin} * 2 + ${width}",
        @"${screen_height} - ${margin} * 2 - ${height} * 2",
        BTN_SQUARE
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"⬛",
        (int[]){GLFW_KEY_SPACE,0,0,0},
        @"${right} - ${margin} * 2 - ${width}",
        @"${bottom} - ${margin} * 2 - ${height}",
        BTN_SQUARE
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"Esc",
        (int[]){GLFW_KEY_ESCAPE,0,0,0},
        @"${right} - ${margin}",
        @"${bottom} - ${margin}",
        BTN_RECT
    )];
    // Additional button for old versions that don't enter fullscreen automatically
    [dict[@"mControlDataList"] addObject:createButton(@"Fullscreen",
        (int[]){GLFW_KEY_F11,0,0,0},
        @"${right} - ${margin}",
        @"${bottom} - ${margin} * 2 - ${height}",
        BTN_RECT
    )];
    NSOutputStream *os = [[NSOutputStream alloc] initToFileAtPath:
        [@(getenv("POJAV_PATH_CONTROL")) stringByAppendingString:@"/default.json"] append:NO];
    [os open];
    [NSJSONSerialization writeJSONObject:dict toStream:os options:NSJSONWritingPrettyPrinted error:nil];
    [os close];

/*
    [dict[@"mControlDataList"] addObject:createButton(@"NAME",
        {SPECIALBTN_KEYBOARD,0,0,0},
        @"DYNAMICX",
        @"DYNAMICY",
        WIDTHHEIGHT
    )];
*/
}
