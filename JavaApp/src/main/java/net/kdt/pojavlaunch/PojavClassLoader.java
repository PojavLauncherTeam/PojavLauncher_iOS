package net.kdt.pojavlaunch;

import java.io.File;
import java.io.IOException;
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
        try {
            System.setProperty("java.class.path", System.getProperty("java.class.path") + ":" + new File(url.toURI()).getAbsolutePath());
        } catch (URISyntaxException e) {
            e.printStackTrace();
        }
    }

    static URL getFileURL(File file) {
        try {
            file = file.getCanonicalFile();
        } catch (IOException e) {}

        try {
            return file.toURL();
        } catch (MalformedURLException e) {
            // Should never happen since we specify the protocol...
            throw new InternalError(e);
        }
    }

    /**
     * This class loader supports dynamic additions to the class path
     * at runtime.
     *
     * @see java.lang.instrument.Instrumentation#appendToSystemClassPathSearch
     */
    private void appendToClassPathForInstrumentation(String path) {
        assert(Thread.holdsLock(this));

        // addURL is a no-op if path already contains the URL
        super.addURL(getFileURL(new File(path)));
    }
}