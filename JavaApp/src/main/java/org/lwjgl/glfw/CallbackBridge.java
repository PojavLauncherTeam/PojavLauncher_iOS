package org.lwjgl.glfw;

import java.io.*;
import java.util.*;
import android.util.*;

import net.kdt.pojavlaunch.*;
import net.kdt.pojavlaunch.uikit.UIKit;
import net.kdt.pojavlaunch.utils.MCOptionUtils;

public class CallbackBridge {
    public static final int CLIPBOARD_COPY = 2000;
    public static final int CLIPBOARD_PASTE = 2001;
    
    public static final int EVENT_TYPE_CHAR = 1000;
    public static final int EVENT_TYPE_CHAR_MODS = 1001;
    public static final int EVENT_TYPE_CURSOR_ENTER = 1002;
    public static final int EVENT_TYPE_CURSOR_POS = 1003;
    public static final int EVENT_TYPE_FRAMEBUFFER_SIZE = 1004;
    public static final int EVENT_TYPE_KEY = 1005;
    public static final int EVENT_TYPE_MOUSE_BUTTON = 1006;
    public static final int EVENT_TYPE_SCROLL = 1007;
    public static final int EVENT_TYPE_WINDOW_POS = 1008;
    public static final int EVENT_TYPE_WINDOW_SIZE = 1009;
    
    public static final int ANDROID_TYPE_GRAB_STATE = 0;
    
    // Should pending events be limited?
    volatile public static List<Object[]> PENDING_EVENT_LIST = new ArrayList<>();
    volatile public static boolean PENDING_EVENT_READY = false;
    
    public static final boolean INPUT_DEBUG_ENABLED;
    
    private static boolean inputReady;
    
    // TODO send grab state event to Android
    
    static {
        System.load(System.getenv("BUNDLE_PATH") + "/PojavLauncher");

        // Forge 1.17+ initialize their very own space (both Java and JNI) so we re-init stuff here
        MCOptionUtils.load();
        Tools.mGLFWWindowWidth = Integer.parseInt(MCOptionUtils.get("overrideWidth"));
        Tools.mGLFWWindowHeight = Integer.parseInt(MCOptionUtils.get("overrideHeight"));
        MCOptionUtils.save(); // Free the loaded data
        CallbackBridge.setClass();
        try {
            Class.forName("net.kdt.pojavlaunch.uikit.UIKit");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }

        INPUT_DEBUG_ENABLED = Boolean.parseBoolean(System.getProperty("glfwstub.debugInput", "false"));
    }
    
// BEGIN launcher side
    public static float mouseX, mouseY, mouseLastX, mouseLastY;
    public static boolean mouseLeft;
    //public static StringBuilder DEBUG_STRING = new StringBuilder();

    public static boolean nativeIsGrabbing() {
        return GLFW.mGLFWIsGrabbing;
    }
    
    private static void nativeSendCursorPos(float x, float y) {
        if (!inputReady) return;
        GLFW.mGLFWCursorX = x + GLFW.internalGetWindow(GLFW.mainContext).x;
        GLFW.mGLFWCursorY = y + GLFW.internalGetWindow(GLFW.mainContext).y;
    }
    private static void nativeSendKeycode(int keycode, char keychar, int scancode, int action, int mods) {
        if (!inputReady) return;
        // TODO keycode
        // PENDING_EVENT_LIST.add(new Integer[]{EVENR_TYPE_CHAR_MODS});
    }
    private static void nativeSendMouseButton(int button, int action, int mods) {
        if (!inputReady) return;
        PENDING_EVENT_LIST.add(new Object[]{EVENT_TYPE_MOUSE_BUTTON, button, action, mods, 0});
    }
    private static void nativeSendScroll(double xoffset, double yoffset) {
        if (!inputReady) return;
        PENDING_EVENT_LIST.add(new Object[]{EVENT_TYPE_SCROLL, (int) xoffset, (int) yoffset, 0, 0});
    }
    private static void nativeSendScreenSize(int width, int height) {
        if (!inputReady) return;
        PENDING_EVENT_LIST.add(new Object[]{EVENT_TYPE_FRAMEBUFFER_SIZE, width, height, 0, 0});
        PENDING_EVENT_LIST.add(new Object[]{EVENT_TYPE_WINDOW_SIZE, width, height, 0, 0});
    }
    private static void nativeSendWindowPos(int x, int y) {
        if (!inputReady) return;
        PENDING_EVENT_LIST.add(new Object[]{EVENT_TYPE_WINDOW_POS, x, y, 0, 0});
    }

    // volatile private static boolean isGrabbing = false;
    public static class PusherRunnable implements Runnable {
        int button; float x; float y;
        public PusherRunnable(int button, float x, float y) {
           this.button = button;
           this.x = x;
           this.y = y;
        }
        @Override
        public void run() {
            putMouseEventWithCoords(button, 1, x, y);
            try { Thread.sleep(40); } catch (InterruptedException e) {}
            putMouseEventWithCoords(button, 0, x, y);
        }
    }
    public static void putMouseEventWithCoords(int button, float x, float y /* , int dz, long nanos */) {
        new Thread(new PusherRunnable(button,x,y)).run();
    }

