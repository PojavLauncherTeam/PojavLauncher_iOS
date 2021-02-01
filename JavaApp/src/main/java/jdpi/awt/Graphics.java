package jdpi.awt;

import jdpi.awt.image.*;

public class Graphics {
    protected java.awt.Graphics2D g2d;

	public Graphics(java.awt.Graphics2D g2d) {
		this.g2d = g2d;
	}

	public void setColor(Color color) {
		g2d.setColor(color);
	}

	public void fillRect(int x, int y, int width, int height) {
		g2d.fillRect(x, y, width, height);
	}

	public void drawString(String s, int x, int y) {
		g2d.drawString(s, x, y);
	}

	public void dispose() {
		g2d.dispose();
	}

	public boolean drawImage(Image image, int x, int y, ImageObserver observer) {
		if (!(image instanceof BufferedImage)) return true;
		return g2d.drawImage(((BufferedImage) image).getBaseImage(), x, y, ImageObserverWrapper.wrap(observer));
	}
}
