package net.kdt.pojavlaunch;

import android.util.ArrayMap;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileFilter;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;
import net.kdt.pojavlaunch.prefs.LauncherPreferences;
import net.kdt.pojavlaunch.uikit.UIKit;
import net.kdt.pojavlaunch.utils.DownloadUtils;
import net.kdt.pojavlaunch.utils.JSONUtils;
import net.kdt.pojavlaunch.value.DependentLibrary;
import net.kdt.pojavlaunch.value.MinecraftAccount;
import org.lwjgl.glfw.GLFW;
/*
import org.robovm.apple.foundation.*;
import org.robovm.apple.uikit.*;
import org.robovm.pods.dialog.*;
import org.robovm.pods.*;
*/
public final class Tools
{
    public static final boolean ENABLE_DEV_FEATURES = true; // BuildConfig.DEBUG;

    public static String APP_NAME = "null";
    
    public static final Gson GLOBAL_GSON = new GsonBuilder().setPrettyPrinting().create();
    
    public static final String URL_HOME = "https://pojavlauncherteam.github.io/PojavLauncher";
    public static String DIR_DATA = "/Applications/PojavLauncher.app";
    public static String CURRENT_ARCHITECTURE;

    public static final String DIR_GAME_HOME = "/var/mobile/Documents";
    public static final String DIR_GAME_NEW = DIR_GAME_HOME + "/minecraft";
    
    public static final String DIR_APP_DATA = DIR_GAME_HOME + "/.pojavlauncher";
    public static final String DIR_ACCOUNT_NEW = DIR_APP_DATA + "/accounts";
    
    // New since 3.0.0
    public static String DIR_HOME_JRE = "/usr/lib/jvm/java-16-openjdk";
    public static String DIRNAME_HOME_JRE = "lib";

    // New since 2.4.2
    public static final String DIR_HOME_VERSION = DIR_GAME_NEW + "/versions";
    public static final String DIR_HOME_LIBRARY = DIR_GAME_NEW + "/libraries";

    public static final String DIR_HOME_CRASH = DIR_GAME_NEW + "/crash-reports";

    public static final String ASSETS_PATH = DIR_GAME_NEW + "/assets";
    public static final String OBSOLETE_RESOURCES_PATH=DIR_GAME_NEW + "/resources";
    public static final String CTRLMAP_PATH = DIR_GAME_NEW + "/controlmap";
    public static final String CTRLDEF_FILE = DIR_GAME_NEW + "/controlmap/default.json";
    
    public static final String LIBNAME_OPTIFINE = "optifine:OptiFine";

    public static void launchMinecraft(MinecraftAccount profile, final JMinecraftVersionList.Version versionInfo) throws Throwable {
        String[] launchArgs = getMinecraftArgs(profile, versionInfo);

        // ctx.appendlnToLog("Minecraft Args: " + Arrays.toString(launchArgs));

        final String launchClassPath = generateLaunchClassPath(profile.selectedVersion);

        List<String> javaArgList = new ArrayList<String>();
        
        javaArgList.add("-cp");
        javaArgList.add(launchClassPath);

        javaArgList.add(versionInfo.mainClass);
        javaArgList.addAll(Arrays.asList(launchArgs));
        
        // Debug
/*
        BufferedWriter bw = new BufferedWriter(new FileWriter(new File(Tools.DIR_GAME_HOME, "currargs_generated.txt")));
        for (String s : javaArgList) {
            bw.write(s, 0, s.length());
            bw.write(" ", 0, 1);
        }
        bw.close();
*/

/*
        final List<URL> urlList = new ArrayList<>();
        for (String s : launchClassPath.split(":")) {
            if (!s.isEmpty()) {
                urlList.add(new File(s).toURI().toURL());
            }
        }
*/
        
        new Thread(() -> { try {
            System.out.println("Args init finished. Now starting game");
        
            // URLClassLoader loader = new URLClassLoader(urlList.toArray(new URL[0]), ClassLoader.getSystemClassLoader());
            
            PojavClassLoader loader = (PojavClassLoader) ClassLoader.getSystemClassLoader();
            
            for (String s : launchClassPath.split(":")) {
                if (!s.isEmpty()) {
                    loader.addURL(new File(s).toURI().toURL());
                }
            }
            
            Class<?> clazz = loader.loadClass(versionInfo.mainClass);
            Method method = clazz.getMethod("main", String[].class);
            method.invoke(null, new Object[]{launchArgs});
        
            System.out.println("It went past main(). Should not reach here!");
        } catch (Throwable th) {
            showError(th);
        }
        
        }).start();
        
        // JREUtils.launchJavaVM(javaArgList);
    }

