package net.kdt.pojavlaunch;

import java.util.Map;
import net.kdt.pojavlaunch.value.*;
import java.util.*;

public class JMinecraftVersionList {
    public static final String TYPE_OLD_ALPHA = "old_alpha";
    public static final String TYPE_OLD_BETA = "old_beta";
    public static final String TYPE_RELEASE = "release";
    public static final String TYPE_SNAPSHOT = "snapshot";
    public Map<String, String> latest;
    public Version[] versions;

    public static class FileProperties {
        public String id, sha1, url;
        public long size;
    }

    public static class Version extends FileProperties {
        // Since 1.13, so it's one of ways to check
        public Arguments arguments;
        public AssetIndex assetIndex;

        public String assets;
        public Map<String, MinecraftClientInfo> downloads;
        public String inheritsFrom;
        public JavaVersionInfo javaVersion;
        public DependentLibrary[] libraries;
        public LoggingConfig logging;
        public String mainClass;
        public String minecraftArguments;
        public int minimumLauncherVersion;
        public String releaseTime;
        public String time;
        public String type;
    }
	public static class JavaVersionInfo {
        public String component;
        public int majorVersion;
    }
    public static class LoggingConfig {
        public LoggingClientConfig client;

        public static class LoggingClientConfig {
            public String argument;
            public FileProperties file;
            public String type;
        }
    }
    // Since 1.13
    public static class Arguments {
        public Object[] game;
        public Object[] jvm;

        public static class ArgValue {
            public ArgRules[] rules;
            public String value;
            
            // TLauncher styled argument...
            public String[] values;

            public static class ArgRules {
                public String action;
                public String features;
            }
        }
    }
    public static class AssetIndex extends FileProperties {
        public long totalSize;
    }
}

