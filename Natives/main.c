#include <unistd.h>
#include <stdio.h>
#include "JavaLauncher.h"

int main(int argc, char * argv[]) {
    if (getppid() != 1) {
        // Not running from launchd, so UI won't work.
        printf("ERROR: ppid was %d\n", getppid());
        printf("ERROR: UIKit could not be connected when run on command line! Please run from home screen instead. If you didn't see PojavLauncher on home screen, run this command:\n");
        printf("uicache -p /Applications/PojavLauncher.app\n");

        return -1;
    }
    launchJVM(argc, argv);
}
