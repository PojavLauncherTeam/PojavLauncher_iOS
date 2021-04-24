package net.kdt.pojavlaunch.utils;

import android.util.*;

import com.oracle.dalvik.*;

import java.io.*;
import java.util.*;

// import libcore.io.*;

import net.kdt.pojavlaunch.*;
import net.kdt.pojavlaunch.prefs.*;

import org.lwjgl.glfw.*;

public class JREUtils
{
    private JREUtils() {}
    
    public static String LD_LIBRARY_PATH;
    private static String nativeLibDir;

    public static String findInLdLibPath(String libName) {
        for (String libPath : System.getenv("LD_LIBRARY_PATH").split(":")) {
            File f = new File(libPath, libName);
            if (f.exists() && f.isFile()) {
                return f.getAbsolutePath();
            }
        }
        return libName;
    }
    
    public static void initJavaRuntime() {
/*
        dlopen(findInLdLibPath("libjli.dylib"));
        dlopen(findInLdLibPath("libjvm.dylib"));
        dlopen(findInLdLibPath("libverify.dylib"));
        dlopen(findInLdLibPath("libjava.dylib"));
        // dlopen(findInLdLibPath("libjsig.so"));
        dlopen(findInLdLibPath("libnet.dylib"));
        dlopen(findInLdLibPath("libnio.dylib"));
        dlopen(findInLdLibPath("libawt.dylib"));
        dlopen(findInLdLibPath("libawt_headless.dylib"));
        dlopen(findInLdLibPath("libfreetype.dylib"));
        dlopen(findInLdLibPath("libfontmanager.dylib"));
*/

        dlopen(nativeLibDir + "/libopenal.dylib");
/*
        if (LauncherPreferences.PREF_CUSTOM_OPENGL_LIBNAME.equals("libgl04es.so")) {
            LauncherPreferences.PREF_CUSTOM_OPENGL_LIBNAME = nativeLibDir + "/libgl04es.so";
        }
        if (!dlopen(LauncherPreferences.PREF_CUSTOM_OPENGL_LIBNAME) && !dlopen(findInLdLibPath(LauncherPreferences.PREF_CUSTOM_OPENGL_LIBNAME))) {
            System.err.println("Failed to load custom OpenGL library " + LauncherPreferences.PREF_CUSTOM_OPENGL_LIBNAME + ". Fallbacking to GL4ES.");
            dlopen(nativeLibDir + "/libgl04es.so");
        }
*/
    }

    public static Map<String, String> readJREReleaseProperties() throws IOException {
        Map<String, String> jreReleaseMap = new ArrayMap<>();
        BufferedReader jreReleaseReader = new BufferedReader(new FileReader(Tools.DIR_HOME_JRE + "/release"));
        String currLine;
        while ((currLine = jreReleaseReader.readLine()) != null) {
            if (!currLine.isEmpty() || currLine.contains("=")) {
                String[] keyValue = currLine.split("=");
                jreReleaseMap.put(keyValue[0], keyValue[1].replace("\"", ""));
            }
        }
        jreReleaseReader.close();
        return jreReleaseMap;
    }
    
    private static boolean checkAccessTokenLeak = true;
    public static void redirectAndPrintJRELog(final String accessToken) {
    }
    
    public static void relocateLibPath() throws Exception {
        StringBuilder ldLibraryPath = new StringBuilder();
        ldLibraryPath.append(
            // To make libjli.so ignore re-execute
            Tools.DIR_HOME_JRE + "/" + Tools.DIRNAME_HOME_JRE + "/server:" +
            Tools.DIR_HOME_JRE + "/" +  Tools.DIRNAME_HOME_JRE + "/jli:" +
            Tools.DIR_HOME_JRE + "/" + Tools.DIRNAME_HOME_JRE + ":" +
            Tools.DIR_DATA + "/Frameworks:"+
            System.getenv("DYLD_LIBRARY_PATH")
        );
        
        LD_LIBRARY_PATH = ldLibraryPath.toString();
    }
    
