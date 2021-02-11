package net.kdt.pojavlaunch.uikit;

import net.kdt.pojavlaunch.PojavProfile;
import net.kdt.pojavlaunch.Tools;
import net.kdt.pojavlaunch.authenticator.mojang.LoginTask;
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
        String password  // Mojang password or Microsoft token
    ) {
        try {
            switch (type) {
                case TYPE_SELECTACC:
                    CURRENT_ACCOUNT = MinecraftAccount.load(username);
                    if (CURRENT_ACCOUNT.accessToken.length() > 5) {
                        PojavProfile.updateTokens(username);
                    }
                    CURRENT_ACCOUNT = MinecraftAccount.load(username);
                    break;
                
                case TYPE_MICROSOFT:
                    // TODO
                    throw new UnsupportedOperationException("TODO");
                    // break;
                
                case TYPE_MOJANG:
                    CURRENT_ACCOUNT = new LoginTask().run(username, password);
                    break;
                
                case TYPE_OFFLINE:
                    CURRENT_ACCOUNT = new MinecraftAccount();
                    CURRENT_ACCOUNT.username = username;
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
