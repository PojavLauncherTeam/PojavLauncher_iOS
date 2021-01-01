#include "JavaLauncher.h"

int main(int argc, char * argv[]) {
    if (!started) {
        first_argc = argc;
        first_argv = argv;
    }
    launchJVM(argc, argv);
}
