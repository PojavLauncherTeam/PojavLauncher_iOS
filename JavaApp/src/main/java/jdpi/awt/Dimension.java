package jdpi.awt;

public class Dimension extends java.awt.Dimension {
    public Dimension() {
        this(0, 0);
    }

    public Dimension(Dimension d) {
        this(d.width, d.height);
    }

    public Dimension(int width, int height) {
        super(width, height);
    }
}
