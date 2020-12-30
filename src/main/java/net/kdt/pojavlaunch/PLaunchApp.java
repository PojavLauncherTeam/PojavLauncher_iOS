package net.kdt.pojavlaunch;

import java.io.*;

import javafx.application.Application;

import org.lwjgl.glfw.CallbackBridge;

import org.robovm.apple.foundation.*;
import org.robovm.apple.uikit.*;
import org.robovm.pods.dialog.*;

import net.kdt.pojavlaunch.prefs.*;

public class PLaunchApp extends UIApplicationDelegateAdapter {

    @Override
    public boolean didFinishLaunching(UIApplication application,
        UIApplicationLaunchOptions launchOptions) {
        File f = new File(Tools.DIR_HOME_JRE);
        if (f.exists()) {
            Thread launchThread = new Thread() {
                @Override
                public void run() {
                    // Application.launch(PLaunchJFXApp.class);
                    
        // Start Minecraft there!
        File file = new File(Tools.DIR_GAME_NEW);
        file.mkdirs();
        
        String mcver = "1.13";
        try {
            mcver = Tools.read(Tools.DIR_GAME_HOME + "/config_ver.txt");
        } catch (IOException e) {
            System.out.println("config_ver.txt not found, defaulting to Minecraft 1.13");
        }
        
        MinecraftAccount acc = new MinecraftAccount();
        acc.selectedVersion = mcver;
        JMinecraftVersionList.Version version = Tools.getVersionInfo(mcver);
        
        try {
            Tools.launchMinecraft(acc, version);
        } catch (Throwable th) {
            Tools.showError(th);
        }
                }
            };
            // launchThread.setDaemon(true);
            launchThread.start();
        } else {
            WindowAlertController alertController = new WindowAlertController("Error", "OpenJDK is not installed. Please install before enter launcher.", UIAlertControllerStyle.Alert);
            alertController.addAction(new UIAlertAction("OK",
                UIAlertActionStyle.Default, (action) -> {
                    alertController.dismissViewController(true, null);
                }
            ));
            alertController.show();  
        }

        return true;
    }
    
    public static void main(String[] args) {
/*
        Thread.setDefaultUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() {
            @Override
            public void uncaughtException(Thread thread, final Throwable ex) {
                StringWriter sw = new StringWriter();
                PrintWriter pw = new PrintWriter(sw);
                ex.printStackTrace(pw);
                pw.flush();
                System.err.println("UNCAUGHT EXCEPTION: " + sw.toString());

//                Platform.getPlatform().runOnUIThread(() -> {
//                    WindowAlertController alertController = new WindowAlertController("Error", sw.toString(), UIAlertControllerStyle.Alert);
//                    alertController.addAction(new UIAlertAction("OK",
//                        UIAlertActionStyle.Default, (action) -> {
//                            alertController.dismissViewController(true, null);
//                        }
//                    ));
//                    alertController.show();  
//                });

            }
        });
        
        try {
            PrintStream filePrintStream = new PrintStream(new FileOutputStream(System.getenv("HOME") + "/log_output.txt"));
            System.setOut(filePrintStream);
            System.setErr(filePrintStream);

            System.out.println("Starting UI...");
        } catch (Throwable th) {
            throw new RuntimeException(th);
        }
*/

        LauncherPreferences.loadPreferences();

        System.setProperty("java.library.path", Tools.DIR_DATA + "/Frameworks");

        System.setProperty("javafx.verbose", "true");
        System.setProperty("javafx.platform", "ios");
        System.setProperty("glass.platform", "ios");
        System.setProperty("jfxmedia.platforms", "IOSPlatform");
        System.setProperty("com.sun.javafx.isEmbedded", "true");
        
        System.setProperty("prism.verbose", "true");
        System.setProperty("prism.allowhidpi", "true");
        System.setProperty("prism.mintexturesize", "16");
        System.setProperty("prism.static.libraries", "true");
        System.setProperty("prism.useNativeIIO", "false");

        System.out.println("Starting UI...");
        NSAutoreleasePool pool = new NSAutoreleasePool();
        UIApplication.main(args, null, PLaunchApp.class);
        pool.drain();
    }
}
