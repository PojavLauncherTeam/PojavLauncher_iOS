package net.kdt.pojavlaunch.uikit;

import java.io.*;
import java.lang.reflect.*;
import java.util.jar.*;
import net.kdt.pojavlaunch.utils.MCOptionUtils;
import net.kdt.pojavlaunch.*;
import org.lwjgl.glfw.*;

public class UIKit {
    public static final int ACTION_DOWN = 0;
    public static final int ACTION_UP = 1;
    public static final int ACTION_MOVE = 2;
    public static final int ACTION_MOVE_MOTION = 3;

    private static int guiScale;

    private static void patch_FlatLAF_setLinux() {
        String osName = System.getProperty("os.name");
        System.setProperty("os.name", "Linux");
        try {
            Class<?> clazz = ClassLoader.getSystemClassLoader().loadClass("com.formdev.flatlaf.util.SystemInfo");
            // trigger static init
            clazz.getField("isMacOS").get(null);
        } catch (Throwable e) {
            System.out.println("Skipped patch_FlatLAF_setLinux");
            //e.printStackTrace();
        }
        System.setProperty("os.name", osName);
    }

    public static void callback_JavaGUIViewController_launchJarFile(final String filepath) throws Throwable {
        // Thread for refreshing the AWT buffer
        new Thread(() -> {
            Method getCurrentScreenRGB;
            try {
                try {
                    getCurrentScreenRGB = Class.forName("net.java.openjdk.cacio.ctc.CTCScreen").getMethod("getCurrentScreenRGB");
                } catch (ClassNotFoundException e) {
                    getCurrentScreenRGB = Class.forName("com.github.caciocavallosilano.cacio.ctc.CTCScreen").getMethod("getCurrentScreenRGB");
                }
            } catch (Throwable th) {
                System.err.println("Failed to find class CTCScreen");
                th.printStackTrace();
                System.exit(1);
                return;
            }

            long lastTime = System.currentTimeMillis();
            while (true) {
                int[] pixelsArray = null;
                try{
                    pixelsArray = (int[])getCurrentScreenRGB.invoke(null);
                } catch (Throwable e) {}
                if (pixelsArray != null) {
                    //System.out.println(java.util.Arrays.toString(pixelsArray));
                    refreshAWTBuffer(pixelsArray);
                }
                long currentTime = System.currentTimeMillis();
                if (currentTime - lastTime < 16) {
                    try {
                        Thread.sleep(16 - (currentTime - lastTime));
                    } catch (InterruptedException e) {
                        break;
                    }
                }
                lastTime = currentTime;
            }
        }, "AWTFBRefreshThread").start();

        // Launch the JAR file
        String mainClassName = null;

        JarFile jarfile = new JarFile(filepath);
        String mainClass = jarfile.getManifest().getMainAttributes().getValue("Main-Class");
        jarfile.close();
        if (mainClass == null) {
            throw new IllegalArgumentException("no main manifest attribute, in \"" + filepath + "\"");
        }

        PojavClassLoader loader = (PojavClassLoader) ClassLoader.getSystemClassLoader();
        loader.addURL(new File(filepath).toURI().toURL());

        // LabyMod Installer uses FlatLAF which has some macOS-specific codes, so we make it think it's running on Linux.
        patch_FlatLAF_setLinux();

        Class<?> clazz = loader.loadClass(mainClass);
        Method method = clazz.getMethod("main", String[].class);
        method.invoke(null, new Object[]{new String[]{}});
    }

    public static void updateMCGuiScale() {
        MCOptionUtils.load();
        String str = MCOptionUtils.get("guiScale");
        guiScale = (str == null ? 0 :Integer.parseInt(str));

        int scale = Math.max(Math.min(Tools.mGLFWWindowWidth / 320, Tools.mGLFWWindowHeight / 240), 1);
        if(scale < guiScale || guiScale == 0){
            guiScale = scale;
        }
        updateMCGuiScale(guiScale);
    }

    static {
        System.load(System.getenv("BUNDLE_PATH") + "/PojavLauncher");
    }

    public static native void refreshAWTBuffer(int[] array);

    // public static native void runOnUIThread(UIKitCallback callback);

    public static native void showError(String title, String message, boolean exitIfOk);

    private static native void updateMCGuiScale(int scale);
} 
