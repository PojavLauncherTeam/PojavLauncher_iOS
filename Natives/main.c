#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "JavaLauncher.h"

int main(int argc, char * argv[]) {
    if (getppid() != 1) {
        // Not running from launchd, so UI won't work.
        printf("ERROR: ppid was %d\n", getppid());
        printf("ERROR: UIKit is unavailable when run on command line! Please run from home screen instead. If you didn't see PojavLauncher on home screen, run this command:\n");
        printf("uicache -p /Applications/PojavLauncher.app\n");

        return -1;
    }

    launchJVM(argc, argv);

    return 0;
}