    public static String[] getMinecraftArgs(MinecraftAccount profile, JMinecraftVersionList.Version versionInfo) {
        String username = profile.username;
        String versionName = versionInfo.id;
        if (versionInfo.inheritsFrom != null) {
            versionName = versionInfo.inheritsFrom;
        }
        
        String userType = "mojang";

        File gameDir = new File(Tools.DIR_GAME_NEW);
        gameDir.mkdirs();

        Map<String, String> varArgMap = new ArrayMap<String, String>();
        varArgMap.put("auth_access_token", profile.accessToken);
        varArgMap.put("auth_player_name", username);
        varArgMap.put("auth_uuid", profile.profileId);
        varArgMap.put("assets_root", Tools.ASSETS_PATH);
        varArgMap.put("assets_index_name", versionInfo.assets);
        varArgMap.put("game_assets", Tools.ASSETS_PATH);
        varArgMap.put("game_directory", gameDir.getAbsolutePath());
        varArgMap.put("user_properties", "{}");
        varArgMap.put("user_type", userType);
        varArgMap.put("version_name", versionName);
        varArgMap.put("version_type", versionInfo.type);

        List<String> minecraftArgs = new ArrayList<String>();
        if (versionInfo.arguments != null) {
            // Support Minecraft 1.13+
            for (Object arg : versionInfo.arguments.game) {
                if (arg instanceof String) {
                    minecraftArgs.add((String) arg);
                } else {
                    /*
                    JMinecraftVersionList.Arguments.ArgValue argv = (JMinecraftVersionList.Arguments.ArgValue) arg;
                    if (argv.values != null) {
                        minecraftArgs.add(argv.values[0]);
                    } else {
                        
                         for (JMinecraftVersionList.Arguments.ArgValue.ArgRules rule : arg.rules) {
                         // rule.action = allow
                         // TODO implement this
                         }
                         
                    }
                    */
                }
            }
        }
        minecraftArgs.add("--width");
        minecraftArgs.add(Integer.toString(GLFW.mGLFWWindowWidth));
        minecraftArgs.add("--height");
        minecraftArgs.add(Integer.toString(GLFW.mGLFWWindowHeight));
        minecraftArgs.add("--fullscreenWidth");
        minecraftArgs.add(Integer.toString(GLFW.mGLFWWindowWidth));
        minecraftArgs.add("--fullscreenHeight");
        minecraftArgs.add(Integer.toString(GLFW.mGLFWWindowHeight));
        
        String[] argsFromJson = JSONUtils.insertJSONValueList(
            splitAndFilterEmpty(
                versionInfo.minecraftArguments == null ?
                fromStringArray(minecraftArgs.toArray(new String[0])):
                versionInfo.minecraftArguments
            ), varArgMap
        );
        // Tools.dialogOnUiThread(this, "Result args", Arrays.asList(argsFromJson).toString());
        return argsFromJson;
    }

    public static String fromStringArray(String[] strArr) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < strArr.length; i++) {
            if (i > 0) builder.append(" ");
            builder.append(strArr[i]);
        }

        return builder.toString();
    }

    private static String[] splitAndFilterEmpty(String argStr) {
        List<String> strList = new ArrayList<String>();
        for (String arg : argStr.split(" ")) {
            if (!arg.isEmpty()) {
                strList.add(arg);
            }
        }
        strList.add("--fullscreen");
        return strList.toArray(new String[0]);
    }

    public static String artifactToPath(String group, String artifact, String version) {
        return group.replaceAll("\\.", "/") + "/" + artifact + "/" + version + "/" + artifact + "-" + version + ".jar";
    }

    public static String getPatchedFile(String version) {
        return DIR_HOME_VERSION + "/" + version + "/" + version + ".jar";
    }
