package jdpi.awt.image;

import jdpi.awt.Image;

public interface ImageObserver extends java.awt.image.ImageObserver {
    public boolean imageUpdate(Image img, int infoflags, int x, int y, int width, int height);
}