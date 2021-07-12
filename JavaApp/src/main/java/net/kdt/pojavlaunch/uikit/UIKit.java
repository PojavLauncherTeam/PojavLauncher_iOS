package net.kdt.pojavlaunch.uikit;

import net.kdt.pojavlaunch.utils.MCOptionUtils;
import net.kdt.pojavlaunch.PLaunchApp;
import org.lwjgl.glfw.*;

public class UIKit {
    public static final int ACTION_DOWN = 0;
    public static final int ACTION_UP = 1;
    public static final int ACTION_MOVE = 2;
    
    private static int guiScale;
    
    public static void callback_LauncherViewController_installMinecraft(String versionPath) {
        PLaunchApp.installMinecraft(versionPath);
    }

    public static void callback_SurfaceViewController_launchMinecraft(int width, int height) {
        System.setProperty("cacio.managed.screensize", width + "x" + height);

        GLFW.internalChangeMonitorSize(width, height);
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
    
    public static void updateMCGuiScale() {
        MCOptionUtils.load();
        String str = MCOptionUtils.get("guiScale");
        guiScale = (str == null ? 0 :Integer.parseInt(str));

        int scale = Math.max(Math.min(GLFW.mGLFWWindowWidth / 320, GLFW.mGLFWWindowHeight / 240), 1);
        if(scale < guiScale || guiScale == 0){
            guiScale = scale;
        }
        updateMCGuiScale(guiScale);
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
    
    public static native void showError(String title, String message, boolean exitIfOk);
    
    private static native void updateMCGuiScale(int scale);
    
    // Update progress
    public static native boolean updateProgress(float progress, String message);
    
    // Start SurfaceViewController
    public static native void launchMinecraftSurface(boolean isUseStackQueueBool);
}
