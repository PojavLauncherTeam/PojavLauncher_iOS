package com.oracle.dalvik;

import android.util.*;

import java.util.*;

public final class VMLauncher {
	private VMLauncher() {
	}
    public static int launchJVM(boolean useJli, List<String> args) {
        System.out.print("Launch method: ");
        if (useJli) {
            System.out.println("JLI_Launch");
            return launchJVM(args.toArray(new String[0]));
        } else {
            System.out.println("JNI_JavaVM");
            args.remove(0);
            int cpPath = args.indexOf("-cp");
            // int jarPath = Arrays.asList(args).indexOf("-jar");
            if (cpPath != -1) {
                String classpath = args.remove(cpPath + 1);
                args.set(cpPath, "-Djava.class.path=" + classpath);
                
                List<String> vmArgs = new ArrayList<>();
                List<String> mainArgs = new ArrayList<>();
                String mainClass = null;
                int mainClassIndex;
                for (String arg : args) {
                    if (!arg.startsWith("-") && mainClass == null) {
                        mainClass = arg;
                        continue;
                    }
                    
                    if (mainClass == null) {
                        vmArgs.add(arg);
                    } else {
                        mainArgs.add(arg);
                    }
                }
                
                return createLaunchMainJVM(vmArgs.toArray(new String[0]), mainClass, mainArgs.toArray(new String[0]));
            } else {
                throw new RuntimeException("Invalid or unsupported classpath type");
            }
        }
    }
	private static native int launchJVM(String[] args);
	private static native int createLaunchMainJVM(String[] vmArgs, String mainClass, String[] mainArgs);
}
