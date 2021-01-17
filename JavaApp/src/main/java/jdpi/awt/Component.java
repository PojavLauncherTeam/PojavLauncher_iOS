package jdpi.awt;

import org.lwjgl.glfw.GLFW;

public class Component {
	//setPreferredSize

	public int getWidth() {
		return GLFW.mGLFWWindowWidth;
	}

	public int getHeight() {
		return GLFW.mGLFWWindowHeight;
	}
	
	public void setVisible(boolean visible) {
	}
}
