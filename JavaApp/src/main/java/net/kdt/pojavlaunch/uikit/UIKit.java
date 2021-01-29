package net.kdt.pojavlaunch.uikit;

import org.lwjgl.glfw.*;

public class UIKit {
    static {
        System.loadLibrary("pojavexec");
    }
    
    public static native int launchUI(String[] uiArgs);
    public static native void runOnUIThread(UIKitCallback callback);
    
    
    public static void callback_AppDelegate_didFinishLaunching(int width, int height) {
        GLFW.mGLFWWindowWidth = CallbackBridge.width;
        GLFW.mGLFWWindowHeight = CallbackBridge.height;
        CallbackBridge.mouseX = CallbackBridge.width / 2;
        CallbackBridge.mouseY = height / 2;
        net.kdt.pojavlaunch.PLaunchApp.applicationDidFinishLaunching();
    }
    
    public static void callback_SurfaceViewController_onTouch(int event, int x, int y) {
        switch (event) {
            case ACTION_DOWN:
            case ACTION_UP:
                CallbackBridge.mouseLastX = x;
                CallbackBridge.mouseLastY = y;
                break;
                
            case ACTION_MOVE:
                if (GLFW.mGLFWIsGrabbing) {
                    CallbackBridge.mouseX += x - CallbackBridge.mouseLastX;
                    CallbackBridge.mouseY += y - CallbackBridge.mouseLastY;
                    
                    CallbackBridge.mouseLastX = CallbackBridge.x;
                    CallbackBridge.mouseLastY = CallbackBridge.y;
                } else {
                    CallbackBridge.mouseX = CallbackBridge.x;
                    CallbackBridge.mouseY = CallbackBridge.y;
                }
                break;
        }
        
        sendCursorPos(CallbackBridge.mouseX, CallbackBridge.mouseY);
    }
}
