package net.kdt.pojavlaunch.authenticator.microsoft;

import android.util.*;

import java.net.*;
import java.text.*;
import java.util.*;
import net.kdt.pojavlaunch.*;
import net.kdt.pojavlaunch.authenticator.mojang.*;
import net.kdt.pojavlaunch.authenticator.microsoft.*;
import org.json.*;

import java.text.ParseException;
import java.io.*;
import net.kdt.pojavlaunch.value.launcherprofiles.*;
import net.kdt.pojavlaunch.value.*;

public class MicrosoftAuthTask extends AsyncTask<String, Void, Object> {

    //private Gson gson = new Gson();
    
    public Object run(String... args) throws Throwable {
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
                acc.isMicrosoft = true;
                acc.msaRefreshToken = msa.msRefreshToken;
            }
            acc.save();
           
            return acc;
    }
}

