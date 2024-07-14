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
import net.kdt.pojavlaunch.uikit.UIKit;
import net.kdt.pojavlaunch.utils.JSONUtils;
import net.kdt.pojavlaunch.value.DependentLibrary;
import net.kdt.pojavlaunch.value.MinecraftAccount;
import net.kdt.pojavlaunch.value.MinecraftLibraryArtifact;

public final class Tools {
    public static final Gson GLOBAL_GSON = new GsonBuilder().setPrettyPrinting().create();

    public static final String DIR_BUNDLE = System.getenv("BUNDLE_PATH"); // path to "PojavLauncher.app"
    public static final String DIR_GAME_HOME = System.getenv("POJAV_HOME");
    public static final String DIR_GAME_NEW = System.getenv("POJAV_GAME_DIR"); // path to "Library/Application Support/minecraft"
    public static final String DIR_GAME_PROFILE = System.getProperty("user.dir");
    
    public static final String DIR_APP_DATA = System.getenv("POJAV_HOME");
    public static final String DIR_ACCOUNT_NEW = DIR_APP_DATA + "/accounts";

    // New since 2.4.2
    public static final String DIR_HOME_VERSION = DIR_GAME_NEW + "/versions";
    public static final String DIR_HOME_LIBRARY = DIR_GAME_NEW + "/libraries";

    public static final String ASSETS_PATH = DIR_GAME_NEW + "/assets";
    public static final String OBSOLETE_RESOURCES_PATH=DIR_GAME_NEW + "/resources";

    public static void launchMinecraft(MinecraftAccount profile, final JMinecraftVersionList.Version versionInfo) throws Throwable {
        String[] launchArgs = getMinecraftArgs(profile, versionInfo);
        // System.out.println("Minecraft Args: " + Arrays.toString(launchArgs));

        final String launchClassPath = generateLaunchClassPath(versionInfo);

        System.out.println("Args init finished. Now starting game");

        PojavClassLoader loader = (PojavClassLoader) ClassLoader.getSystemClassLoader();
        // add launcher.jar itself
        for (String s : System.getProperty("java.class.path").split(":")) {
            loader.appendToClassPathForInstrumentation(s);
        }
        for (String s : launchClassPath.split(":")) {
            if (!s.isEmpty()) {
                loader.addURL(new File(s).toURI().toURL());
            }
        }
            
        Class<?> clazz = loader.loadClass(versionInfo.mainClass);
        Method method = clazz.getMethod("main", String[].class);
        method.invoke(null, new Object[]{launchArgs});
    }

