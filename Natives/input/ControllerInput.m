#import "ControllerInput.h"
#import "../SurfaceViewController.h"
#import "../utils.h"

#include "../glfw_keycodes.h"

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

    gameMap = [[NSMutableDictionary alloc] init];

    gameMap[@(GLFW_KEY_W)] = @(GLFW_KEY_W);
    gameMap[@(GLFW_KEY_A)] = @(GLFW_KEY_A);
    gameMap[@(GLFW_KEY_S)] = @(GLFW_KEY_S);
    gameMap[@(GLFW_KEY_D)] = @(GLFW_KEY_D);
    gameMap[@(SPECIALBTN_MOUSEPRI)] = @(SPECIALBTN_MOUSEPRI);
    gameMap[@(SPECIALBTN_MOUSEMID)] = @(SPECIALBTN_MOUSEMID);
    gameMap[@(SPECIALBTN_MOUSESEC)] = @(SPECIALBTN_MOUSESEC);

    gameMap[@(GLFW_GAMEPAD_BUTTON_LEFT_BUMPER)] = @(SPECIALBTN_SCROLLUP);
    gameMap[@(GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER)] = @(SPECIALBTN_SCROLLDOWN);

    gameMap[@(GLFW_GAMEPAD_AXIS_LEFT_TRIGGER)] = @(SPECIALBTN_MOUSESEC);
    gameMap[@(GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER)] = @(SPECIALBTN_MOUSEPRI);

    menuMap[@(GLFW_GAMEPAD_BUTTON_BACK)] = @(GLFW_KEY_TAB);
    menuMap[@(GLFW_GAMEPAD_BUTTON_START)] = @(GLFW_KEY_ESCAPE);
    //gameMap[@(GLFW_GAMEPAD_BUTTON_GUIDE)] = @(GLFW_KEY_UNKNOWN);

    gameMap[@(GLFW_GAMEPAD_BUTTON_A)] = @(GLFW_KEY_SPACE);
    gameMap[@(GLFW_GAMEPAD_BUTTON_B)] = @(GLFW_KEY_Q);
    gameMap[@(GLFW_GAMEPAD_BUTTON_X)] = @(GLFW_KEY_E);
    gameMap[@(GLFW_GAMEPAD_BUTTON_Y)] = @(GLFW_KEY_F);

    gameMap[@(GLFW_GAMEPAD_BUTTON_DPAD_UP)] = @(GLFW_KEY_LEFT_SHIFT);
    gameMap[@(GLFW_GAMEPAD_BUTTON_DPAD_DOWN)] = @(GLFW_KEY_O);
    gameMap[@(GLFW_GAMEPAD_BUTTON_DPAD_LEFT)] = @(GLFW_KEY_J);
    gameMap[@(GLFW_GAMEPAD_BUTTON_DPAD_RIGHT)] = @(GLFW_KEY_K);

    gameMap[@(GLFW_GAMEPAD_BUTTON_LEFT_THUMB)] = @(GLFW_KEY_LEFT_CONTROL);
    gameMap[@(GLFW_GAMEPAD_BUTTON_RIGHT_THUMB)] = @(-GLFW_KEY_LEFT_SHIFT);

    menuMap = [[NSMutableDictionary alloc] init];

    menuMap[@(SPECIALBTN_MOUSEPRI)] = @(SPECIALBTN_MOUSEPRI);
    menuMap[@(SPECIALBTN_MOUSEMID)] = @(SPECIALBTN_MOUSEMID);
    menuMap[@(SPECIALBTN_MOUSESEC)] = @(SPECIALBTN_MOUSESEC);

    menuMap[@(GLFW_GAMEPAD_BUTTON_LEFT_BUMPER)] = @(SPECIALBTN_SCROLLUP);
    menuMap[@(GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER)] = @(SPECIALBTN_SCROLLDOWN);

    menuMap[@(GLFW_GAMEPAD_BUTTON_A)] = @(SPECIALBTN_MOUSEPRI);
    menuMap[@(GLFW_GAMEPAD_BUTTON_B)] = @(GLFW_KEY_ESCAPE);
    menuMap[@(GLFW_GAMEPAD_BUTTON_X)] = @(SPECIALBTN_MOUSESEC);
    menuMap[@(GLFW_GAMEPAD_BUTTON_Y)] = @(GLFW_KEY_LEFT_SHIFT);

    menuMap[@(GLFW_GAMEPAD_BUTTON_DPAD_DOWN)] = @(GLFW_KEY_O);
    menuMap[@(GLFW_GAMEPAD_BUTTON_DPAD_LEFT)] = @(GLFW_KEY_J);
    menuMap[@(GLFW_GAMEPAD_BUTTON_DPAD_RIGHT)] = @(GLFW_KEY_K);
}

