#import "ControlDrawer.h"
#import "ControlSubButton.h"
#import "CustomControlsUtils.h"
#import "../LauncherPreferences.h"
#import "../ios_uikit_bridge.h"
#include "../glfw_keycodes.h"
#include "../utils.h"

NSMutableDictionary* createButton(NSString* name, int* keycodes, NSString* dynamicX, NSString* dynamicY, CGFloat width, CGFloat height) {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"name"] = name;
    dict[@"keycodes"] = [[NSMutableArray alloc] initWithCapacity:4];
    for (int i = 0; i < 4; i++) {
        [dict[@"keycodes"] addObject:@(keycodes[i])];
    }
    dict[@"dynamicX"] = dynamicX;
    dict[@"dynamicY"] = dynamicY;
    dict[@"width"] = @(width);
    dict[@"height"] = @(height);
    dict[@"opacity"] = @(1);
    dict[@"cornerRadius"] = @(0);
    dict[@"bgColor"] = @(0x4d000000);
    return dict;
}

NSMutableDictionary* createGamepadButton(NSString* name, int gamepad_button, int keycode) {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"name"] = name;
    dict[@"gamepad_button"] = @(gamepad_button);
    dict[@"keycode"] = @(keycode);
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
    return (a << 24) | (r << 16) | (g << 8) | (b << 0);
}

int convertUIColor2RGB(UIColor* color) {
    const CGFloat *rgb = CGColorGetComponents(color.CGColor);
    int r = (int) (rgb[0] * 255);
    int g = (int) (rgb[1] * 255);
    int b = (int) (rgb[2] * 255);
    return (0xFF << 24) | (r << 16) | (g << 8) | (b << 0);
}

void convertV2Layout(NSMutableDictionary* dict) {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;

    // width: offset the notch parts
    CGFloat screenWidth = (screenBounds.size.width - insets.left - insets.right) * screenScale;

    for (NSMutableDictionary *button in (NSMutableArray *)dict[@"mControlDataList"]) {
        if (![button[@"isDynamicBtn"] boolValue]) {
            button[@"dynamicX"] = [NSString stringWithFormat:@"%f * ${screen_width}", [button[@"x"] floatValue] / screenWidth];
            button[@"dynamicY"] = [NSString stringWithFormat:@"%f * ${screen_height}", [button[@"y"] floatValue] / screenBounds.size.height];
            [button removeObjectForKey:@"x"];
            [button removeObjectForKey:@"y"];
        }
    }
    for (NSMutableDictionary *button in (NSMutableArray *)dict[@"mDrawerDataList"]) {
        NSMutableDictionary *buttonProp = button[@"properties"];
        if (![buttonProp[@"isDynamicBtn"] boolValue]) {
            buttonProp[@"dynamicX"] = [NSString stringWithFormat:@"%f * ${screen_width}", [buttonProp[@"x"] floatValue] / screenWidth];
            buttonProp[@"dynamicY"] = [NSString stringWithFormat:@"%f * ${screen_height}", [buttonProp[@"y"] floatValue] / screenBounds.size.height];
            [buttonProp removeObjectForKey:@"x"];
            [buttonProp removeObjectForKey:@"y"];
        }
    }

    dict[@"version"] = @(4);
}

void convertV1Layout(NSMutableDictionary* dict) {
    for (NSMutableDictionary *btnDict in (NSMutableArray *)dict[@"mControlDataList"]) {
        NSMutableArray *keycodes = [NSMutableArray arrayWithCapacity:4];
        CGFloat scale = [dict[@"scaledAt"] floatValue];

        // default values
        btnDict[@"bgColor"] = @(0x4d000000);
        btnDict[@"strokeWidth"] = @(0);

        // opacity -> reverse transparency
        btnDict[@"opacity"] = @((100.0 - [btnDict[@"transparency"] intValue]) / 100.0);
        [btnDict removeObjectForKey:@"transparency"];

        // pixel of width, height -> dp
        btnDict[@"width"] = @([btnDict[@"width"] floatValue] / scale * 50.0);
        btnDict[@"height"] = @([btnDict[@"height"] floatValue] / scale * 50.0);

        // isRound -> cornerRadius 35%
        if ([btnDict[@"isRound"] boolValue] == YES) {
            btnDict[@"cornerRadius"] = @(35.0f);
        }
        [btnDict removeObjectForKey:@"isRound"];

        // keycode -> keycodes[0]
        [keycodes addObject:btnDict[@"keycode"]];
        [btnDict removeObjectForKey:@"keycode"];

        // alt -> keycodes[i++]
        if ([dict[@"holdAlt"] boolValue] == YES) {
            [keycodes addObject:@(GLFW_KEY_LEFT_ALT)];
        }
        [btnDict removeObjectForKey:@"holdAlt"];

        // ctrl -> keycodes[i++]
        if ([dict[@"holdCtrl"] boolValue] == YES) {
            [keycodes addObject:@(GLFW_KEY_LEFT_CONTROL)];
        }
        [btnDict removeObjectForKey:@"holdCtrl"];

        // shift -> keycodes[i++]
        if ([dict[@"holdShift"] boolValue] == YES) {
            [keycodes addObject:@(GLFW_KEY_LEFT_SHIFT)];
        }
        [btnDict removeObjectForKey:@"holdShift"];

        // set final keycode array
        btnDict[@"keycodes"] = keycodes;

        btnDict[@"mDrawerDataList"] = [[NSMutableArray alloc] init];
    }

    dict[@"scaledAt"] = @(100);
    dict[@"version"] = @(2);

    convertV2Layout(dict);
}

