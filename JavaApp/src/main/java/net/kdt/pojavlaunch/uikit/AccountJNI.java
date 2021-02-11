package net.kdt.pojavlaunch.uikit;

import net.kdt.pojavlaunch.PojavProfile;
import net.kdt.pojavlaunch.authenticator.mojang.*;
import net.kdt.pojavlaunch.value.MinecraftAccount;

public class AccountJNI {
    public static final int TYPE_SELECTACC = 0;
    public static final int TYPE_MICROSOFT = 1;
    public static final int TYPE_MOJANG = 2;
    public static final int TYPE_OFFLINE = 3;
    
    public static volatile MinecraftAccount CURRENT_ACCOUNT;

    // Call back about account credentials for login
    public static boolean loginAccount(int type,
        String username, // Mojang or offline username
        String password, // Mojang password or Microsoft token
    ) {
        try {
            switch (type) {
                case TYPE_SELECTACC:
                PojavProfile.updateTokens(username);
                    CURRENT_ACCOUNT = MinecraftAccount.load(username);
                    return true;
                
                case TYPE_MICROSOFT:
                    // TODO
                    break;
                
                case TYPE_MOJANG:
                    String[] retArr = new LoginTask().run(username, password);
                    if (!retArr[0].equals("NORMAL")) {
                        StringBuilder full = new StringBuilder();
                        for (int i = 1; i < retArr.length; i++) {
                            full.append(retArr[i] + "\n");
                        }
                        UIKit.showError("Error", full.toString());
                        return false;
                    } else {
                        CURRENT_ACCOUNT = new MinecraftAccount();
                        CURRENT_ACCOUNT.accessToken = retArr[1];
                        CURRENT_ACCOUNT.clientToken = retArr[2];
                        CURRENT_ACCOUNT.profileId = retArr[3];
                        CURRENT_ACCOUNT.username = retArr[4];
                        CURRENT_ACCOUNT.save();
                        return true;
                    }
                    break;
                
                case TYPE_OFFLINE:
                    CURRENT_ACCOUNT = new MinecraftAccount();
                    CURRENT_ACCOUNT.username = username;
                    CURRENT_ACCOUNT.save();
                    return true;
            }
        } catch (Throwable th) {
            Tools.showError(th);
        }
        
        return false;
    }
    
    static {
        // System.loadLibrary("pojavexec");
    }
}
