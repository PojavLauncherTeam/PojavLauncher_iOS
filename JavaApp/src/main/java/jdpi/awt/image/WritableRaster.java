package jdpi.awt.image;

public class WritableRaster {
	private BufferedImage image;
	public WritableRaster(BufferedImage image) {
		this.image = image;
	}
	public DataBuffer getDataBuffer() {
		int[] theBuf = new int[image.getWidth() * image.getHeight()];
		image.getRGB(0, 0, image.getWidth(), image.getHeight(), theBuf, 0, image.getWidth());
		return new DataBufferInt(theBuf, theBuf.length);
	}
}
