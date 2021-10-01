package net.kdt.pojavlaunch.uikit;

import java.io.*;
import java.lang.reflect.*;
import java.util.jar.*;
import net.java.openjdk.cacio.ctc.CTCScreen;
import net.kdt.pojavlaunch.utils.MCOptionUtils;
import net.kdt.pojavlaunch.*;
import org.lwjgl.glfw.*;

public class UIKit {
    public static final int ACTION_DOWN = 0;
    public static final int ACTION_UP = 1;
    public static final int ACTION_MOVE = 2;
    
    private static int guiScale;

    private static void patch_FlatLAF_setLinux() {
        String osName = System.getProperty("os.name");
        System.setProperty("os.name", "Linux");
        try {
            Class<?> clazz = ClassLoader.getSystemClassLoader().loadClass("com.formdev.flatlaf.util.SystemInfo");
            // trigger static init
            clazz.getField("isMacOS").get(null);
        } catch (Throwable e) {
            e.printStackTrace();
        }
        System.setProperty("os.name", osName);
    }

    public static void callback_JavaGUIViewController_launchJarFile(final String filepath, int width, int height) {
        System.setProperty("cacio.managed.screensize", width + "x" + height);

        // Thread for refreshing the AWT buffer
        new Thread(() -> {
            try {
                long lastTime = System.currentTimeMillis();
                while (true) {
                    int[] pixelsArray = null;
                    try{
                        pixelsArray = CTCScreen.getCurrentScreenRGB();
                    } catch (NullPointerException e) {
                        Thread.sleep(500);
                    }
                    if (pixelsArray != null) {
                        //System.out.println(java.util.Arrays.toString(pixelsArray));
                        refreshAWTBuffer(pixelsArray);
                    }
                    long currentTime = System.currentTimeMillis();
                    if (currentTime - lastTime < 16) {
                        Thread.sleep(16 - (currentTime - lastTime));
                    }
                    lastTime = currentTime;
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }, "AWTFBRefreshThread").start();

        // Thread for launching the JAR file
        new Thread(() -> {
            String mainClassName = null;
            try {
                JarFile jarfile = new JarFile(filepath);
                String mainClass = jarfile.getManifest().getMainAttributes().getValue("Main-Class");
                jarfile.close();
                if (mainClass == null) {
                    throw new IllegalArgumentException("no main manifest attribute, in \"" + filepath + "\"");
                }

                PojavClassLoader loader = (PojavClassLoader) ClassLoader.getSystemClassLoader();
                loader.addURL(new File(filepath).toURI().toURL());

                // LabyMod Installer uses FlatLAF which has some macOS-specific codes, so we make it thinks it's running on Linux.
                patch_FlatLAF_setLinux();

                Class<?> clazz = loader.loadClass(mainClass);
                Method method = clazz.getMethod("main", String[].class);
                method.invoke(null, new Object[]{new String[]{}});

                // throw new RuntimeException("Application exited");
            } catch (Throwable th) {
                Tools.showError(th, true);
            }
        }, "ModInstallerThread").start();
    }
    
    public static void callback_LauncherViewController_installMinecraft(String versionPath) {
        PLaunchApp.installMinecraft(versionPath);
    }

    public static void callback_SurfaceViewController_launchMinecraft(int width, int height, String rendererLibName) {
        MCOptionUtils.load();
        MCOptionUtils.set("overrideWidth", Integer.toString(width));
        MCOptionUtils.set("overrideHeight", Integer.toString(height));
        MCOptionUtils.save();

        System.setProperty("cacio.managed.screensize", width + "x" + height);
        System.setProperty("org.lwjgl.opengl.libname", rendererLibName);

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
    
    public static void updateProgressSafe(final float progress, final String message) {
        System.out.println(message);
        updateProgress(progress, ((int) (progress * 100)) + "% - " + message);
    }

    static {
        System.load(System.getenv("BUNDLE_PATH") + "/PojavLauncher");
    }

    public static native void refreshAWTBuffer(int[] array);

    public static native int launchUI();
    // public static native void runOnUIThread(UIKitCallback callback);
    
    public static native void showError(String title, String message, boolean exitIfOk);
    
    private static native void updateMCGuiScale(int scale);
    
    // Update progress
    public static native void updateProgress(float progress, String message);
    
    // Start SurfaceViewController
    public static native void launchMinecraftSurface(boolean isUseStackQueueBool);
}
