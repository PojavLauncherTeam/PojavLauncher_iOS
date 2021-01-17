package jdpi.awt.image;

import jdpi.awt.Image;

public class ImageObserverWrapper {
    public static java.awt.image.ImageObserver wrap(final ImageObserver observer) {
        return new java.awt.image.ImageObserver() {
            @Override
            public boolean imageUpdate(java.awt.Image img, int infoflags, int x, int y, int width, int height) {
                if (img instanceof BufferedImage) {
                    observer.imageUpdate((BufferedImage) imf, infoflags, x, y, width, height);
                }
            }
        };
    }
}