+ (void)sendKeyEvent:(int)controllerKeycode pressed:(BOOL)pressed {
    int keycode;
    if (isGrabbing) {
        keycode = [gameMap[@(controllerKeycode)] intValue];
    } else {
        keycode = [menuMap[@(controllerKeycode)] intValue];
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
            CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_LEFT, pressed, leftShiftHeld ? GLFW_MOD_SHIFT : 0);
            break;
        case SPECIALBTN_MOUSEMID:
            CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_MIDDLE, pressed, leftShiftHeld ? GLFW_MOD_SHIFT : 0);
            break;
        case SPECIALBTN_MOUSESEC:
            CallbackBridge_nativeSendMouseButton(GLFW_MOUSE_BUTTON_RIGHT, pressed, leftShiftHeld ? GLFW_MOD_SHIFT : 0);
            break;
        case SPECIALBTN_SCROLLUP:
            CallbackBridge_nativeSendScroll(0, -1);
            break;
        case SPECIALBTN_SCROLLDOWN:
            CallbackBridge_nativeSendScroll(0, 1);
            break;
        case GLFW_KEY_LEFT_SHIFT:
            leftShiftHeld = pressed;
        default:
            CallbackBridge_nativeSendKey(keycode, 0, pressed, leftShiftHeld ? GLFW_MOD_SHIFT : 0);
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
        [self sendKeyEvent:SPECIALBTN_MOUSESEC pressed:pressed];
    };
    gamepad.rightTrigger.pressedChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        [self sendKeyEvent:SPECIALBTN_MOUSEPRI pressed:pressed];
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
            lastXValue = xValue;
            lastYValue = yValue;
        }
    };
    gamepad.rightThumbstick.valueChangedHandler = ^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
        if (isGrabbing) {
            lastXValue = xValue;
            lastYValue = yValue;
        }
    };
    gamepad.rightThumbstick.up.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_KEY_W pressed:pressed];
    };
    gamepad.rightThumbstick.left.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_KEY_A pressed:pressed];
    };
    gamepad.rightThumbstick.down.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_KEY_S pressed:pressed];
    };
    gamepad.rightThumbstick.right.pressedChangedHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        [self sendKeyEvent:GLFW_KEY_D pressed:pressed];
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
    CGFloat frameTimeMilis = CACurrentMediaTime();
    // GameController automatically performs deadzone calculations
    // so we just take the raw input
    if (lastFrameTime != 0 && (lastXValue != 0 || lastYValue != 0)) {
        CGFloat acceleration = MathUtils_dist(0, 0, lastXValue, lastYValue); // magnitude
        CGFloat deltaX = lastXValue * acceleration * 18;
        CGFloat deltaY = -lastYValue * acceleration * 18;
        CGFloat deltaTimeScale = (frameTimeMilis - lastFrameTime) / 0.016666666; // Scale of 1 = 60Hz
        deltaX *= deltaTimeScale;
        deltaY *= deltaTimeScale;

        SurfaceViewController *vc = (id)(currentWindow().rootViewController);
        [vc sendTouchPoint:CGPointMake(deltaX, deltaY) withEvent:ACTION_MOVE_MOTION];
    }
    lastFrameTime = frameTimeMilis;
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
    gamepad.rightThumbstick.up.pressedChangedHandler = nil;
    gamepad.rightThumbstick.down.pressedChangedHandler = nil;
    gamepad.rightThumbstick.left.pressedChangedHandler = nil;
    gamepad.rightThumbstick.right.pressedChangedHandler = nil;
    gamepad.rightThumbstick.valueChangedHandler = nil;
    if (@available(iOS 12.1, *)) {
    gamepad.leftThumbstickButton.pressedChangedHandler = nil;
        gamepad.rightThumbstickButton.pressedChangedHandler = nil;
    }
}

@end
