package net.kdt.pojavlaunch.utils;

import android.util.*;

import java.io.*;
import java.util.*;

// import libcore.io.*;

import net.kdt.pojavlaunch.*;

import org.lwjgl.glfw.*;

public class JREUtils
{
    private JREUtils() {}


    static {
        System.load(System.getenv("BUNDLE_PATH") + "/PojavLauncher");
    }
}
