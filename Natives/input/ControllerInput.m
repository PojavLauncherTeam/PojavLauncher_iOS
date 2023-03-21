#import "ControllerInput.h"
#import "../LauncherPreferences.h"
#import "../SurfaceViewController.h"
#import "../utils.h"

#include "../glfw_keycodes.h"

// Left thumbstick directions
#define DIRECTION_EAST 0
#define DIRECTION_NORTH_EAST 1
//#define DIRECTION_NORTH 2
#define DIRECTION_NORTH_WEST 3
//#define DIRECTION_WEST 4
#define DIRECTION_SOUTH_WEST 5
//#define DIRECTION_SOUTH 6
#define DIRECTION_SOUTH_EAST 7
#define MOUSE_MAX_ACCELERATION 2

CFAbsoluteTime lastFrameTime;
CGFloat lastXValue; // lastHorizontalValue
CGFloat lastYValue; // lastVerticalValue

@implementation ControllerInput

NSMutableDictionary *gameMap, *menuMap;
BOOL leftShiftHeld;

+ (void)initKeycodeTable {
    if (gameMap && menuMap) {
        return;
    }
    
    NSString *gamepadPath = [NSString stringWithFormat:@"%s/controlmap/gamepads/%@", getenv("POJAV_HOME"), getPreference(@"default_gamepad_ctrl")];
    NSMutableDictionary *gamepadJSON = parseJSONFromFile(gamepadPath);
    
    gameMap = gamepadJSON[@"mGameMappingList"];
    menuMap = gamepadJSON[@"mMenuMappingList"];
}

+ (void)sendKeyEvent:(int)controllerKeycode pressed:(BOOL)pressed {
    int keycode;
    __block NSMutableDictionary *mapping;
    if (isGrabbing) {
        mapping = gameMap;
    } else {
        mapping = menuMap;
    }
    
    for (NSMutableDictionary *buttonDict in mapping) {
        if(controllerKeycode == [buttonDict[@"gamepad_button"] intValue]) {
            keycode = [buttonDict[@"keycode"] intValue];
        }
    }

    switch (keycode) {
        case GLFW_KEY_UNKNOWN:
            // Do nothing
            break;
        case -GLFW_KEY_LEFT_SHIFT:
            if (!pressed) {
                leftShiftHeld = !leftShiftHeld;
                CallbackBridge_nativeSendKey(GLFW_KEY_LEFT_SHIFT, 0, leftShiftHeld, 0);
            }
            break;
        case SPECIALBTN_MOUSEPRI:
            CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_LEFT, pressed, 0);
            break;
        case SPECIALBTN_MOUSEMID:
            CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_MIDDLE, pressed, 0);
            break;
        case SPECIALBTN_MOUSESEC:
            CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_RIGHT, pressed, 0);
            break;
        case SPECIALBTN_SCROLLUP:
            CallbackBridge_nativeSendScroll(0, pressed ? 1 : 0);
            break;
        case SPECIALBTN_SCROLLDOWN:
            CallbackBridge_nativeSendScroll(0, pressed ? -1 : 0);
            break;
        default:
            if (keycode == GLFW_KEY_LEFT_SHIFT) {
                leftShiftHeld = pressed;
            }
            CallbackBridge_nativeSendKey(keycode, 0, pressed, 0);
            break;
    }
}

