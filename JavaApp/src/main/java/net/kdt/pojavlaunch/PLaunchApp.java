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

    public static volatile JMinecraftVersionList.Version mVersion;
    public static boolean mIsAssetsProcessing = false;

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

    public static String getSelectedVersion() {
        try {
            String plistContent = Tools.read(Tools.DIR_APP_DATA + "/launcher_preferences.plist");
            plistContent = plistContent.substring(plistContent.indexOf("<key>selected_version</key>") + 27);
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
            if (AccountJNI.CURRENT_ACCOUNT == null) {
                AccountJNI.CURRENT_ACCOUNT = MinecraftAccount.load(System.getProperty("pojav.selectedAccount"));
                mVersion = Tools.getVersionInfo(getSelectedVersion());
            }
            System.out.println("Launching Minecraft " + mVersion.id);
            String configPath;
            if (mVersion.logging != null) {
                if (mVersion.logging.client.file.id.equals("client-1.12.xml")) {
                    configPath = Tools.DIR_BUNDLE + "/log4j-rce-patch-1.12.xml";
                } else {
                    configPath = Tools.DIR_GAME_NEW + "/" + mVersion.logging.client.file.id;
                }
                System.setProperty("log4j.configurationFile", configPath);
            }
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
            String mcver = getSelectedVersion();

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

            try {
                final String downVName = "/" + mcver + "/" + mcver;
                String minecraftMainJar = Tools.DIR_HOME_VERSION + downVName + ".jar";
                String verJsonDir = Tools.DIR_HOME_VERSION + downVName + ".json";

                JAssets assets = null;

                if (AccountJNI.CURRENT_ACCOUNT.accessToken.equals("0")) {
                    if (!new File(verJsonDir).exists()) {
                        // Local account: disallow install new version
                        UIKit.showError("Error", "Minecraft can't be legally installed when logged in with a local account. Please switch to an online account to continue.", false);
                        return;
                    } else {
                        // Local account: jump to launch Minecraft, not download anything
                        mVersion = Tools.getVersionInfo(mcver);
                        UIKit.launchMinecraftSurface(mVersion.arguments != null);
                        return;
                    }
                } else if (versionPath.startsWith("http") && !new File(verJsonDir).exists()) {
                    UIKit.updateProgressSafe(0, "Downloading " + mcver + ".json");
                    Tools.downloadFile(versionPath, verJsonDir);
                }

                mVersion = Tools.getVersionInfo(mcver);
                try {
                    UIKit.updateProgressSafe(0, "Downloading " + mcver + ".json assets info");
                    assets = downloadIndex(mVersion.assets, new File(Tools.ASSETS_PATH, "indexes/" + mVersion.assets + ".json"));
                } catch (IOException e) {
                    UIKit.updateProgressSafe(0, "Error: " + e.getMessage());
                    e.printStackTrace();
                }

                if (mVersion.logging != null && !mVersion.logging.client.file.id.equals("client-1.12.xml")) {
                    UIKit.updateProgressSafe(0, "Downloading " + mVersion.logging.client.file.id);
                    String configPath = Tools.DIR_GAME_NEW + "/" + mVersion.logging.client.file.id;
                    Tools.downloadFile(mVersion.logging.client.file.url, configPath);
                }

                maxProgress = mVersion.libraries.length + 1 + (assets == null ? 0 : assets.objects.size());

                File outLib;
                String libPathURL;

                Tools.preProcessLibraries(mVersion.libraries);
                for (final DependentLibrary libItem : mVersion.libraries) {
                    if (libItem._skip) {
                        currProgress++;
                        UIKit.updateProgressSafe(currProgress / maxProgress, "Skipped " + libItem.name);
                        // Thread.sleep(100);
                        
                        String[] libInfo = libItem.name.split(":");
                        String libArtifact = Tools.artifactToPath(libInfo[0], libInfo[1], libInfo[2]);
                        outLib = new File(Tools.DIR_HOME_LIBRARY + "/" + libArtifact);
                        outLib.delete();
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
                File minecraftMainFile = new File(minecraftMainJar);
                if (!minecraftMainFile.exists() || minecraftMainFile.length() == 0l) {
                    UIKit.updateProgressSafe(currProgress / maxProgress, "Downloading " + mcver + ".jar");
                    Tools.downloadFile(mVersion.downloads.values().toArray(new MinecraftClientInfo[0])[0].url, minecraftMainJar);
                }

                if (assets != null) {
                    mIsAssetsProcessing = true;
                    downloadAssets(assets, mVersion.assets, assets.map_to_resources ? new File(Tools.OBSOLETE_RESOURCES_PATH) : new File(Tools.ASSETS_PATH));
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
        final ThreadPoolExecutor executor = new ThreadPoolExecutor(10, 10, 500, TimeUnit.MILLISECONDS, workQueue);

        File hasDownloadedFile = new File(outputDir, "downloaded/" + assetsVersion + ".downloaded");
        if (!hasDownloadedFile.exists()) {
            System.out.println("Assets begin time: " + System.currentTimeMillis());
            Map<String, JAssetInfo> assetsObjects = assets.objects;
            File objectsDir = new File(outputDir, "objects");
            for (JAssetInfo asset : assetsObjects.values()) {
                executor.execute(() -> {
                try {
                    String assetName = assetsObjects.keySet().toArray(new String[0])[downloaded];
                    if(!assets.map_to_resources) downloadAsset(assetName, asset, objectsDir);
                    else downloadAssetMapped(assetName, asset, outputDir);
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

    public static void downloadAsset(String assetName, JAssetInfo asset, File objectsDir) throws IOException {
        String assetPath = asset.hash.substring(0, 2) + "/" + asset.hash;
        File outFile = new File(objectsDir, assetPath);
        if (!outFile.exists()) {
            UIKit.updateProgressSafe(currProgress / maxProgress, "Downloading " + assetName);
            DownloadUtils.downloadFile(MINECRAFT_RES + assetPath, outFile);
        }
    }
    public static void downloadAssetMapped(String assetName, JAssetInfo asset, File resDir) throws IOException {
        String assetPath = asset.hash.substring(0, 2) + "/" + asset.hash;
        File outFile = new File(resDir,"/"+assetName);
        if (!outFile.exists()) {
            UIKit.updateProgressSafe(currProgress / maxProgress, "Downloading " + assetName);
            DownloadUtils.downloadFile(MINECRAFT_RES + assetPath, outFile);
        }
    }
}
