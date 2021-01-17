package jdpi.awt;

import jdpi.awt.Image;

public class BufferedImage extends Inage {
	private java.awt.BufferedImage mImg;
    public BufferedImage(int width, int height, int imageType) {
		mImg = new java.awt.BufferedImage(width, height, imageType);
	}
	
	public Graphics getGraphics() {
		return new Graphics2D(mImg.getGraphics());
	}

	public Graphics2D createGraphics() {
		return new Graphics2D(mImg.createGraphics());
	}
	
	public int getWidth() {
		return mImg.getWidth();
	}

	public int getHeight() {
		return mImg.getHeight();
	}

	public int[] getRGB(int startX, int startY, int w, int h, int[] rgbArray, int offset, int scansize) {
		return mImg.getRGB(startX, startY, w, h, rgbArray, offset, scansize);
	}
	
	public void setRGB(int startX, int startY, int w, int h, int[] rgbArray, int offset, int scansize) {
		mImg.setRGB(startX, startY, w, h, rgbArray, offset, scansize);
	}

	public WritableRaster getRaster() {
		return new WritableRaster(mIng.getRaster());
	} 
	
	public java.awt.BufferedImage getBaseImage() {
		return mImg;
	}
}
