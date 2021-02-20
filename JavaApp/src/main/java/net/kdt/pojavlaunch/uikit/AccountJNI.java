package net.kdt.pojavlaunch.uikit;

import net.kdt.pojavlaunch.PojavProfile;
import net.kdt.pojavlaunch.Tools;
import net.kdt.pojavlaunch.authenticator.microsoft.MicrosoftAuthTask;
import net.kdt.pojavlaunch.authenticator.mojang.LoginTask;
import net.kdt.pojavlaunch.authenticator.mojang.yggdrasil.*;
import net.kdt.pojavlaunch.value.MinecraftAccount;

public class AccountJNI {
    public static final int TYPE_SELECTACC = 0;
    public static final int TYPE_MICROSOFT = 1;
    public static final int TYPE_MOJANG = 2;
    public static final int TYPE_OFFLINE = 3;
    
    public static volatile MinecraftAccount CURRENT_ACCOUNT;

    // Call back about account credentials for login
    public static boolean loginAccount(int type,
        String data, // One of:
        // Offline username
        // Mojang json response
        // Microsoft token
    ) {
        try {
            switch (type) {
                case TYPE_SELECTACC:
                    CURRENT_ACCOUNT = MinecraftAccount.load(data);
                    if (CURRENT_ACCOUNT.isMicrosoft) {
                        CURRENT_ACCOUNT = new MicrosoftAuthTask().run("true", CURRENT_ACCOUNT.msaRefreshToken);
                    } else if (CURRENT_ACCOUNT.accessToken.length() > 5) {
                        PojavProfile.updateTokens(data);
                    }
                    CURRENT_ACCOUNT = MinecraftAccount.load(data);
                    break;
                
                case TYPE_MICROSOFT:
                    CURRENT_ACCOUNT = new MicrosoftAuthTask().run("false", data);
                    break;
                
                case TYPE_MOJANG:
                    AuthenticateResponse response = Tools.GLOBAL_GSON.fromJson(data, AuthenticateResponse.class);
                    CURRENT_ACCOUNT = new MinecraftAccount();
                    CURRENT_ACCOUNT.accessToken = response.accessToken;
                    CURRENT_ACCOUNT.clientToken = response.clientToken.toString();
                    CURRENT_ACCOUNT.profileId = response.selectedProfile.id;
                    CURRENT_ACCOUNT.username = response.selectedProfile.name;
                    CURRENT_ACCOUNT.save();
                    break;
                
                case TYPE_OFFLINE:
                    CURRENT_ACCOUNT = new MinecraftAccount();
                    CURRENT_ACCOUNT.username = data;
                    CURRENT_ACCOUNT.save();
                    break;
            }
            
            return true;
        } catch (Throwable th) {
            Tools.showError(th);
        }
        
        return false;
    }
    
    static {
        // System.loadLibrary("pojavexec");
    }
}
