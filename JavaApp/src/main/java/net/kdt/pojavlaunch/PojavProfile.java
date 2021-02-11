package net.kdt.pojavlaunch;

import com.google.gson.JsonSyntaxException;
import java.io.File;
import java.io.IOException;
import net.kdt.pojavlaunch.authenticator.mojang.RefreshListener;
import net.kdt.pojavlaunch.authenticator.mojang.RefreshTokenTask;
import net.kdt.pojavlaunch.value.MinecraftAccount;

public class PojavProfile
{
/*
	public static MinecraftAccount getCurrentProfileContent() throws IOException, JsonSyntaxException {
		MinecraftAccount build = MinecraftAccount.load(getCurrentProfileName());
        if (build == null) {
            return getTempProfileContent();
        }
        return MinecraftAccount.load(getCurrentProfileName());
	}

    public static MinecraftAccount getTempProfileContent(Context ctx) {
        return MinecraftAccount.parse(getPrefs(ctx).getString(PROFILE_PREF_TEMP_CONTENT, ""));
    }

    public static String getCurrentProfileName() {
        String name = "";
        try {
            name = Tools.read(currAccFile.getAbsolutePath());
        } catch (IOException e) {
            e.printStackTrace();
        }
        // A dirty fix
        if (!name.isEmpty() && name.startsWith(Tools.DIR_ACCOUNT_NEW) && name.endsWith(".json")) {
            name = name.substring(0, name.length() - 5).replace(Tools.DIR_ACCOUNT_NEW, "").replace(".json", "");
            setCurrentProfile(name);
        }
        return name;
    }

	public static boolean setCurrentProfile(Object obj) {
		try {
			if (obj instanceof MinecraftAccount) {
                throw new UnsupportedOperationException("Temp account is not supported yet");
			} else if (obj instanceof String) {
                String acc = (String) obj;
				Tools.write(currAccFile.getAbsolutePath(), acc);
                MinecraftAccount.clearTempAccount();
			} else if (obj == null) {
				// pref.putString(PROFILE_PREF_FILE, "");
			} else {
				throw new IllegalArgumentException("Profile must be MinecraftAccount.class, String.class or null");
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
        return false;
    }
	
	public static boolean isFileType() {
		return new File(Tools.DIR_ACCOUNT_NEW + "/" + getCurrentProfileName() + ".json").exists();
	}
*/
    public static void updateTokens(final String name) throws Throwable {
        new RefreshTokenTask().run(name);
    }
}
