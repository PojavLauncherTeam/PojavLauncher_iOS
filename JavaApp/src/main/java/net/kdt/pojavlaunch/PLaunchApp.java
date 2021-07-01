package net.kdt.pojavlaunch;

import java.io.*;
import java.util.*;
import java.util.concurrent.*;

import org.lwjgl.glfw.CallbackBridge;

import net.kdt.pojavlaunch.prefs.*;
import net.kdt.pojavlaunch.uikit.*;
import net.kdt.pojavlaunch.utils.*;
import net.kdt.pojavlaunch.value.*;

public class PLaunchApp {
    private static float currProgress, maxProgress;

    public static volatile JMinecraftVersionList.Version mVersion;
    public static boolean mIsAssetsProcessing = false;

    public static void main(String[] args) throws Throwable {
        // User might remove the minecraft folder, this can cause crashes, safety re-create it
        try {
            File mcDir = new File("/var/mobile/Documents/minecraft");
            mcDir.mkdirs();
            new File(Tools.DIR_ACCOUNT_NEW).mkdirs();
            if (!new File(mcDir, "config_ver.txt").exists()) {
                Tools.write(mcDir.getAbsolutePath() + "/config_ver.txt", "1.16.5");
                
                Tools.write(mcDir.getAbsolutePath() + "/launcher_profiles.json",
                  Tools.read(Tools.DIR_DATA + "/launcher_profiles.json"));
            }

            LauncherPreferences.loadPreferences();
        } catch (IOException e) {
            e.printStackTrace();
        }

        if (args[0].startsWith("/Applications/")) {
            System.out.println("We are on java now! Starting UI...");
            UIKit.launchUI(args);
        } else {
            return;
        }
    }

    // Called from SurfaceViewController
    public static void launchMinecraft() {
        System.out.println("Saving GLES context");
        JREUtils.saveGLContext();

        System.out.println("Launching Minecraft " + mVersion.id);
        try {
            Tools.launchMinecraft(AccountJNI.CURRENT_ACCOUNT, mVersion);
        } catch (Throwable th) {
            Tools.showError(th);
        }
    }

