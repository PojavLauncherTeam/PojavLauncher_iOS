package net.kdt.pojavlaunch.uikit;

import net.kdt.pojavlaunch.PLaunchApp;
import org.lwjgl.glfw.*;

public class UIKit {
    public static final int ACTION_DOWN = 0;
    public static final int ACTION_UP = 1;
    public static final int ACTION_MOVE = 2;
    
    public static void callback_LauncherViewController_installMinecraft() {
        PLaunchApp.installMinecraft();
    }

    public static void callback_SurfaceViewController_launchMinecraft(int width, int height) {
        GLFW.mGLFWWindowWidth = width;
        GLFW.mGLFWWindowHeight = height;
        CallbackBridge.mouseX = width / 2;
        CallbackBridge.mouseY = height / 2;
        PLaunchApp.launchMinecraft();
    }
    
    public static void callback_SurfaceViewController_onTouch(int event, int x, int y) {
        switch (event) {
            case ACTION_DOWN:
            case ACTION_UP:
                if (!GLFW.mGLFWIsGrabbing) {
                    CallbackBridge.mouseX = x;
                    CallbackBridge.mouseY = y;
                }
                CallbackBridge.mouseLastX = x;
                CallbackBridge.mouseLastY = y;
                break;
                
            case ACTION_MOVE:
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
    
    public static boolean updateProgressSafe(final float progress, final String message) {
        System.out.println(message);
        return updateProgress(progress, ((int) (progress * 100)) + "% - " + message);
    }

    static {
        System.loadLibrary("pojavexec");
    }
    
    public static native int launchUI(String[] uiArgs);
    // public static native void runOnUIThread(UIKitCallback callback);
    
    // Update progress
    public static native boolean updateProgress(float progress, String message);
    
    // Start SurfaceViewController
    public static native void launchMinecraftSurface(boolean isUseStackQueueBool);
}
