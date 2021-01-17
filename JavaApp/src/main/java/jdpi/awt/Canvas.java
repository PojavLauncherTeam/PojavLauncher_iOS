package jdpi.awt;

import org.lwjgl.glfw.GLFW;

public class Canvas extends Component {

	public void setPreferredSize(Dimension dim) {
	}

	public Graphics getGraphics() {
		return null;
	}

	public int getWidth() {
		return GLFW.mGLFWWindowWidth;
	}

	public int getHeight() {
		return GLFW.mGLFWWindowHeight;
	}
}