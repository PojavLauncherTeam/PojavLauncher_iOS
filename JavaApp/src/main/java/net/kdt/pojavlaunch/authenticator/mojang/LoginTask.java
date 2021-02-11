package net.kdt.pojavlaunch.authenticator.mojang;

import java.io.File;
import java.util.UUID;
import net.kdt.pojavlaunch.Tools;
import net.kdt.pojavlaunch.authenticator.mojang.yggdrasil.AuthenticateResponse;
import net.kdt.pojavlaunch.authenticator.mojang.yggdrasil.YggdrasilAuthenticator;
import net.kdt.pojavlaunch.value.MinecraftAccount;

public class LoginTask {
    private YggdrasilAuthenticator authenticator = new YggdrasilAuthenticator();
    //private String TAG = "MojangAuth-login";
    
    private UUID getRandomUUID() {
        return UUID.randomUUID();
    }
    
    public MinecraftAccount run(String username, String password) throws Throwable {
        AuthenticateResponse response = authenticator.authenticate(username, password, getRandomUUID());
        if (response.selectedProfile == null) {
            throw new IllegalArgumentException("Can't login a demo account!\n");
        } else {
            if (new File(Tools.DIR_ACCOUNT_NEW + "/" + response.selectedProfile.name + ".json").exists()) {
                throw new IllegalArgumentException("This account already exist!\n");
            } else {
                MinecraftAccount acc = new MinecraftAccount();
                acc.accessToken = response.accessToken;
                acc.clientToken = response.clientToken.toString();
                acc.profileId = response.selectedProfile.id;
                acc.username = response.selectedProfile.name;
                acc.save();
                return acc;
            }
        }
    }
}
