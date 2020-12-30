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
                
                String mainClass = "";
                int mainClassIndex;
                for (mainClassIndex = 0; mainClassIndex < args.size(); mainClassIndex++) {
                    if (!args.get(mainClassIndex).startsWith("-")) {
                        mainClass = args.get(mainClassIndex);
                        break;
                    }
                }
                
                mainClassIndex++;
                String[] mainArgs = new String[args.size() - mainClassIndex];
                System.arraycopy(
                    args.toArray(new String[0]), mainClassIndex,
                    mainArgs, 0, mainArgs.length
                );

                String[] vmArgs = new String[args.size() - mainArgs.length - 2];
                System.arraycopy(
                    args.toArray(new String[0]), 0,
                    vmArgs, 0, vmArgs.length
                );
                
                return createLaunchMainJVM(vmArgs, mainClass, mainArgs);
            } else {
                throw new RuntimeException("Invalid or unsupported classpath type");
            }
        }
    }
	private static native int launchJVM(String[] args);
	private static native int createLaunchMainJVM(String[] vmArgs, String mainClass, String[] mainArgs);
}
