package com.mojang.text2speech;

public class NarratorDummy implements Narrator {
    @Override
    public void say(final String msg, final boolean interrupt) {
    }

    @Override
    public void clear() {
    }

    @Override
    public boolean active() {
        return false;
    }

    @Override
    public void destroy() {

    }
}