    public static void putMouseEventWithCoords(int button, int state, float x, float y /* , int dz, long nanos */) {
        sendCursorPos(x, y);
        sendMouseKeycode(button, CallbackBridge.getCurrentMods(), state == 1);
    }

    private static boolean threadAttached;
    public static void sendCursorPos(float x, float y) {
        if (!threadAttached) {
            threadAttached = true; // CallbackBridge.nativeAttachThreadToOther(true, true /* TODO BaseMainActivity.isInputStackCall */);
        }

        //DEBUG_STRING.append("CursorPos=" + x + ", " + y + "\n");
        mouseX = x;
        mouseY = y;
        nativeSendCursorPos(x, y);
    }

    public static void sendKeycode(int keycode, char keychar, int scancode, int modifiers, boolean isDown) {
        //DEBUG_STRING.append("KeyCode=" + keycode + ", Char=" + keychar);
        // TODO CHECK: This may cause input issue, not receive input!
        /*
         if (!nativeSendCharMods((int) keychar, modifiers) || !nativeSendChar(keychar)) {
         nativeSendKey(keycode, 0, isDown ? 1 : 0, modifiers);
         }
         */

        nativeSendKeycode(keycode, keychar, scancode, isDown ? 1 : 0, modifiers);

        // sendData(JRE_TYPE_KEYCODE_CONTROL, keycode, Character.toString(keychar), Boolean.toString(isDown), modifiers);
    }

    public static void sendMouseKeycode(int button, int modifiers, boolean isDown) {
        //DEBUG_STRING.append("MouseKey=" + button + ", down=" + isDown + "\n");
        // if (isGrabbing()) DEBUG_STRING.append("MouseGrabStrace: " + android.util.Log.getStackTraceString(new Throwable()) + "\n");
        nativeSendMouseButton(button, isDown ? 1 : 0, modifiers);
    }

    public static void sendMouseKeycode(int keycode) {
        sendMouseKeycode(keycode, CallbackBridge.getCurrentMods(), true);
        sendMouseKeycode(keycode, CallbackBridge.getCurrentMods(), false);
    }

    public static void sendScroll(double xoffset, double yoffset) {
        //DEBUG_STRING.append("ScrollX=" + xoffset + ",ScrollY=" + yoffset);
        nativeSendScroll(xoffset, yoffset);
    }

    public static void sendUpdateWindowSize(int w, int h) {
        nativeSendScreenSize(w, h);
    }
    
    public static boolean isGrabbing() {
        return nativeIsGrabbing();
    }

    public static boolean holdingAlt, holdingCapslock, holdingCtrl,
    holdingNumlock, holdingShift;
    public static int getCurrentMods() {
        int currMods = 0;
        if (holdingAlt) {
            currMods &= LWJGLGLFWKeycode.GLFW_MOD_ALT;
        } if (holdingCapslock) {
            currMods &= LWJGLGLFWKeycode.GLFW_MOD_CAPS_LOCK;
        } if (holdingCtrl) {
            currMods &= LWJGLGLFWKeycode.GLFW_MOD_CONTROL;
        } if (holdingNumlock) {
            currMods &= LWJGLGLFWKeycode.GLFW_MOD_NUM_LOCK;
        } if (holdingShift) {
            currMods &= LWJGLGLFWKeycode.GLFW_MOD_SHIFT;
        }
        return currMods;
    }
// END launcher side
    
    public static void sendGrabbing(boolean grab, float xset, float yset) {
        // sendData(ANDROID_TYPE_GRAB_STATE, Boolean.toString(grab));
        
        if (grab) {
            UIKit.updateMCGuiScale();
        }
        
        mouseX = xset;
        mouseY = yset;
        
        GLFW.mGLFWIsGrabbing = grab;
        nativeSetGrabbing(grab, xset, yset);
    }
    
    // Called from native code
    public static void receiveCallback(int type, float i1, float i2, int i3, int i4) {
       /*
        if (INPUT_DEBUG_ENABLED) {
            System.out.println("LWJGL GLFW Callback received type=" + Integer.toString(type) + ", data=" + i1 + ", " + i2 + ", " + i3 + ", " + i4);
        }
        */
        if (PENDING_EVENT_READY) {
            if (type == EVENT_TYPE_CURSOR_POS) {
                GLFW.mGLFWCursorX = (double) i1;
                GLFW.mGLFWCursorY = (double) i2;
            } else if (type == EVENT_TYPE_SCROLL) {
                PENDING_EVENT_LIST.add(new Object[]{type, i1, i2, i3, i4});
            } else {
                PENDING_EVENT_LIST.add(new Object[]{type, (int)i1, (int)i2, i3, i4});
            }
        } // else System.out.println("Event input is not ready yet!");
    }
    
    // public static native void nativeSendData(boolean isAndroid, int type, String data);
    public static boolean nativeSetInputReady(boolean ready) {
        inputReady = ready;
        return true;
    }
    
    public static native String nativeClipboard(int action, String copy);
    private static native void nativeSetGrabbing(boolean grab, float xset, float yset);
    public static native void setClass();
}