+ (void)registerControllerCallbacks:(GCController *)controller {
    GCExtendedGamepad *gamepad = controller.extendedGamepad;

    gamepad.leftShoulder.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_LEFT_BUMPER pressed:pressed];
    };
    gamepad.rightShoulder.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER pressed:pressed];
    };

    gamepad.leftTrigger.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_LEFT_TRIGGER pressed:pressed];
    };
    gamepad.rightTrigger.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_RIGHT_TRIGGER pressed:pressed];
    };

    if (@available(iOS 13.0, *)) {
        gamepad.buttonOptions.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_BACK pressed:pressed];
        };
        gamepad.buttonMenu.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_START pressed:pressed];
        };
    }
    if (@available(iOS 14.0, *)) {
        gamepad.buttonHome.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
            [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_GUIDE pressed:pressed];
        };
    }

    gamepad.buttonA.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_A pressed:pressed];
    };
    gamepad.buttonB.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_B pressed:pressed];
    };
    gamepad.buttonX.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_X pressed:pressed];
    };
    gamepad.buttonY.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_Y pressed:pressed];
    };

    gamepad.dpad.up.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_DPAD_UP pressed:pressed];
    };
    gamepad.dpad.down.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_DPAD_DOWN pressed:pressed];
    };
    gamepad.dpad.left.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_DPAD_LEFT pressed:pressed];
    };
    gamepad.dpad.right.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_DPAD_RIGHT pressed:pressed];
    };

    gamepad.leftThumbstick.valueChangedHandler = ^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
        if (!isGrabbing) {
            // Update virtual mouse position
            lastXValue = xValue;
            lastYValue = yValue;
            return;
        }

        static char lastLThumbDirection = -2;
        char direction = -1;
        if (xValue != 0 && yValue != 0) {
            CGFloat degree = atan2f(yValue, xValue) * (180.0 / M_PI);
            if (degree < 0) {
                degree += 360;
            }
            direction = (int)((degree+22.5)/45.0) % 8;
        }
        if (lastLThumbDirection == direction) {
            return;
        }

        // Update WASD states
        CallbackBridge_nativeSendKey(GLFW_KEY_W, 0,
            direction >= DIRECTION_NORTH_EAST &&
            direction <= DIRECTION_NORTH_WEST, 0);
        CallbackBridge_nativeSendKey(GLFW_KEY_A, 0,
            direction >= DIRECTION_NORTH_WEST &&
            direction <= DIRECTION_SOUTH_WEST, 0);
        CallbackBridge_nativeSendKey(GLFW_KEY_S, 0,
            direction >= DIRECTION_SOUTH_WEST &&
            direction <= DIRECTION_SOUTH_EAST, 0);
        CallbackBridge_nativeSendKey(GLFW_KEY_D, 0,
            direction == DIRECTION_SOUTH_EAST ||
            direction == DIRECTION_EAST ||
            direction == DIRECTION_NORTH_EAST, 0);

        lastLThumbDirection = direction;
    };
    gamepad.rightThumbstick.valueChangedHandler = ^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
        if (isGrabbing) {
            lastXValue = xValue;
            lastYValue = yValue;
        }
    };
    if (@available(iOS 12.1, *)) {
        gamepad.leftThumbstickButton.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
            [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_LEFT_THUMB pressed:pressed];
        };
        gamepad.rightThumbstickButton.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
            [self sendKeyEvent:GLFW_GAMEPAD_BUTTON_RIGHT_THUMB pressed:pressed];
        };
    }
}

/**
 * Send the new mouse position, computing the delta
 */
+ (void)tick {
    // There isn't a convenient way to get ns, use ms at this point
    CGFloat frameTime = CACurrentMediaTime();
    // GameController automatically performs deadzone calculations
    // so we just take the raw input
    if (lastFrameTime != 0 && (lastXValue != 0 || lastYValue != 0)) {
        CGFloat acceleration = pow(MathUtils_dist(0, 0, lastXValue, lastYValue), MOUSE_MAX_ACCELERATION); // magnitude
        if (acceleration > 1) acceleration = 1;

        // Compute delta since last tick time
        CGFloat deltaX = lastXValue * acceleration * 18;
        CGFloat deltaY = -lastYValue * acceleration * 18;
        CGFloat deltaTimeScale = (frameTime - lastFrameTime) / (1.0/60.0); // Scale of 1 = 60Hz
        deltaX *= deltaTimeScale;
        deltaY *= deltaTimeScale;

        SurfaceViewController *vc = (id)(currentWindow().rootViewController);
        [vc sendTouchPoint:CGPointMake(deltaX, deltaY) withEvent:ACTION_MOVE_MOTION];
    }
    lastFrameTime = frameTime;
}

+ (void)unregisterControllerCallbacks:(GCController *)controller {
    GCExtendedGamepad *gamepad = controller.extendedGamepad;
    gamepad.leftShoulder.pressedChangedHandler = nil;
    gamepad.rightShoulder.pressedChangedHandler = nil;
    gamepad.leftTrigger.pressedChangedHandler = nil;
    gamepad.rightTrigger.pressedChangedHandler = nil;
    if (@available(iOS 13.0, *)) {
        gamepad.buttonOptions.pressedChangedHandler = nil;
        gamepad.buttonMenu.pressedChangedHandler = nil;
    }
    if (@available(iOS 14.0, *)) {
        gamepad.buttonHome.pressedChangedHandler = nil;
    }
    gamepad.buttonA.pressedChangedHandler = nil;
    gamepad.buttonB.pressedChangedHandler = nil;
    gamepad.buttonX.pressedChangedHandler = nil;
    gamepad.buttonY.pressedChangedHandler = nil;
    gamepad.dpad.up.pressedChangedHandler = nil;
    gamepad.dpad.down.pressedChangedHandler = nil;
    gamepad.dpad.left.pressedChangedHandler = nil;
    gamepad.dpad.right.pressedChangedHandler = nil;
    gamepad.leftThumbstick.valueChangedHandler = nil;
    gamepad.rightThumbstick.valueChangedHandler = nil;
    if (@available(iOS 12.1, *)) {
    gamepad.leftThumbstickButton.pressedChangedHandler = nil;
        gamepad.rightThumbstickButton.pressedChangedHandler = nil;
    }
}

@end
