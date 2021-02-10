package net.kdt.pojavlaunch.authenticator.mojang;

import android.content.*;
import android.os.*;
import net.kdt.pojavlaunch.authenticator.mojang.yggdrasil.*;
import java.io.*;
import java.util.*;
import net.kdt.pojavlaunch.*;
import net.kdt.pojavlaunch.value.*;

public class InvalidateTokenTask {
    private YggdrasilAuthenticator authenticator = new YggdrasilAuthenticator();
    //private Gson gson = new Gson();
    private MinecraftAccount profilePath;
    private String name;

    @Override
    public Throwable run(String name) {
        this.name = name;
        try {
            this.profilePath = MinecraftAccount.load(name);
            this.authenticator.invalidate(profilePath.accessToken,
                UUID.fromString(profilePath.isMicrosoft ? profilePath.profileId : profilePath.clientToken /* should be? */));
            new File(Tools.DIR_ACCOUNT_NEW, name + ".json").delete();
            return null;
        } catch (Throwable e) {
            return e;
        }
    }
}

