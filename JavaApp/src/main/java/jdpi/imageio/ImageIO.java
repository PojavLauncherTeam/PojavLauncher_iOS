package jdpi.imageio;

import java.io.*;
import java.net.URL;

import jdpi.awt.*;
import jdpi.awt.image.*;

public class ImageIO {
	public static void setUseCache(boolean set) {
	}

	public static BufferedImage read(InputStream is) throws IOException {
		return new BufferedImage(javax.imageio.ImageIO.read(is));
	}

	public static BufferedImage read(File input) throws IOException {
		return read(new FileInputStream(input));
	}

	public static BufferedImage read(URL input) throws IOException {
		BufferedImage img = read(input.openStream());
		input.close();
		return img;
	}

	public static boolean write(RenderedImage im, String formatName, File output) {
		System.out.println("ImageIO.write stub " + output);
		return true;
	}
}