BOOL convertLayoutIfNecessary(NSMutableDictionary* dict) {
    int version = [dict[@"version"] intValue];
    switch (version) {
        case 0:
        case 1:
            convertV1Layout(dict);
            break;
        case 2:
            convertV2Layout(dict);
            break;
        case 3:
        case 4:
            break;
        default:
            showDialog(currentVC(), localize(@"custom_controls.control_menu.save.error.json", nil), [NSString stringWithFormat:localize(@"custom_controls.error.imcompatible", nil), version]);
            return NO;
    }
    return YES;
}

void generateAndSaveDefaultControl() {
    NSString *defaultPath = [NSString stringWithFormat:@"%s/controlmap/default.json", getenv("POJAV_HOME")];
    if ([NSFileManager.defaultManager fileExistsAtPath:defaultPath]) {
        return;
    }

    // Generate a v2.4 control
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"version"] = @(4);
    dict[@"scaledAt"] = @(100);
    dict[@"mControlDataList"] = [[NSMutableArray alloc] init];
    dict[@"mDrawerDataList"] = [[NSMutableArray alloc] init];
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
    [dict[@"mControlDataList"] addObject:createButton(@"Mouse",
        (int[]){SPECIALBTN_VIRTUALMOUSE,0,0,0},
        @"${right} - ${margin}",
        @"${margin}",
        BTN_RECT
    )];
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
    NSOutputStream *os = [[NSOutputStream alloc] initToFileAtPath:defaultPath append:NO];
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

