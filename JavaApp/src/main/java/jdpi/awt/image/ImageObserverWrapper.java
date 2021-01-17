package jdpi.awt.image;

import jdpi.awt.Image;

public void ImageObserverWrapper {
    public java.awt.image.ImageObserver wrap(final ImageObserver observer) {
        return new java.awt.image.ImageObserver() {
            public boolean imageUpdate(java.awt.Image img, int infoflags, int x, int y, int width, int height) {
                if (img instanceof BufferedImage) {
                    observer.imageUpdate((BufferedImage) imf, infoflags, x, y, width, height);
                }
            }
        };
    }
}