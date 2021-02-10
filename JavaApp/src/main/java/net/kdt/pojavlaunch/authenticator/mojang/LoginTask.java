package net.kdt.pojavlaunch.authenticator.mojang;

import android.os.*;
import net.kdt.pojavlaunch.authenticator.mojang.yggdrasil.*;
import java.io.*;
import java.util.*;
import net.kdt.pojavlaunch.*;

public class LoginTask {
    private YggdrasilAuthenticator authenticator = new YggdrasilAuthenticator();
    //private String TAG = "MojangAuth-login";
    private LoginListener listener;
    
    private UUID getRandomUUID() {
        return UUID.randomUUID();
    }
    
    @Override
    protected void onPreExecute() {
        listener.onBeforeLogin();
        
        super.onPreExecute();
    }
    
    @Override
    protected String[] run(String username, String password) {
        ArrayList<String> str = new ArrayList<String>();
        str.add("ERROR");
        try{
            try{
                AuthenticateResponse response = authenticator.authenticate(username, password, getRandomUUID());
                if (response.selectedProfile == null) {
                    str.add("Can't login a demo account!\n");
                } else {
                    if (new File(Tools.DIR_ACCOUNT_NEW + "/" + response.selectedProfile.name + ".json").exists()) {
                        str.add("This account already exist!\n");
                    } else {
                        str.add(response.accessToken);            // Access token
                        str.add(response.clientToken.toString()); // Client token
                        str.add(response.selectedProfile.id);     // Profile ID
                        str.add(response.selectedProfile.name);   // Username
                        str.set(0, "NORMAL");
                    }
                }
            }
                //MainActivity.updateStatus(804);
            catch(Throwable e){
                str.add(e.getMessage());
            }
        }
        catch(Exception e){
            str.add(e.getMessage());
        }
        return str.toArray(new String[0]);
    }
}
