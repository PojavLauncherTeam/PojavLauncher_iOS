package net.kdt.pojavlaunch;

import java.io.*;
import java.util.Arrays;

import javafx.application.Application;

import org.lwjgl.glfw.CallbackBridge;

import net.kdt.pojavlaunch.prefs.*;
import net.kdt.pojavlaunch.uikit.*;
import net.kdt.pojavlaunch.utils.*;
import net.kdt.pojavlaunch.value.*;

public class PLaunchApp {
    public static JMinecraftVersionList mVersionList;
    public static MinecraftAccount mAccount;
    public static JMinecraftVersionList.Version mVersion;
    public static void main(String[] args) throws Throwable {
        // System.setProperty("os.name", "iOS");
/*
        System.setProperty("javafx.verbose", "true");
        System.setProperty("javafx.platform", "ios");
        System.setProperty("glass.platform", "ios");
        System.setProperty("jfxmedia.platforms", "IOSPlatform");
        System.setProperty("com.sun.javafx.isEmbedded", "true");

        System.setProperty("prism.verbose", "true");
        System.setProperty("prism.allowhidpi", "true");
        System.setProperty("prism.mintexturesize", "16");
        System.setProperty("prism.static.libraries", "false");
        System.setProperty("prism.useNativeIIO", "false");
*/
        
        if (args[0].startsWith("/Applications/")) {
            System.out.println("We are on java now! Starting UI...");
            UIKit.launchUI(args);
        } else {
            // Test on cmdline
            launchMinecraft();
        }

        LauncherPreferences.loadPreferences();
    }

    public static void installMinecraft() {
        new Thread(() -> {
        
        int currProgress = 0;
        float totalProgress = 0;
        
        UIKit.updateProgressSafe(0, "Finding a version");
        String mcver = "1.16.5";
        
        try {
            mcver = Tools.read(Tools.DIR_GAME_NEW + "/config_ver.txt");
        } catch (IOException e) {
            UIKit.updateProgressSafe(currProgress, "config_ver.txt not found, defaulting to Minecraft 1.16.5");
        }
        
        UIKit.updateProgressSafe(0, "Selected Minecraft version: " + mcver);
        
        Thread.sleep(1000);
        
        // dummy account
        MinecraftAccount acc = new MinecraftAccount();
        acc.selectedVersion = mcver;
        
        new File(Tools.DIR_HOME_VERSION + "/" + mcver).mkdirs();
        
        JMinecraftVersionList.Version verInfo = null;
        
        try {
            final String downVName = "/" + mcver + "/" + mcver;
            String minecraftMainJar = Tools.DIR_HOME_VERSION + downVName + ".jar";
            String verJsonDir = Tools.DIR_HOME_VERSION + downVName + ".json";
            
            UIKit.updateProgressSafe(0, "Downloading version list");
            mVersionList = Tools.GLOBAL_GSON.fromJson(DownloadUtils.downloadString("https://launchermeta.mojang.com/mc/game/version_manifest.json"), JMinecraftVersionList.class);
            
            verInfo = findVersion(mcver);
            if (verInfo.url != null && !new File(verJsonDir).exists()) {
                UIKit.updateProgressSafe(0, "Downloading " + mcver + ".json");
                Tools.downloadFile(verInfo.url, verJsonDir);
            }
            
            verInfo = Tools.getVersionInfo(mcver);
            totalProgress = verInfo.libraries.length + 1; // + verInfo.assetslength
            
            File outLib;
            String libPathURL;
                
            for (final DependentLibrary libItem : verInfo.libraries) {
                if (
                    libItem.name.startsWith("net.java.jinput") ||
                    libItem.name.startsWith("org.lwjgl")
                ) { // Black list
                    currProgress++;
                    UIKit.updateProgressSafe(currProgress / maxProgress, "Ignored " + libItem.name);
                    // Thread.sleep(100);
                } else {
                    String[] libInfo = libItem.name.split(":");
                    String libArtifact = Tools.artifactToPath(libInfo[0], libInfo[1], libInfo[2]);
                    outLib = new File(Tools.DIR_HOME_LIBRARY + "/" + libArtifact);
                    outLib.getParentFile().mkdirs();

                    if (!outLib.exists()) {
                        currProgress++;
                    UIKit.updateProgressSafe(currProgress / maxProgress, "Downloading " + libItem.name);

                        boolean skipIfFailed = false;

                        if (libItem.downloads == null || libItem.downloads.artifact == null) {
                            MinecraftLibraryArtifact artifact = new MinecraftLibraryArtifact();
                            artifact.url = (libItem.url == null ? "https://libraries.minecraft.net/" : libItem.url) + libArtifact;
                            libItem.downloads = new DependentLibrary.LibraryDownloads(artifact);

                            skipIfFailed = true;
                        }
                        try {
                            libPathURL = libItem.downloads.artifact.url;
                            Tools.downloadFile(libPathURL, outLib.getAbsolutePath());
                        } catch (Throwable th) {
                            th.printStackTrace();
                            UIKit.updateProgressSafe(currProgress / maxProgress, "Download failed");
                        }
                    }
                }
            }
            
            currProgress++;
            UIKit.updateProgressSafe(currProgress / maxProgress, "Downloading " + mcver + ".jar");
            File minecraftMainFile = new File(minecraftMainJar);
            if (!minecraftMainFile.exists() || minecraftMainFile.length() == 0l) {
                Tools.downloadFile(verInfo.downloads.values().toArray(new MinecraftClientInfo[0])[0].url, minecraftMainJar);
            }
            
            // TODO download assets
            
        } catch (IOException e) {
            UIKit.updateProgressSafe(currProgress / maxProgress, "Download error, skipping");
            e.printStackTrace();
        }
        
        mAccount = acc;
        mVersion = verInfo;
        
        UIKit.runOnUIThread(() -> {
            UIKit.launchMinecraftSurface();
        });
        
        }).start();
    }
    
    // Called from SurfaceViewController
    public static void launchMinecraft() {
        System.out.println("Saving GLES context");
        JREUtils.saveGLContext();
        
        System.out.println("Launching Minecraft " + mVersion.id);
        try {
            Tools.launchMinecraft(mAccount, mVersion);
        } catch (Throwable th) {
            throw new RuntimeException(th);
        }
    }
    
    private static JMinecraftVersionList.Version findVersion(String version) {
        if (mVersionList != null) {
            for (JMinecraftVersionList.Version valueVer: mVersionList.versions) {
                if (valueVer.id.equals(version)) {
                    return valueVer;
                }
            }
        }

        // Custom version, inherits from base.
        return Tools.getVersionInfo(version);
    }
}
