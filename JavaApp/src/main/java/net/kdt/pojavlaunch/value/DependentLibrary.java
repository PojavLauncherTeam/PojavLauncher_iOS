package net.kdt.pojavlaunch.value;

public class DependentLibrary {
    public boolean _skip; // internal
    //public ArgRules[] rules;
    public String name;
    public LibraryDownloads downloads;
    public String url;
    
    public static class LibraryDownloads {
        public MinecraftLibraryArtifact artifact;
        public LibraryDownloads(MinecraftLibraryArtifact artifact) {
            this.artifact = artifact;
        }
    }
}

