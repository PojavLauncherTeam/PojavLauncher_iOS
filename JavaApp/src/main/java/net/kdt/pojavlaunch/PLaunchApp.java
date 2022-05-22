package net.kdt.pojavlaunch;

import java.io.*;
import java.util.*;
import java.util.concurrent.*;

import org.lwjgl.glfw.CallbackBridge;

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

        // User might remove the minecraft folder, this can cause crashes, safety re-create it
        try {
            File mcDir = new File(Tools.DIR_GAME_NEW);
            mcDir.mkdirs();
            new File(Tools.DIR_ACCOUNT_NEW).mkdirs();
            if (!new File(mcDir.getAbsolutePath() + "/launcher_profiles.json").exists()) {
                Tools.write(mcDir.getAbsolutePath() + "/launcher_profiles.json",
                  Tools.read(Tools.DIR_BUNDLE + "/launcher_profiles.json"));
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        System.out.println("We are on java now! Starting UI...");
        UIKit.launchUI();
    }

    public static String getStringFromPref(String pref) {
        try {
            String plistContent = Tools.read(Tools.DIR_APP_DATA + "/launcher_preferences.plist");
            plistContent = plistContent.substring(plistContent.indexOf("<key>" + pref + "</key>") + pref.length() + 11);
            return plistContent.substring(
                    plistContent.indexOf("<string>") + 8,
                plistContent.indexOf("</string>"));
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }

    // Called from SurfaceViewController
    public static void launchMinecraft() {
        try {
            MinecraftAccount account = MinecraftAccount.load(getStringFromPref("internal_selected_account"));
            JMinecraftVersionList.Version version = Tools.getVersionInfo(getStringFromPref("selected_version"));
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
        } catch (Throwable th) {
            Tools.showError(th);
        }
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
