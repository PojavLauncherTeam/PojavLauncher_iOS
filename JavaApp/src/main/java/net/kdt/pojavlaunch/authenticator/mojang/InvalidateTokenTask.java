package net.kdt.pojavlaunch.authenticator.mojang;

import java.io.File;
import java.util.UUID;
import net.kdt.pojavlaunch.Tools;
import net.kdt.pojavlaunch.authenticator.mojang.yggdrasil.YggdrasilAuthenticator;
import net.kdt.pojavlaunch.value.MinecraftAccount;

public class InvalidateTokenTask {
    private YggdrasilAuthenticator authenticator = new YggdrasilAuthenticator();
    //private Gson gson = new Gson();
    private MinecraftAccount profilePath;
    private String name;

    public void run(String name) throws Throwable {
        this.name = name;
        this.profilePath = MinecraftAccount.load(name);
        this.authenticator.invalidate(profilePath.accessToken,
                                      UUID.fromString(profilePath.isMicrosoft ? profilePath.profileId : profilePath.clientToken /* should be? */));
        new File(Tools.DIR_ACCOUNT_NEW, name + ".json").delete();
    }
}

