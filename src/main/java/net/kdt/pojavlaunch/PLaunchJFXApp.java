package net.kdt.pojavlaunch;

import java.io.*;

import javafx.application.Application;
import javafx.geometry.Rectangle2D;
import javafx.scene.Group;
import javafx.scene.Scene;
import javafx.scene.shape.Circle;
import javafx.stage.Stage;

import net.kdt.pojavlaunch.value.*;

public class PLaunchJFXApp extends Application {
    public void start(Stage stage) {
        Rectangle2D bounds = Screen.getPrimary().getBounds();
        CallbackBridge.windowWidth = bounds.getWidth();
        CallbackBridge.windowHeight = bounds.getHeight();
    
/*
        Circle circ = new Circle(40, 40, 30);
        Group root = new Group(circ);
        Scene scene = new Scene(root, 400, 300);
        stage.setTitle("PojavLauncher");
        stage.setScene(scene);
        stage.show();
*/

        // Start Minecraft there!
        File file = new File(Tools.DIR_GAME_NEW);
        file.mkdirs();
        
        String mcver = "1.13";
        try {
            mcver = Tools.read(Tools.DIR_GAME_HOME + "/config_ver.txt");
        } catch (IOException e) {
            e.printStackTrace();
        }
        
        MinecraftAccount acc = new MinecraftAccount();
        JMinecraftVersionLis.Version version = Tools.getVersionInfo(mcver);
        
        Tools.launchMinecraft(acc, version);
        
/*
        net.minecraft.client.main.Main.main(new String[]{
            "--username", "test",
            "--version", "1.7.10",
            "--gameDir", file.getAbsolutePath(),
            "--assetsDir", file.getAbsolutePath() + "/assets",
            "--assetIndex", "1.7.10",
            "--uuid", "0", 
            "--accessToken", "0",
            "--userProperties", "{}",
            "--userType", "mojang",
            "--versionType", "release"
        });
*/
    }
}
