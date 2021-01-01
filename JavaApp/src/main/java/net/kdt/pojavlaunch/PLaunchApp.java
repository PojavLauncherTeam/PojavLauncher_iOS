package net.kdt.pojavlaunch;

import java.io.*;
import java.util.Arrays;

import org.lwjgl.glfw.CallbackBridge;
/*
import org.robovm.apple.foundation.*;
import org.robovm.apple.uikit.*;
import org.robovm.pods.dialog.*;
*/
import net.kdt.pojavlaunch.prefs.*;
import net.kdt.pojavlaunch.utils.*;
import net.kdt.pojavlaunch.value.*;

public class PLaunchApp {
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
        System.out.println("We are on java now! Starting UI...");
        org.lwjgl.glfw.CallbackBridge.nativeLaunchUI(args);

        LauncherPreferences.loadPreferences();
    }
    
    public static void launchMinecraft() {
        System.out.println("Saving GLES context");
        JREUtils.saveGLContext();
    
        // Start Minecraft there!
        System.out.println("Finding a version");
        File file = new File(Tools.DIR_GAME_NEW);
        file.mkdirs();
        
        String mcver = "1.13";
        try {
            mcver = Tools.read(Tools.DIR_GAME_HOME + "/config_ver.txt");
        } catch (IOException e) {
            System.out.println("config_ver.txt not found, defaulting to Minecraft 1.13");
        }
        System.out.println("Launching Minecraft " + mcver);
        
        MinecraftAccount acc = new MinecraftAccount();
        acc.selectedVersion = mcver;
        JMinecraftVersionList.Version version = Tools.getVersionInfo(mcver);
        
        try {
            Tools.launchMinecraft(acc, version);
        } catch (Throwable th) {
            Tools.showError(th);
        }
    }
}