/*
    private static String getLWJGL3ClassPath() {
        StringBuilder libStr = new StringBuilder();
        File lwjgl3Folder = new File(Tools.DIR_GAME_NEW, "lwjgl3");
        if (/* info.arguments != null && @lwjgl3Folder.exists()) {
            for (File file: lwjgl3Folder.listFiles()) {
                if (file.getName().endsWith(".jar")) {
                    libStr.append(file.getAbsolutePath() + ":");
                }
            }
            // Remove the ':' at the end
            libStr.setLength(libStr.length() - 1);
        }
        return libStr.toString();
    }
*/
    private static boolean isClientFirst = false;
    public static String generateLaunchClassPath(String version) {
        StringBuilder libStr = new StringBuilder(); //versnDir + "/" + version + "/" + version + ".jar:";

        JMinecraftVersionList.Version info = getVersionInfo(version);
        String[] classpath = generateLibClasspath(info);

        // Debug: LWJGL 3 override
        // File lwjgl2Folder = new File(Tools.MAIN_PATH, "lwjgl2");

        /*
         File lwjgl3Folder = new File(Tools.MAIN_PATH, "lwjgl3");
         if (lwjgl3Folder.exists()) {
         for (File file: lwjgl3Folder.listFiles()) {
         if (file.getName().endsWith(".jar")) {
         libStr.append(file.getAbsolutePath() + ":");
         }
         }
         } else if (lwjgl2Folder.exists()) {
         for (File file: lwjgl2Folder.listFiles()) {
         if (file.getName().endsWith(".jar")) {
         libStr.append(file.getAbsolutePath() + ":");
         }
         }
         }
         */

        if (isClientFirst) {
            libStr.append(getPatchedFile(version));
        }
        for (String perJar : classpath) {
            if (!new File(perJar).exists()) {
                System.out.println("Ignored non-exists file: " + perJar);
                continue;
            }
            libStr.append((isClientFirst ? ":" : "") + perJar + (!isClientFirst ? ":" : ""));
        }
        if (!isClientFirst) {
            libStr.append(getPatchedFile(version));
        }

        return libStr.toString();
    }
/*
    public static DisplayMetrics getDisplayMetrics(Activity ctx) {
        DisplayMetrics displayMetrics = new DisplayMetrics();
        ctx.getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);
        return displayMetrics;
    }

    public static void setFullscreen(Activity act) {
        final View decorView = act.getWindow().getDecorView();
        decorView.setOnSystemUiVisibilityChangeListener (new View.OnSystemUiVisibilityChangeListener() {
                @Override
                public void onSystemUiVisibilityChange(int visibility) {
                    if ((visibility & View.SYSTEM_UI_FLAG_FULLSCREEN) == 0) {
                        decorView.setSystemUiVisibility(
                            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);
                    }
                }
            });
    }

    public static DisplayMetrics currentDisplayMetrics;
    public static void updateWindowSize(Activity ctx) {
        currentDisplayMetrics = getDisplayMetrics(ctx);
        CallbackBridge.windowWidth = currentDisplayMetrics.widthPixels;
        CallbackBridge.windowHeight = currentDisplayMetrics.heightPixels;
        
        if (CallbackBridge.windowWidth < CallbackBridge.windowHeight) {
            CallbackBridge.windowWidth = currentDisplayMetrics.heightPixels;
            CallbackBridge.windowHeight = currentDisplayMetrics.widthPixels;
        }
    }

    public static float dpToPx(float dp) {
        // 921600 = 1280 * 720, default scale
        // TODO better way to scaling
        float scaledDp = dp; // / DisplayMetrics.DENSITY_XHIGH * currentDisplayMetrics.densityDpi;
        return (scaledDp * currentDisplayMetrics.density);
    }

    public static void copyAssetFile(Context ctx, String fileName, String output, boolean overwrite) throws IOException {
        copyAssetFile(ctx, fileName, output, new File(fileName).getName(), overwrite);
    }

    public static void copyAssetFile(Context ctx, String fileName, String output, String outputName, boolean overwrite) throws IOException
    {
        File file = new File(output);
        if(!file.exists()) {
            file.mkdirs();
        }
        File file2 = new File(output, outputName);
        if(!file2.exists() || overwrite){
            write(file2.getAbsolutePath(), loadFromAssetToByte(ctx, fileName));
        }
    }

    public static void extractAssetFolder(Activity ctx, String path, String output) throws Exception {
        extractAssetFolder(ctx, path, output, false);
    }

    public static void extractAssetFolder(Activity ctx, String path, String output, boolean overwrite) throws Exception {
        AssetManager assetManager = ctx.getAssets();
        String assets[] = null;
        try {
            assets = assetManager.list(path);
            if (assets.length == 0) {
                Tools.copyAssetFile(ctx, path, output, overwrite);
            } else {
                File dir = new File(output, path);
                if (!dir.exists())
                    dir.mkdirs();
                for (String sub : assets) {
                    extractAssetFolder(ctx, path + "/" + sub, output, overwrite);
                }
            }
        } catch (Exception e) {
            showError(ctx, e);
        }
    }
*/
    public static void showError(Throwable e) {
        showError(e, false);
    }

    public static void showError(final Throwable e, final boolean exitIfOk) {
        showError("Error", e, exitIfOk, false);
    }

    public static void showError(final String title, final Throwable e, final boolean exitIfOk) {
        showError(title, e, exitIfOk, false);
    }

    private static void showError(final String title, final Throwable e, final boolean exitIfOk, final boolean showMore) {
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        e.printStackTrace(pw);
        pw.flush();
        
        System.err.println(sw.toString());
        
        UIKit.showError(title, sw.toString(), exitIfOk);
        
/*
        Platform.getPlatform().runOnUIThread(() -> {
            WindowAlertController alertController = new WindowAlertController(title, sw.toString(), UIAlertControllerStyle.Alert);
            alertController.addAction(new UIAlertAction("OK",
                UIAlertActionStyle.Default, (action) -> {
                    alertController.dismissViewController(true, null);
                    if (exitIfOk) {
                        System.exit(0);
                    }
                })
            );
            alertController.show();
        });
*/
    }