    public static String[] getMinecraftArgs(MinecraftAccount profile, JMinecraftVersionList.Version versionInfo) {
        String username = profile.username.replace("Demo.", "");
        String versionName = versionInfo.id;
        if (versionInfo.inheritsFrom != null) {
            versionName = versionInfo.inheritsFrom;
        }

        File gameDir = new File(Tools.DIR_GAME_PROFILE);
        gameDir.mkdirs();

        Map<String, String> varArgMap = new ArrayMap<String, String>();
        varArgMap.put("auth_session", profile.accessToken); // For legacy versions of MC
        varArgMap.put("auth_access_token", profile.accessToken);
        varArgMap.put("auth_player_name", username);
        varArgMap.put("auth_uuid", profile.profileId.replace("-", ""));
        varArgMap.put("auth_xuid", profile.xuid);
        varArgMap.put("assets_root", Tools.ASSETS_PATH);
        varArgMap.put("assets_index_name", versionInfo.assets);
        varArgMap.put("clientid", profile.clientToken);
        varArgMap.put("game_assets", Tools.ASSETS_PATH);
        varArgMap.put("game_directory", gameDir.getAbsolutePath());
        varArgMap.put("user_properties", "{}");
        varArgMap.put("user_type", "mojang");
        varArgMap.put("version_name", versionName);
        varArgMap.put("version_type", versionInfo.type);
        varArgMap.put("natives_directory", System.getProperty("java.library.path"));

        List<String> minecraftArgs = new ArrayList<String>();
        if (versionInfo.arguments != null) {
            // Support Minecraft 1.13+
            for (Object arg : versionInfo.arguments.game) {
                if (arg instanceof String) {
                    minecraftArgs.add((String) arg);
                    if (arg.equals("--xuid")) {
                        varArgMap.put("user_type", "msa");
                    }
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
        String[] argsFromJson = JSONUtils.insertJSONValueList(
            splitAndFilterEmpty(
                versionInfo.minecraftArguments == null ?
                fromStringArray(minecraftArgs.toArray(new String[0])):
                versionInfo.minecraftArguments,
                profile
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

    private static String[] splitAndFilterEmpty(String argStr, MinecraftAccount profile) {
        List<String> strList = new ArrayList<String>();
        if(profile.username.startsWith("Demo.")) {
            strList.add("--demo");
        }
        for (String arg : argStr.split(" ")) {
            if (!arg.isEmpty()) {
                strList.add(arg);
            }
        }
        return strList.toArray(new String[0]);
    }

    public static String artifactToPath(DependentLibrary library) {
        if (library.downloads != null &&
            library.downloads.artifact != null &&
            library.downloads.artifact.path != null)
            return library.downloads.artifact.path;
        String[] libInfos = library.name.split(":");
        return libInfos[0].replaceAll("\\.", "/") + "/" + libInfos[1] + "/" + libInfos[2] + "/" + libInfos[1] + "-" + libInfos[2] + ".jar";
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
    public static String generateLaunchClassPath(JMinecraftVersionList.Version info) {
        StringBuilder libStr = new StringBuilder(); //versnDir + "/" + version + "/" + version + ".jar:";

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

        for (String perJar : classpath) {
            if (!new File(perJar).exists()) {
                System.out.println("Ignored non-exists file: " + perJar);
                continue;
            }
            libStr.append(perJar + ":");
        }
        libStr.append(DIR_HOME_VERSION + "/" + info.id + "/" + info.id + ".jar");

        return libStr.toString();
    }
    
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

    public static void preProcessLibraries(DependentLibrary[] libraries) {
        // Ignore some libraries since they are unsupported (jinput, text2speech) or unused (LWJGL)
        // Support for text2speech is not planned, so skip it for now.
        for (int i = 0; i < libraries.length; i++) {
            DependentLibrary libItem = libraries[i];
            if (libItem.name.startsWith("com.mojang:text2speech") ||
                //libItem.name.startsWith("net.java.jinput") ||
                libItem.name.startsWith("net.java.dev.jna:platform:") ||
                libItem.name.startsWith("org.lwjgl") ||
                libItem.name.startsWith("tv.twitch")) {
                    libItem._skip = true;
                    continue;
            }

            String[] version = libItem.name.split(":")[2].split("\\.");
            if (libItem.name.startsWith("net.java.dev.jna:jna:")) {
                // Special handling for LabyMod 1.8.9 and Forge 1.12.2(?)
                // we have libjnidispatch 5.13.0 in Frameworks directory
                if (Integer.parseInt(version[0]) >= 5 && Integer.parseInt(version[1]) >= 13) continue;
                //System.out.println("Library " + libItem.name + " has been changed to version 5.13.0");
                
createLibraryInfo(libItem);
                libItem.name = "net.java.dev.jna:jna:5.13.0";
                libItem.downloads.artifact.path = "net/java/dev/jna/jna/5.13.0/jna-5.13.0.jar";
                libItem.downloads.artifact.url = "https://libraries.minecraft.net/net/java/dev/jna/jna/5.13.0/jna-5.13.0.jar";
            } else if (libItem.name.startsWith("org.ow2.asm:asm-all:")) {
                if(Integer.parseInt(version[0]) >= 5) continue;
                //System.out.println("Library " + libItem.name + " has been changed to version 5.0.4");
                createLibraryInfo(libItem);
                libItem.name = "org.ow2.asm:asm-all:5.0.4";
                libItem.url = null;
                libItem.downloads.artifact.path = "org/ow2/asm/asm-all/5.0.4/asm-all-5.0.4.jar";
                libItem.downloads.artifact.sha1 = "e6244859997b3d4237a552669279780876228909";
                libItem.downloads.artifact.url = "https://repo1.maven.org/maven2/org/ow2/asm/asm-all/5.0.4/asm-all-5.0.4.jar";
            }
        }
    }

    private static void createLibraryInfo(DependentLibrary library) {
        if(library.downloads == null || library.downloads.artifact == null)
            library.downloads = new DependentLibrary.LibraryDownloads(new MinecraftLibraryArtifact());
    }

    public static String[] generateLibClasspath(JMinecraftVersionList.Version info) {
        List<String> libDir = new ArrayList<String>();

        preProcessLibraries(info.libraries);
        for (DependentLibrary libItem : info.libraries) {
            if (libItem._skip) continue;
            String fullPath = Tools.DIR_HOME_LIBRARY + "/" + artifactToPath(libItem);
            if (!libDir.contains(fullPath)) {
                libDir.add(fullPath);
            }
        }
        return libDir.toArray(new String[0]);
    }

    public static JMinecraftVersionList.Version getVersionInfo(String versionName) {
        try {
            JMinecraftVersionList.Version customVer = Tools.GLOBAL_GSON.fromJson(read(DIR_HOME_VERSION + "/" + versionName + "/" + versionName + ".json"), JMinecraftVersionList.Version.class);
            if (customVer.inheritsFrom == null || customVer.inheritsFrom.equals(customVer.id)) {
                return customVer;
            } else {
                JMinecraftVersionList.Version inheritsVer = Tools.GLOBAL_GSON.fromJson(read(DIR_HOME_VERSION + "/" + customVer.inheritsFrom + "/" + customVer.inheritsFrom + ".json"), JMinecraftVersionList.Version.class);
                inheritsVer.inheritsFrom = inheritsVer.id;
                
                insertSafety(inheritsVer, customVer,
                             "assetIndex", "assets", "id",
                             "mainClass", "minecraftArguments",
                             "releaseTime", "time", "type"
                             );

                // Go through the libraries, remove the ones overridden by the custom version
                List<DependentLibrary> inheritLibraryList = new ArrayList<>(Arrays.asList(inheritsVer.libraries));
                outer_loop:
                for(DependentLibrary library : customVer.libraries){
                    // Clean libraries overridden by the custom version
                    String libName = library.name.substring(0, library.name.lastIndexOf(":"));

                    for(DependentLibrary inheritLibrary : inheritLibraryList) {
                        String inheritLibName = inheritLibrary.name.substring(0, inheritLibrary.name.lastIndexOf(":"));

                        if(libName.equals(inheritLibName)){
                            System.out.println("Library " + libName + ": Replaced version " +
                                    libName.substring(libName.lastIndexOf(":") + 1) + " with " +
                                    inheritLibName.substring(inheritLibName.lastIndexOf(":") + 1));

                            // Remove the library , superseded by the overriding libs
                            inheritLibraryList.remove(inheritLibrary);
                            continue outer_loop;
                        }
                    }
                }

                // Fuse libraries
                inheritLibraryList.addAll(Arrays.asList(customVer.libraries));
                inheritsVer.libraries = inheritLibraryList.toArray(new DependentLibrary[0]);
                preProcessLibraries(inheritsVer.libraries);

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
                Field fieldA = fromVer.getClass().getField(key);
                value = fieldA.get(fromVer);
                if (((value instanceof String) && !((String) value).isEmpty()) || value != null) {
                    Field fieldB = targetVer.getClass().getField(key);
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
}
