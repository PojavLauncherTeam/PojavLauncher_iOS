package net.kdt.pojavlaunch.authenticator.microsoft;

import android.util.*;

import java.io.*;
import java.net.*;
import java.text.*;
import java.util.*;

import net.kdt.pojavlaunch.*;
import net.kdt.pojavlaunch.value.launcherprofiles.*;
import net.kdt.pojavlaunch.value.*;

import org.json.*;

public class MicrosoftAuthTask {

    //private Gson gson = new Gson();
    
    public MinecraftAccount run(String... args) throws Throwable {
            /*
            publishProgress();
            String msaAccessToken = acquireAccessToken(args[0]);
            
            publishProgress();
            String xblToken = acquireXBLToken(msaAccessToken);
            
            publishProgress();
            String[] xstsData = acquireXsts(xblToken);
            
            publishProgress();
            String mcAccessToken = acquireMinecraftToken(xstsData[0], xstsData[1]);
            
            publishProgress();

             */
            Msa msa = new Msa(this, Boolean.parseBoolean(args[0]), args[1]);

            MinecraftAccount acc = new MinecraftAccount();
            if (msa.doesOwnGame) {
                acc.clientToken = "0"; /* FIXME */
                acc.accessToken = msa.mcToken;
                acc.username = msa.mcName;
                acc.profileId = msa.mcUuid;
                acc.msaRefreshToken = msa.msRefreshToken;
            } else if(msa.doesDemo) {
                acc.clientToken = "0"; /* FIXME */
                acc.accessToken = "-1"; // Differentiate from local accounts
                acc.username = "demo_user";
                acc.profileId = "25e00594-cf57-3f87-b3af-3f06591be252";
                acc.msaRefreshToken = "0";
            }
            acc.save();
           
            return acc;
    }
}