void generateAndSaveDefaultControlForGamepad() {
    NSString *gamepadPath = [NSString stringWithFormat:@"%s/controlmap/gamepads/default.json", getenv("POJAV_HOME")];
    if ([NSFileManager.defaultManager fileExistsAtPath:gamepadPath]) {
        return;
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"version"] = @(1);
    
    dict[@"mGameMappingList"] = [[NSMutableArray alloc] init];
    
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"bumper_left", GLFW_GAMEPAD_BUTTON_LEFT_BUMPER, SPECIALBTN_SCROLLUP)];
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"bumper_right", GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER, SPECIALBTN_SCROLLDOWN)];
    
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"trigger_left", GLFW_GAMEPAD_BUTTON_LEFT_TRIGGER, SPECIALBTN_MOUSESEC)];
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"trigger_right", GLFW_GAMEPAD_BUTTON_RIGHT_TRIGGER, SPECIALBTN_MOUSEPRI)];
    
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"named_back", GLFW_GAMEPAD_BUTTON_BACK, GLFW_KEY_TAB)];
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"named_start", GLFW_GAMEPAD_BUTTON_START, GLFW_KEY_ESCAPE)];
    
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"named_a", GLFW_GAMEPAD_BUTTON_A, GLFW_KEY_SPACE)];
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"named_b", GLFW_GAMEPAD_BUTTON_B, GLFW_KEY_Q)];
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"named_x", GLFW_GAMEPAD_BUTTON_X, GLFW_KEY_E)];
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"named_y", GLFW_GAMEPAD_BUTTON_Y, GLFW_KEY_F)];
    
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"dpad_up", GLFW_GAMEPAD_BUTTON_DPAD_UP, GLFW_KEY_LEFT_SHIFT)];
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"dpad_down", GLFW_GAMEPAD_BUTTON_DPAD_DOWN, GLFW_KEY_O)];
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"dpad_left", GLFW_GAMEPAD_BUTTON_DPAD_LEFT, GLFW_KEY_J)];
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"dpad_right", GLFW_GAMEPAD_BUTTON_DPAD_RIGHT, GLFW_KEY_K)];
    
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"thumb_left", GLFW_GAMEPAD_BUTTON_LEFT_THUMB, GLFW_KEY_LEFT_CONTROL)];
    [dict[@"mGameMappingList"] addObject:createGamepadButton(@"thumb_right", GLFW_GAMEPAD_BUTTON_RIGHT_THUMB, GLFW_KEY_LEFT_SHIFT)];
    
    dict[@"mMenuMappingList"] = [[NSMutableArray alloc] init];
    
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"bumper_left", GLFW_GAMEPAD_BUTTON_LEFT_BUMPER, SPECIALBTN_SCROLLUP)];
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"bumper_right", GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER, SPECIALBTN_SCROLLDOWN)];
    
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"trigger_left", GLFW_GAMEPAD_BUTTON_LEFT_TRIGGER, GLFW_KEY_UNKNOWN)];
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"trigger_right", GLFW_GAMEPAD_BUTTON_RIGHT_TRIGGER, GLFW_KEY_UNKNOWN)];
    
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"named_back", GLFW_GAMEPAD_BUTTON_BACK, GLFW_KEY_UNKNOWN)];
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"named_start", GLFW_GAMEPAD_BUTTON_START, GLFW_KEY_UNKNOWN)];
    
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"named_a", GLFW_GAMEPAD_BUTTON_A, SPECIALBTN_MOUSEPRI)];
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"named_b", GLFW_GAMEPAD_BUTTON_B, GLFW_KEY_ESCAPE)];
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"named_x", GLFW_GAMEPAD_BUTTON_X, SPECIALBTN_MOUSESEC)];
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"named_y", GLFW_GAMEPAD_BUTTON_Y, GLFW_KEY_LEFT_SHIFT)];
    
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"dpad_up", GLFW_GAMEPAD_BUTTON_DPAD_UP, GLFW_KEY_UNKNOWN)];
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"dpad_down", GLFW_GAMEPAD_BUTTON_DPAD_DOWN, GLFW_KEY_O)];
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"dpad_left", GLFW_GAMEPAD_BUTTON_DPAD_LEFT, GLFW_KEY_J)];
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"dpad_right", GLFW_GAMEPAD_BUTTON_DPAD_RIGHT, GLFW_KEY_K)];
    
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"thumb_left", GLFW_GAMEPAD_BUTTON_LEFT_THUMB, GLFW_KEY_UNKNOWN)];
    [dict[@"mMenuMappingList"] addObject:createGamepadButton(@"thumb_right", GLFW_GAMEPAD_BUTTON_RIGHT_THUMB, GLFW_KEY_UNKNOWN)];
    
    NSOutputStream *os = [[NSOutputStream alloc] initToFileAtPath:gamepadPath append:NO];
    [os open];
    [NSJSONSerialization writeJSONObject:dict toStream:os options:NSJSONWritingPrettyPrinted error:nil];
    [os close];
}

void loadControlObject(UIView* targetView, NSMutableDictionary* controlDictionary) {
    NSMutableString *errorString = [[NSMutableString alloc] init];

    if (convertLayoutIfNecessary(controlDictionary)) {
        NSMutableArray *controlDataList = controlDictionary[@"mControlDataList"];
        setPreference(@"internal_current_button_scale", controlDictionary[@"scaledAt"]);
        for (NSMutableDictionary *buttonDict in controlDataList) {
            //APPLY_SCALE(buttonDict[@"strokeWidth"]);
            @try {
                ControlButton *button = [ControlButton buttonWithProperties:buttonDict];
                [targetView addSubview:button];
                [button update];
            } @catch (NSException *exception) {
                [errorString appendFormat:@"%@: %@\n", buttonDict[@"name"], exception.reason];
            }
            //NSLog(@"DBG Added button=%@", button);
        }

        NSMutableArray *drawerDataList = controlDictionary[@"mDrawerDataList"];
        for (NSMutableDictionary *drawerData in drawerDataList) {
            ControlDrawer *drawer;
            @try {
                drawer = [ControlDrawer buttonWithData:drawerData];
            } @catch (NSException *exception) {
                [errorString appendFormat:@"%@: %@\n", drawerData[@"name"], exception.reason];
            }
            if (isControlModifiable) drawer.areButtonsVisible = YES;
            [targetView addSubview:drawer];
            //NSLog(@"DBG Added drawer=%@", drawer);

            for (NSMutableDictionary *subButton in drawerData[@"buttonProperties"]) {
                ControlSubButton *subView = [ControlSubButton buttonWithProperties:subButton];
                [drawer addButton:subView];
                [targetView addSubview:subView];
            }
            [drawer syncButtons];
        }

        controlDictionary[@"scaledAt"] = @([getPreference(@"button_scale") floatValue]);

        if (errorString.length > 0) {
            showDialog(currentVC(), @"Error processing dynamic position", errorString);
        }
    }
}