    public static void setJavaEnvironment() throws Throwable {
        Map<String, String> envMap = new ArrayMap<>();
        envMap.put("JAVA_HOME", Tools.DIR_HOME_JRE);
        envMap.put("HOME", Tools.DIR_GAME_NEW);
        envMap.put("TMPDIR", System.getProperty("java.io.tmpdir"));
        envMap.put("LIBGL_MIPMAP", "3");
        
        // Fix white color on banner and sheep, since GL4ES 1.1.5
        envMap.put("LIBGL_NORMALIZE", "1");
   
        envMap.put("MESA_GLSL_CACHE_DIR", System.getProperty("java.io.tmpdir"));
        envMap.put("DYLD_LIBRARY_PATH", LD_LIBRARY_PATH);
        // envMap.put("PATH", Tools.DIR_HOME_JRE + "/bin:" + Os.getenv("PATH"));
        
        File customEnvFile = new File(Tools.DIR_GAME_NEW, "custom_env.txt");
        if (customEnvFile.exists() && customEnvFile.isFile()) {
            BufferedReader reader = new BufferedReader(new FileReader(customEnvFile));
            String line;
            while ((line = reader.readLine()) != null) {
                // Not use split() as only split first one
                int index = line.indexOf("=");
                envMap.put(line.substring(0, index), line.substring(index + 1));
            }
            reader.close();
        }
        
        for (Map.Entry<String, String> env : envMap.entrySet()) {
            setenv(env.getKey(), env.getValue(), true);
        }
        
        setLdLibraryPath(LD_LIBRARY_PATH);
        
        // return ldLibraryPath;
    }
    
    public static int launchJavaVM(final List<String> args) throws Throwable {
        JREUtils.relocateLibPath();
        // ctx.appendlnToLog("LD_LIBRARY_PATH = " + JREUtils.LD_LIBRARY_PATH);

        List<String> javaArgList = new ArrayList<String>();
        javaArgList.add(Tools.DIR_HOME_JRE + "/bin/java");
        Tools.getJavaArgs(javaArgList);

        javaArgList.addAll(args);
        
        // For debugging only!
/*
        StringBuilder sbJavaArgs = new StringBuilder();
        for (String s : javaArgList) {
            sbJavaArgs.append(s + " ");
        }
        ctx.appendlnToLog("Executing JVM: \"" + sbJavaArgs.toString() + "\"");
*/

        redirectLogcat(Tools.DIR_APP_DATA + "/latestlog.txt");

        setJavaEnvironment();
        initJavaRuntime();
        chdir(Tools.DIR_GAME_NEW);

        final int exitCode = VMLauncher.launchJVM(true /* JLI_Launch */, javaArgList);
        System.out.println("Java Exit code: " + exitCode);
        if (exitCode != 0) {
            Tools.showError(new Exception("Java exited with code " + exitCode));
/*
            ctx.runOnUiThread(new Runnable(){
                    @Override
                    public void run() {
                        AlertDialog.Builder dialog = new AlertDialog.Builder(ctx);
                        dialog.setMessage(ctx.getString(R.string.mcn_exit_title, exitCode));
                        dialog.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener(){

                                @Override
                                public void onClick(DialogInterface p1, int p2){
                                    BaseMainActivity.fullyExit();
                                }
                            });
                        dialog.show();
                    }
                });
*/
        }
        return exitCode;
    }

    public static native int chdir(String path);
    public static native boolean dlopen(String libPath);
    public static native void redirectLogcat(String path);
    public static native void setLdLibraryPath(String ldLibraryPath);
    public static native void saveGLContext();
    public static native void setenv(String key, String value, boolean overwrite);
    
    // Obtain AWT screen pixels to render on Android SurfaceView
    public static native int[] renderAWTScreenFrame(/* Object canvas, int width, int height */);

    static {
        System.loadLibrary("pojavexec");
    }
}
