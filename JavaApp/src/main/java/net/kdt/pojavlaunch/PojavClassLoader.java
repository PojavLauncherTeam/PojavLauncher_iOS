package net.kdt.pojavlaunch;

import java.net.*;

/**
 * This class loader is used as system class loader
 * as a workaround to modded libraries for Java 8
 * compatibility that safety casting to URLClassLoader:
 * ((URLClassLoader) ClassLoader.getSystemClassLoader())
 */
public class PojavClassLoader extends URLClassLoader {
    public PojavClassLoader(ClassLoader parent) {
        super(new URL[0], parent);
    }
    
    @Override
    public void addURL(URL url) {
        super.addURL(url);
    }
}