void initKeycodeTable(NSMutableArray* keyCodeMap, NSMutableArray* keyValueMap) {
#define GLFW_KEY_NONE 0
#define addkey(key) \
    [keyCodeMap addObject:@(#key)]; \
    [keyValueMap addObject:@(GLFW_KEY_##key)];
#define addspec(key) \
    [keyCodeMap addObject:@(#key)]; \
    [keyValueMap addObject:@(key)];

    addspec(SPECIALBTN_MENU)
    addspec(SPECIALBTN_SCROLLDOWN)
    addspec(SPECIALBTN_SCROLLUP)
    addspec(SPECIALBTN_VIRTUALMOUSE)
    addspec(SPECIALBTN_MOUSEMID)
    addspec(SPECIALBTN_MOUSESEC)
    addspec(SPECIALBTN_MOUSEPRI)
    addspec(SPECIALBTN_TOGGLECTRL)
    addspec(SPECIALBTN_KEYBOARD)

    addkey(NONE)
    addkey(HOME)
    addkey(ESCAPE)

    // 0-9 keys
    addkey(0) addkey(1) addkey(2) addkey(3) addkey(4)
    addkey(5) addkey(6) addkey(7) addkey(8) addkey(9)
    //addkey(POUND)

    // Arrow keys
    addkey(DPAD_UP) addkey(DPAD_DOWN) addkey(DPAD_LEFT) addkey(DPAD_RIGHT)

    // A-Z keys
    addkey(A) addkey(B) addkey(C) addkey(D) addkey(E)
    addkey(F) addkey(G) addkey(H) addkey(I) addkey(J)
    addkey(K) addkey(L) addkey(M) addkey(N) addkey(O)
    addkey(P) addkey(Q) addkey(R) addkey(S) addkey(T)
    addkey(U) addkey(V) addkey(W) addkey(X) addkey(Y)
    addkey(Z)

    addkey(COMMA)
    addkey(PERIOD)

    // Alt keys
    addkey(LEFT_ALT)
    addkey(RIGHT_ALT)

    // Shift keys
    addkey(LEFT_SHIFT)
    addkey(RIGHT_SHIFT)

    addkey(TAB)
    addkey(SPACE)
    addkey(ENTER)
    addkey(BACKSPACE)
    addkey(DELETE)
    addkey(GRAVE_ACCENT)
    addkey(MINUS)
    addkey(EQUAL)
    addkey(LEFT_BRACKET) addkey(RIGHT_BRACKET)
    addkey(BACKSLASH)
    addkey(SEMICOLON)
    addkey(SLASH)
    //addkey(AT) //@

    // Page keys
    addkey(PAGE_UP) addkey(PAGE_DOWN)

    // Control keys
    addkey(LEFT_CONTROL)
    addkey(RIGHT_CONTROL)

    addkey(CAPS_LOCK)
    addkey(PAUSE)
    addkey(INSERT)

    // Fn keys
    addkey(F1) addkey(F2) addkey(F3) addkey(F4)
    addkey(F5) addkey(F6) addkey(F7) addkey(F8)
    addkey(F9) addkey(F10) addkey(F11) addkey(F12)

    // Num keys
    addkey(NUM_LOCK)
    addkey(NUMPAD_0)
    addkey(NUMPAD_1) addkey(NUMPAD_2) addkey(NUMPAD_3)
    addkey(NUMPAD_4) addkey(NUMPAD_5) addkey(NUMPAD_6)
    addkey(NUMPAD_7) addkey(NUMPAD_8) addkey(NUMPAD_9)
    addkey(NUMPAD_DECIMAL)
    addkey(NUMPAD_DIVIDE)
    addkey(NUMPAD_MULTIPLY)
    addkey(NUMPAD_SUBTRACT)
    addkey(NUMPAD_ADD)
    addkey(NUMPAD_ENTER)
    addkey(NUMPAD_EQUAL)

    //addkey(APOSTROPHE)
    //addkey(WORLD_1) addkey(WORLD_2)
    //addkey(END)
    //addkey(SCROLL_LOCK) 
    //addkey(PRINT_SCREEN)
    //addkey(LEFT_SUPER) addkey(RIGHT_ENTER)
    //addkey(MENU)
#undef addkey
}
