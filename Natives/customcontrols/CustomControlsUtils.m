#import "ControlDrawer.h"
#import "ControlSubButton.h"
#import "CustomControlsUtils.h"
#import "../LauncherPreferences.h"
#import "../ios_uikit_bridge.h"
#include "../glfw_keycodes.h"
#include "../utils.h"

#define BTN_RECT 80.0, 30.0
#define BTN_SQUARE 50.0, 50.0

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
    dict[@"isDynamicBtn"] = @(YES);
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
            showDialog(currentVC(), @"Error parsing JSON", [NSString stringWithFormat:@"Incompatible control version code %d. This control version was not implemented in this launcher build.", version]);
            return NO;
    }
    return YES;
}

void generateAndSaveDefaultControl() {
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
    // Additional button for old versions that don't enter fullscreen automatically
    [dict[@"mControlDataList"] addObject:createButton(@"Fullscreen",
        (int[]){GLFW_KEY_F11,0,0,0},
        @"${right} - ${margin} * 2 - ${width}",
        @"${bottom} - ${margin}",
        BTN_RECT
    )];
    NSOutputStream *os = [[NSOutputStream alloc] initToFileAtPath:
        [NSString stringWithFormat:@"%s/controlmap/default.json", getenv("POJAV_HOME")] append:NO];
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

void loadControlObject(UIView* targetView, NSMutableDictionary* controlDictionary, void(^walkToButton)(ControlButton* button)) {
    NSMutableString *errorString = [[NSMutableString alloc] init];

    current_control_object = controlDictionary;
    if (convertLayoutIfNecessary(controlDictionary)) {
        NSMutableArray *controlDataList = controlDictionary[@"mControlDataList"];
        setPreference(@"internal_current_button_scale", controlDictionary[@"scaledAt"]);
        for (NSMutableDictionary *buttonDict in controlDataList) {
            //APPLY_SCALE(buttonDict[@"strokeWidth"]);
            @try {
                ControlButton *button = [ControlButton buttonWithProperties:buttonDict];
                walkToButton(button);
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
            walkToButton(drawer);
            [targetView addSubview:drawer];
            //NSLog(@"DBG Added drawer=%@", drawer);

            for (NSMutableDictionary *subButton in drawerData[@"buttonProperties"]) {
                ControlSubButton *subView = [ControlSubButton buttonWithProperties:subButton];
                [drawer addButton:subView];
                walkToButton(subView);
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
