package net.kdt.pojavlaunch.utils;

import libcore.io.*;

import com.oracle.dalvik.*;
import java.io.*;
import java.util.*;
import net.kdt.pojavlaunch.*;
import net.kdt.pojavlaunch.prefs.*;
import org.lwjgl.glfw.*;

import libcore.io.*;

public class JREUtils
{
    private JREUtils() {}
    
    public static String LD_LIBRARY_PATH;
    private static String nativeLibDir;

    public static String findInLdLibPath(String libName) {
        for (String libPath : Libcore.os.getenv("LD_LIBRARY_PATH").split(":")) {
            File f = new File(libPath, libName);
            if (f.exists() && f.isFile()) {
                return f.getAbsolutePath();
            }
        }
        return libName;
    }
    
    public static void initJavaRuntime() {
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
/*
        JREUtils.redirectLogcat();
        Log.v("jrelog","Log starts here");
        Thread t = new Thread(new Runnable(){
            int failTime = 0;
            ProcessBuilder logcatPb;
            @Override
            public void run() {
                try {
                    if (logcatPb == null) {
                        logcatPb = new ProcessBuilder().command("logcat", "-v", "brief", "*:S").redirectErrorStream(true);
                    }
                    
                    Log.i("jrelog-logcat","Clearing logcat");
                    new ProcessBuilder().command("logcat", "-c").redirectErrorStream(true).start();
                    Log.i("jrelog-logcat","Starting logcat");
                    java.lang.Process p = logcatPb.start();

                    byte[] buf = new byte[1024];
                    int len;
                    while ((len = p.getInputStream().read(buf)) != -1) {
                        String currStr = new String(buf, 0, len);
                        
                        // Avoid leaking access token to log by replace it.
                        // Also, Minecraft will just print it once.
                        if (checkAccessTokenLeak) {
                            if (accessToken != null && accessToken.length() > 5 && currStr.contains(accessToken)) {
                                checkAccessTokenLeak = false;
                                currStr = currStr.replace(accessToken, "ACCESS_TOKEN_HIDDEN");
                            }
                        }
                        
                        act.appendToLog(currStr);
                    }
                    
                    if (p.waitFor() != 0) {
                        Log.e("jrelog-logcat", "Logcat exited with code " + p.exitValue());
                        failTime++;
                        Log.i("jrelog-logcat", (failTime <= 10 ? "Restarting logcat" : "Too many restart fails") + " (attempt " + failTime + "/10");
                        if (failTime <= 10) {
                            run();
                        } else {
                            act.appendlnToLog("ERROR: Unable to get more log.");
                        }
                        return;
                    }
                } catch (Throwable e) {
                    Log.e("jrelog-logcat", "Exception on logging thread", e);
                    act.appendlnToLog("Exception on logging thread:\n" + Log.getStackTraceString(e));
                }
            }
        });
        t.start();
        Log.i("jrelog-logcat","Logcat thread started");
*/
    }
    
    public static void relocateLibPath() throws Exception {
        StringBuilder ldLibraryPath = new StringBuilder();
        ldLibraryPath.append(
            // To make libjli.so ignore re-execute
            Tools.DIR_HOME_JRE + "/" + Tools.DIRNAME_HOME_JRE + "/server:" +
            Tools.DIR_HOME_JRE + "/" +  Tools.DIRNAME_HOME_JRE + "/jli:" +
            Tools.DIR_HOME_JRE + "/" + Tools.DIRNAME_HOME_JRE + ":" +
            Tools.DIR_DATA + "/Frameworks"
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
        envMap.put("LD_LIBRARY_PATH", LD_LIBRARY_PATH);
        // envMap.put("PATH", Tools.DIR_HOME_JRE + "/bin:" + Os.getenv("PATH"));
    
        envMap.put("AWTSTUB_WIDTH", Integer.toString(CallbackBridge.windowWidth));
        envMap.put("AWTSTUB_HEIGHT", Integer.toString(CallbackBridge.windowHeight));
        
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
            Libcore.os.setenv(env.getKey(), env.getValue(), true);
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
        setJavaEnvironment();
        initJavaRuntime();
        chdir(Tools.DIR_GAME_NEW);

        final int exitCode = VMLauncher.launchJVM(javaArgList.toArray(new String[0]));
        System.out.println("Java Exit code: " + exitCode);
        if (exitCode != 0) {
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
    public static native void redirectLogcat();
    public static native void setLdLibraryPath(String ldLibraryPath);
    public static native void saveGLContext();
    
    // Obtain AWT screen pixels to render on Android SurfaceView
    public static native int[] renderAWTScreenFrame(/* Object canvas, int width, int height */);

    static {
        System.loadLibrary("pojavexec");
    }
}
