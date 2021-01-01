#pragma once

static bool started = false;

static int first_argc;
static char *first_argv[];

int launchJVM(int argc, char *argv[]);
int launchUI();