    public static void installMinecraft(final String versionPath) {
        new Thread(() -> {

            currProgress = 0;
            maxProgress = 0;

            UIKit.updateProgressSafe(0, "Finding a version");
            String mcver = "1.16.5";

            try {
                mcver = Tools.read(Tools.DIR_GAME_NEW + "/config_ver.txt");
            } catch (IOException e) {
                UIKit.updateProgressSafe(0, "config_ver.txt not found, defaulting to Minecraft 1.16.5");
            }

            AccountJNI.CURRENT_ACCOUNT.selectedVersion = mcver;
            try {
                AccountJNI.CURRENT_ACCOUNT.save();
            } catch (IOException e) {
                e.printStackTrace();
            }
            UIKit.updateProgressSafe(0, "Selected Minecraft version: " + mcver);

            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {}

            new File(Tools.DIR_HOME_VERSION + "/" + mcver).mkdirs();

            JMinecraftVersionList.Version verInfo = null;

            try {
                final String downVName = "/" + mcver + "/" + mcver;
                String minecraftMainJar = Tools.DIR_HOME_VERSION + downVName + ".jar";
                String verJsonDir = Tools.DIR_HOME_VERSION + downVName + ".json";

                JAssets assets = null;

                if (versionPath.startsWith("http") && !new File(verJsonDir).exists()) {
                    UIKit.updateProgressSafe(0, "Downloading " + mcver + ".json");
                    Tools.downloadFile(versionPath, verJsonDir);
                }

                mVersion = verInfo = Tools.getVersionInfo(mcver);
                try {
                    UIKit.updateProgressSafe(0, "Downloading " + mcver + ".json assets info");
                    assets = downloadIndex(verInfo.assets, new File(Tools.ASSETS_PATH, "indexes/" + verInfo.assets + ".json"));
                } catch (IOException e) {
                    UIKit.updateProgressSafe(0, "Error: " + e.getMessage());
                    e.printStackTrace();
                }

                maxProgress = verInfo.libraries.length + 1 + (assets == null ? 0 : assets.objects.size());

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

                            if (libItem.downloads == null || libItem.downloads.artifact == null) {
                                MinecraftLibraryArtifact artifact = new MinecraftLibraryArtifact();
                                artifact.url = (libItem.url == null ? "https://libraries.minecraft.net/" : libItem.url) + libArtifact;
                                libItem.downloads = new DependentLibrary.LibraryDownloads(artifact);
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

                if (assets != null) {
                    mIsAssetsProcessing = true;
                    downloadAssets(assets, verInfo.assets, assets.map_to_resources ? new File(Tools.OBSOLETE_RESOURCES_PATH) : new File(Tools.ASSETS_PATH));
                }

                // TODO download assets

            } catch (IOException e) {
                UIKit.updateProgressSafe(currProgress / maxProgress, "Download error, skipping");
                e.printStackTrace();
            }

            UIKit.launchMinecraftSurface(mVersion.arguments != null);

        }).start();
    }

    private static int downloaded = 0;
    public static void downloadAssets(final JAssets assets, String assetsVersion, final File outputDir) throws IOException {
        LinkedBlockingQueue<Runnable> workQueue = new LinkedBlockingQueue<>();
        final ThreadPoolExecutor executor = new ThreadPoolExecutor(50, 50, 500, TimeUnit.MILLISECONDS, workQueue);

        File hasDownloadedFile = new File(outputDir, "downloaded/" + assetsVersion + ".downloaded");
        if (!hasDownloadedFile.exists()) {
            System.out.println("Assets begin time: " + System.currentTimeMillis());
            Map<String, JAssetInfo> assetsObjects = assets.objects;
            File objectsDir = new File(outputDir, "objects");
            for (JAssetInfo asset : assetsObjects.values()) {
                executor.execute(() -> {
                mIsAssetsProcessing &= !UIKit.updateProgressSafe(currProgress / maxProgress, "Downloading " + assetsObjects.keySet().toArray(new String[0])[downloaded]);

                try {
                    if(!assets.map_to_resources) downloadAsset(asset, objectsDir);
                    else downloadAssetMapped(asset,(assetsObjects.keySet().toArray(new String[0])[downloaded]),outputDir);
                } catch (IOException e) {
                    e.printStackTrace();
                    mIsAssetsProcessing = false;
                }
                currProgress++;
                downloaded++;
                
                });
            }
            executor.shutdown();
            try {
                while ((!executor.awaitTermination(250, TimeUnit.MILLISECONDS)) && mIsAssetsProcessing) {}
                executor.shutdownNow();
                while (!executor.awaitTermination(250, TimeUnit.MILLISECONDS)) {}
                System.out.println("Fully shut down!");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println("Assets end time: " + System.currentTimeMillis());
        }
    }


    public static final String MINECRAFT_RES = "https://resources.download.minecraft.net/";

    public static JAssets downloadIndex(String versionName, File output) throws IOException {
        if (!output.exists()) {
            output.getParentFile().mkdirs();
            DownloadUtils.downloadFile(mVersion.assetIndex != null ? mVersion.assetIndex.url : "https://s3.amazonaws.com/Minecraft.Download/indexes/" + versionName + ".json", output);
        }

        return Tools.GLOBAL_GSON.fromJson(Tools.read(output.getAbsolutePath()), JAssets.class);
    }

    public static void downloadAsset(JAssetInfo asset, File objectsDir) throws IOException {
        String assetPath = asset.hash.substring(0, 2) + "/" + asset.hash;
        File outFile = new File(objectsDir, assetPath);
        if (!outFile.exists()) {
            DownloadUtils.downloadFile(MINECRAFT_RES + assetPath, outFile);
        }
    }
    public static void downloadAssetMapped(JAssetInfo asset, String assetName, File resDir) throws IOException {
        String assetPath = asset.hash.substring(0, 2) + "/" + asset.hash;
        File outFile = new File(resDir,"/"+assetName);
        if (!outFile.exists()) {
            DownloadUtils.downloadFile(MINECRAFT_RES + assetPath, outFile);
        }
    }
}
