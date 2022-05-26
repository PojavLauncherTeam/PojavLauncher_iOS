package net.kdt.pojavlaunch;

import java.io.*;
import java.util.*;
import java.util.concurrent.*;

import org.lwjgl.glfw.CallbackBridge;
import org.lwjgl.glfw.GLFW;

import net.kdt.pojavlaunch.uikit.*;
import net.kdt.pojavlaunch.utils.*;
import net.kdt.pojavlaunch.value.*;

public class PLaunchApp {
    private static float currProgress, maxProgress;

    public static void main(String[] args) throws Throwable {
        try {
            sun.font.FontUtilities.isLinux = true;
        } catch (Throwable th) {
            // Not on JRE8, ignore exception
        }

        Thread.currentThread().setUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() {

            public void uncaughtException(Thread t, Throwable th) {
                Tools.showError(th);
                // Block this thread from exiting
                while (true) {}
            }
        });

        System.setProperty("cacio.managed.screensize", args[2]);

        if (args[0].equals(".LaunchJAR")) {
            UIKit.callback_JavaGUIViewController_launchJarFile(args[1]);
        } else {
            launchMinecraft(args);
        }
    }

    public static void launchMinecraft(String[] args) throws Throwable {
        String[] size = args[2].split("x");

        MCOptionUtils.load();
        MCOptionUtils.set("overrideWidth", size[0]);
        MCOptionUtils.set("overrideHeight", size[1]);
        MCOptionUtils.save();

        System.setProperty("org.lwjgl.opengl.libname", System.getenv("POJAV_RENDERER"));

        Tools.mGLFWWindowWidth = Integer.parseInt(size[0]);
        Tools.mGLFWWindowHeight = Integer.parseInt(size[1]);
        //GLFW.internalChangeMonitorSize(width, height);
        //CallbackBridge.mouseX = width / 2;
        //CallbackBridge.mouseY = height / 2;

        MinecraftAccount account = MinecraftAccount.load(args[0]);
        JMinecraftVersionList.Version version = Tools.getVersionInfo(args[1]);
        System.out.println("Launching Minecraft " + version.id);
        String configPath;
        if (version.logging != null) {
            if (version.logging.client.file.id.equals("client-1.12.xml")) {
                configPath = Tools.DIR_BUNDLE + "/log4j-rce-patch-1.12.xml";
            } else if (version.logging.client.file.id.equals("client-1.7.xml")) {
                configPath = Tools.DIR_BUNDLE + "/log4j-rce-patch-1.7.xml";
            } else {
                configPath = Tools.DIR_GAME_NEW + "/" + version.logging.client.file.id;
            }
            System.setProperty("log4j.configurationFile", configPath);
        }

        Tools.launchMinecraft(account, version);
    }

// TODO
/*
    public static void downloadAssetMapped(String assetName, JAssetInfo asset, File resDir) throws IOException {
        String assetPath = asset.hash.substring(0, 2) + "/" + asset.hash;
        File outFile = new File(resDir,"/"+assetName);
        if (!outFile.exists()) {
            UIKit.updateProgressSafe(currProgress / maxProgress, "Downloading " + assetName);
            DownloadUtils.downloadFile(MINECRAFT_RES + assetPath, outFile);
        }
    }
    */
}
