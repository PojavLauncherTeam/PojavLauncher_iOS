package net.kdt.pojavlaunch.authenticator.mojang;

import com.google.gson.*;
import java.util.*;
import net.kdt.pojavlaunch.*;
import net.kdt.pojavlaunch.authenticator.mojang.yggdrasil.*;
import net.kdt.pojavlaunch.value.*;
import java.io.IOException;

public class RefreshTokenTask {
    private YggdrasilAuthenticator authenticator = new YggdrasilAuthenticator();
    private MinecraftAccount profilePath;

    public void run(String name) throws Throwable {
        this.profilePath = MinecraftAccount.load(name);
        int responseCode = 400;
        responseCode = this.authenticator.validate(profilePath.accessToken).statusCode;
        if (responseCode >= 200 && responseCode < 300) {
            RefreshResponse response = this.authenticator.refresh(profilePath.accessToken, UUID.fromString(profilePath.clientToken));
            // if (response == null) {
            // throw new NullPointerException("Response is null?");
            // }
            if (response == null) {
                // Refresh when offline?
                return;
            } else if (response.selectedProfile == null) {
                throw new IllegalArgumentException("Can't refresh a demo account!");
            }

            profilePath.clientToken = response.clientToken.toString();
            profilePath.accessToken = response.accessToken;
            profilePath.username = response.selectedProfile.name;
            profilePath.profileId = response.selectedProfile.id;
            profilePath.save();
        }
    }
}

