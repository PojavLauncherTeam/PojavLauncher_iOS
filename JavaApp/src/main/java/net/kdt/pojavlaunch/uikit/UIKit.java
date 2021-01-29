package net.kdt.pojavlaunch.uikit;

import org.lwjgl.glfw.*;

public class UIKit {
    public static final int ACTION_DOWN = 0;
    public static final int ACTION_UP = 1;
    public static final int ACTION_MOVE = 2;
    
    public static void callback_AppDelegate_didFinishLaunching(int width, int height) {
        GLFW.mGLFWWindowWidth = width;
        GLFW.mGLFWWindowHeight = height;
        CallbackBridge.mouseX = width / 2;
        CallbackBridge.mouseY = height / 2;
        net.kdt.pojavlaunch.PLaunchApp.applicationDidFinishLaunching();
    }
    
    public static void callback_SurfaceViewController_onTouch(int event, int x, int y) {
        switch (event) {
            case CallbackBridge.ACTION_DOWN:
            case CallbackBridge.ACTION_UP:
                CallbackBridge.mouseLastX = x;
                CallbackBridge.mouseLastY = y;
                break;
                
            case CallbackBridge.ACTION_MOVE:
                if (GLFW.mGLFWIsGrabbing) {
                    CallbackBridge.mouseX += x - CallbackBridge.mouseLastX;
                    CallbackBridge.mouseY += y - CallbackBridge.mouseLastY;
                    
                    CallbackBridge.mouseLastX = x;
                    CallbackBridge.mouseLastY = y;
                } else {
                    CallbackBridge.mouseX = x;
                    CallbackBridge.mouseY = y;
                }
                break;
        }
        
        CallbackBridge.sendCursorPos(CallbackBridge.mouseX, CallbackBridge.mouseY);
    }
    
    static {
        System.loadLibrary("pojavexec");
    }
    
    public static native int launchUI(String[] uiArgs);
    public static native void runOnUIThread(UIKitCallback callback);
}
