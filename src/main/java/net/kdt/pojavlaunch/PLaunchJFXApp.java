package net.kdt.pojavlaunch;

import java.io.*;

import javafx.application.Application;
import javafx.scene.Group;
import javafx.scene.Scene;
import javafx.scene.shape.Circle;
import javafx.stage.Stage;

public class PLaunchJFXApp extends Application {
    public void start(Stage stage) {
        Circle circ = new Circle(40, 40, 30);
        Group root = new Group(circ);
        Scene scene = new Scene(root, 400, 300);
        stage.setTitle("PojavLauncher");
        stage.setScene(scene);
        stage.show();

        // Start Minecraft there!
        File file = new File(System.getenv("HOME"), "Documents/minecraft");
        file.mkdirs();
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
