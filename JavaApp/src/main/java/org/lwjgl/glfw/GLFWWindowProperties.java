package org.lwjgl.glfw;

import java.util.*;
import net.kdt.pojavlaunch.Tools;

public class GLFWWindowProperties {
    public int width = Tools.mGLFWWindowWidth;
    public int height = Tools.mGLFWWindowHeight;
    public float x, y;
    public CharSequence title;
    public boolean shouldClose, isInitialSizeCalled, isCursorEntered;
    public long monitor;
    public Map<Integer, Integer> inputModes = new HashMap<>();
    public Map<Integer, Integer> windowAttribs = new HashMap<>();
    
    @Override
    public String toString() {
        return "width=" + width + ", " +
          "height=" + height + ", " +
          "x=" + x + ", " +
          "y=" + y + ", ";
    }
}