/*
    public static void dialogOnUiThread(final Activity ctx, final CharSequence title, final CharSequence message) {
        ctx.runOnUiThread(new Runnable(){

                @Override
                public void run() {
                    new AlertDialog.Builder(ctx)
                        .setTitle(title)
                        .setMessage(message)
                        .setPositiveButton(android.R.string.ok, null)
                        .show();
                }
            });

    }
*/
    public static void moveInside(String from, String to) {
        File fromFile = new File(from);
        for (File fromInside : fromFile.listFiles()) {
            moveRecursive(fromInside.getAbsolutePath(), to);
        }
        fromFile.delete();
    }

    public static void moveRecursive(String from, String to) {
        moveRecursive(new File(from), new File(to));
    }

    public static void moveRecursive(File from, File to) {
        File toFrom = new File(to, from.getName());
        try {
            if (from.isDirectory()) {
                for (File child : from.listFiles()) {
                    moveRecursive(child, toFrom);
                }
            }
        } finally {
            from.getParentFile().mkdirs();
            from.renameTo(toFrom);
        }
    }
/*
    public static void openURL(Activity act, String url) {
        Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        act.startActivity(browserIntent);
    }
*/
    public static String[] generateLibClasspath(JMinecraftVersionList.Version info) {
        List<String> libDir = new ArrayList<String>();

        for (DependentLibrary libItem: info.libraries) {
            String[] libInfos = libItem.name.split(":");
            libDir.add(Tools.DIR_HOME_LIBRARY + "/" + Tools.artifactToPath(libInfos[0], libInfos[1], libInfos[2]));
        }
        return libDir.toArray(new String[0]);
    }

    public static JMinecraftVersionList.Version getVersionInfo(String versionName) {
        try {
            JMinecraftVersionList.Version customVer = Tools.GLOBAL_GSON.fromJson(read(DIR_HOME_VERSION + "/" + versionName + "/" + versionName + ".json"), JMinecraftVersionList.Version.class);
            for (DependentLibrary lib : customVer.libraries) {
                if (lib.name.startsWith(LIBNAME_OPTIFINE)) {
                    customVer.optifineLib = lib;
                }
            }
            if (customVer.inheritsFrom == null || customVer.inheritsFrom.equals(customVer.id)) {
                return customVer;
            } else {
                JMinecraftVersionList.Version inheritsVer = Tools.GLOBAL_GSON.fromJson(read(DIR_HOME_VERSION + "/" + customVer.inheritsFrom + "/" + customVer.inheritsFrom + ".json"), JMinecraftVersionList.Version.class);
                inheritsVer.inheritsFrom = inheritsVer.id;
                
                insertSafety(inheritsVer, customVer,
                             "assetIndex", "assets", "id",
                             "mainClass", "minecraftArguments",
                             "optifineLib", "releaseTime", "time", "type"
                             );

                List<DependentLibrary> libList = new ArrayList<DependentLibrary>(Arrays.asList(inheritsVer.libraries));
                try {
                    loop_1:
                    for (DependentLibrary lib : customVer.libraries) {
                        String libName = lib.name.substring(0, lib.name.lastIndexOf(":"));
                        for (int i = 0; i < libList.size(); i++) {
                            DependentLibrary libAdded = libList.get(i);
                            String libAddedName = libAdded.name.substring(0, libAdded.name.lastIndexOf(":"));
                            
                            if (libAddedName.equals(libName)) {
                                System.out.println("Library " + libName + ": Replaced version " + 
                                    libAdded.name.substring(libAddedName.length() + 1) + " with " +
                                    lib.name.substring(libName.length() + 1));
                                libList.set(i, lib);
                                continue loop_1;
                            }
                        }

                        libList.add(lib);
                    }
                } finally {
                    inheritsVer.libraries = libList.toArray(new DependentLibrary[0]);
                }

                // Inheriting Minecraft 1.13+ with append custom args
                if (inheritsVer.arguments != null && customVer.arguments != null) {
                    List totalArgList = new ArrayList();
                    totalArgList.addAll(Arrays.asList(inheritsVer.arguments.game));
                    
                    int nskip = 0;
                    for (int i = 0; i < customVer.arguments.game.length; i++) {
                        if (nskip > 0) {
                            nskip--;
                            continue;
                        }
                        
                        Object perCustomArg = customVer.arguments.game[i];
                        if (perCustomArg instanceof String) {
                            String perCustomArgStr = (String) perCustomArg;
                            // Check if there is a duplicate argument on combine
                            if (perCustomArgStr.startsWith("--") && totalArgList.contains(perCustomArgStr)) {
                                perCustomArg = customVer.arguments.game[i + 1];
                                if (perCustomArg instanceof String) {
                                    perCustomArgStr = (String) perCustomArg;
                                    // If the next is argument value, skip it
                                    if (!perCustomArgStr.startsWith("--")) {
                                        nskip++;
                                    }
                                }
                            } else {
                                totalArgList.add(perCustomArgStr);
                            }
                        } else if (!totalArgList.contains(perCustomArg)) {
                            totalArgList.add(perCustomArg);
                        }
                    }

                    inheritsVer.arguments.game = totalArgList.toArray(new Object[0]);
                }

                return inheritsVer;
            }
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    // Prevent NullPointerException
    private static void insertSafety(JMinecraftVersionList.Version targetVer, JMinecraftVersionList.Version fromVer, String... keyArr) {
        for (String key : keyArr) {
            Object value = null;
            try {
                Field fieldA = fromVer.getClass().getDeclaredField(key);
                value = fieldA.get(fromVer);
                if (((value instanceof String) && !((String) value).isEmpty()) || value != null) {
                    Field fieldB = targetVer.getClass().getDeclaredField(key);
                    fieldB.set(targetVer, value);
                }
            } catch (Throwable th) {
                System.err.println("Unable to insert " + key + "=" + value);
                th.printStackTrace();
            }
        }
    }
    
    public static String convertStream(InputStream inputStream) throws IOException {
        return convertStream(inputStream, Charset.forName("UTF-8"));
    }
    
    public static String convertStream(InputStream inputStream, Charset charset) throws IOException {
        String out = "";
        int len;
        byte[] buf = new byte[512];
        while((len = inputStream.read(buf))!=-1) {
            out += new String(buf,0,len,charset);
        }
        return out;
    }

    public static void copy(final InputStream input, final OutputStream output) throws IOException {
        final byte[] buffer = new byte[8192];
        int n = 0;
        while ((n = input.read(buffer)) != -1) {
            output.write(buffer, 0, n);
        }
    }

    public static File lastFileModified(String dir) {
        File fl = new File(dir);

        File[] files = fl.listFiles(new FileFilter() {          
                public boolean accept(File file) {
                    return file.isFile();
                }
            });

        long lastMod = Long.MIN_VALUE;
        File choice = null;
        for (File file : files) {
            if (file.lastModified() > lastMod) {
                choice = file;
                lastMod = file.lastModified();
            }
        }

        return choice;
    }

    public static String read(InputStream is) throws IOException {
        String out = "";
        int len;
        byte[] buf = new byte[512];
        while((len = is.read(buf))!=-1) {
            out += new String(buf,0,len);
        }
        return out;
    }

    public static String read(String path) throws IOException {
        return read(new FileInputStream(path));
    }

    public static void write(String path, byte[] content) throws IOException
    {
        File outPath = new File(path);
        outPath.getParentFile().mkdirs();
        outPath.createNewFile();

        BufferedOutputStream fos = new BufferedOutputStream(new FileOutputStream(path));
        fos.write(content, 0, content.length);
        fos.close();
    }

    public static void write(String path, String content) throws IOException {
        write(path, content.getBytes());
    }
/*
    public static byte[] loadFromAssetToByte(Context ctx, String inFile) {
        byte[] buffer = null;

        try {
            InputStream stream = ctx.getAssets().open(inFile);

            int size = stream.available();
            buffer = new byte[size];
            stream.read(buffer);
            stream.close();
        } catch (IOException e) {
            // Handle exceptions here
            e.printStackTrace();
        }
        return buffer;
    }
*/
    public static void downloadFile(String urlInput, String nameOutput) throws IOException {
        File file = new File(nameOutput);
        DownloadUtils.downloadFile(urlInput, file);
    }
    public abstract static class DownloaderFeedback {
        public abstract void updateProgress(int curr, int max);
    }

    public static void downloadFileMonitored(String urlInput,String nameOutput, DownloaderFeedback monitor) throws IOException {
        if(!new File(nameOutput).exists()){
            new File(nameOutput).getParentFile().mkdirs();
        }
        HttpURLConnection conn = (HttpURLConnection) new URL(urlInput).openConnection();
        InputStream readStr = conn.getInputStream();
        FileOutputStream fos = new FileOutputStream(new File(nameOutput));
        int cur = 0; int oval=0; int len = conn.getContentLength(); byte[] buf = new byte[65535];
        while((cur = readStr.read(buf)) != -1) {
            oval += cur;
            fos.write(buf,0,cur);
            monitor.updateProgress(oval,len);
        }
        fos.close();
        conn.disconnect();
    }
    public static class ZipTool
    {
        private ZipTool(){}
        public static void zip(List<File> files, File zipFile) throws IOException {
            final int BUFFER_SIZE = 2048;

            BufferedInputStream origin = null;
            ZipOutputStream out = new ZipOutputStream(new BufferedOutputStream(new FileOutputStream(zipFile)));

            try {
                byte data[] = new byte[BUFFER_SIZE];

                for (File file : files) {
                    FileInputStream fileInputStream = new FileInputStream( file );

                    origin = new BufferedInputStream(fileInputStream, BUFFER_SIZE);

                    try {
                        ZipEntry entry = new ZipEntry(file.getName());

                        out.putNextEntry(entry);

                        int count;
                        while ((count = origin.read(data, 0, BUFFER_SIZE)) != -1) {
                            out.write(data, 0, count);
                        }
                    }
                    finally {
                        origin.close();
                    }
                }
            } finally {
                out.close();
            }
        }
        public static void unzip(File zipFile, File targetDirectory) throws IOException {
            final int BUFFER_SIZE = 1024;
            ZipInputStream zis = new ZipInputStream(
                new BufferedInputStream(new FileInputStream(zipFile)));
            try {
                ZipEntry ze;
                int count;
                byte[] buffer = new byte[BUFFER_SIZE];
                while ((ze = zis.getNextEntry()) != null) {
                    File file = new File(targetDirectory, ze.getName());
                    File dir = ze.isDirectory() ? file : file.getParentFile();
                    if (!dir.isDirectory() && !dir.mkdirs())
                        throw new FileNotFoundException("Failed to ensure directory: " +
                                                        dir.getAbsolutePath());
                    if (ze.isDirectory())
                        continue;
                    FileOutputStream fout = new FileOutputStream(file);
                    try {
                        while ((count = zis.read(buffer)) != -1)
                            fout.write(buffer, 0, count);
                    } finally {
                        fout.close();
                    }
                    /* if time should be restored as well
                     long time = ze.getTime();
                     if (time > 0)
                     file.setLastModified(time);
                     */
                }
            } finally {
                zis.close();
            }
        }
    }
}
