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
    public static JMinecraftVersionList mVersionList;
    public static void main(String[] args) throws Throwable {
        if (args[0].startsWith("/Applications/")) {
            System.out.println("We are on java now! Starting UI...");
            org.lwjgl.glfw.CallbackBridge.nativeLaunchUI(args);
        } else {
            launchMinecraft();
        }

        LauncherPreferences.loadPreferences();
    }
    
    public static void launchMinecraft() throws Throwable {
        System.out.println("Saving GLES context");
        JREUtils.saveGLContext();
    
        // Start Minecraft there!
        System.out.println("Finding a version");
        String mcver = "1.13";
        
        try {
            mcver = Tools.read(Tools.DIR_GAME_NEW + "/config_ver.txt");
        } catch (IOException e) {
            System.out.println("config_ver.txt not found, defaulting to Minecraft 1.13");
        }
        
        MinecraftAccount acc = new MinecraftAccount();
        acc.selectedVersion = mcver;
        JMinecraftVersionList.Version verInfo = findVersion(mcver);
        
        try {
            final String downVName = "/" + mcver + "/" + mcver;
            String minecraftMainJar = Tools.DIR_HOME_VERSION + downVName + ".jar";
            String verJsonDir = Tools.DIR_HOME_VERSION + downVName + ".json";
            
            System.out.println("Downloading version list");
            mVersionList = Tools.GLOBAL_GSON.fromJson(DownloadUtils.downloadString("https://launchermeta.mojang.com/mc/game/version_manifest.json"), JMinecraftVersionList.class);
            
            if (verInfo.url != null && !new File(verJsonDir).exists()) {
                System.out.println("Downloading " + mcver + ".json");
                Tools.downloadFile(verInfo.url, verJsonDir);
            }
            
            verInfo = Tools.getVersionInfo(mcver);
            
            File outLib;
            String libPathURL;
                
            for (final DependentLibrary libItem : verInfo.libraries) {
                if (
                    libItem.name.startsWith("net.java.jinput") ||
                    libItem.name.startsWith("org.lwjgl")
                ) { // Black list
                    System.out.println("Ignored " + libItem.name);
                    // Thread.sleep(100);
                } else {
                    String[] libInfo = libItem.name.split(":");
                    String libArtifact = Tools.artifactToPath(libInfo[0], libInfo[1], libInfo[2]);
                    outLib = new File(Tools.DIR_HOME_LIBRARY + "/" + libArtifact);
                    outLib.getParentFile().mkdirs();

                    if (!outLib.exists()) {
                        System.out.println("Downloading " + libItem.name);

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
                        /*
                            if (!skipIfFailed) {
                                throw th;
                            } else {
                                th.printStackTrace();
                                publishProgress("0", th.getMessage());
                            }
                        */
                        
                            System.out.println("Download failed");
                        }
                    }
                }
            }
            
            System.out.println("Downloading " + mcver + ".jar");
            File minecraftMainFile = new File(minecraftMainJar);
            if (!minecraftMainFile.exists() || minecraftMainFile.length() == 0l) {
                Tools.downloadFile(verInfo.downloads.values().toArray(new MinecraftClientInfo[0])[0].url, minecraftMainJar);
            }
        } catch (IOException e) {
            System.out.println("Download error, skipping");
        }
        
        System.out.println("Launching Minecraft " + mcver);
        Tools.launchMinecraft(acc, verInfo);
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
