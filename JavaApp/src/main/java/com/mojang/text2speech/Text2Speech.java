package com.mojang.text2speech;

public class Text2Speech {
    public static void main(final String[] args) {
        System.setProperty("jna.library.path", "./src/natives/resources/");
        final Narrator narrator = Narrator.getNarrator();
        narrator.say("This is a test", false);

        while (true) {
            try {
                Thread.sleep(100);
            } catch (final InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
