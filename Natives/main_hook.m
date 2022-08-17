#include <dlfcn.h>
#include <fnmatch.h>
#include <libgen.h>
#include <spawn.h>
#include <stdio.h>

#include "external/fishhook/fishhook.h"
#import "utils.h"

int main(int argc, char * argv[]);

static CFRunLoopRunResult (*orig_CFRunLoopRunInMode)(CFRunLoopMode mode, CFTimeInterval seconds, Boolean returnAfterSourceHandled);

static int (*orig_dladdr)(const void* addr, Dl_info* info);
static void* (*orig_dlopen)(const char* path, int mode);
//static void* (*orig_mmap)(void *addr, size_t len, int prot, int flags, int fd, off_t offset);
static char* (*orig_realpath)(const char *restrict path, char *restrict resolved_path);
pid_t (*orig_waitpid)(pid_t pid, int *status, int options);
//static void (*orig_sys_icache_invalidate)(void *start, size_t len);


int hooked_dladdr(const void* addr, Dl_info* info) {
    //NSLog(@"hook dladdr(%p, %p)", addr, info);
    int retVal = orig_dladdr(addr, info);
    if (addr == main) {
        //NSLog(@"hooked dladdr");
        info->dli_fname = getenv("JAVA_EXT_EXECNAME");
    } else if (retVal != 0) {
        //NSLog(@"hooked dladdr");
        char *libname = basename((char *)info->dli_fname);
        char src[2048], dst[2048];
        sprintf((char *)src, "%s/Frameworks", getenv("BUNDLE_PATH"));
        if (0 == strncmp(info->dli_fname, src, strlen(src))) {
            if (0 == strncmp(libname, "libjli.dylib", 12)) {
                info->dli_fname = getenv("INTERNAL_JLI_PATH");
            } else if (0 == strncmp(libname, "libjvm.dylib", 12)) {
                sprintf((char *)dst, "%s/lib/server/libjvm.dylib", getenv("JAVA_HOME"));
                info->dli_fname = (char *)dst;
            }
        }
    }
    //if (retVal) NSLog(@"dli_fname=%s", info->dli_fname);
    return retVal;
}

void* hooked_dlopen(const char* path, int mode) {
    //NSLog(@"dlopen(%s, %d)", path, mode);

    // Avoid loading the executable itself twice
    if (path && [@(path) hasSuffix:@"PojavLauncher"]) {
        return orig_dlopen(NULL, mode);
    }

    return orig_dlopen(path, mode);

}

/*
void *hooked_mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset) {
    NSLog(@"mmap(%p, %ld, %d, %d, %d, %lld)", addr, len, prot, flags, fd, offset);

    if (flags & MAP_JIT) {
        NSLog(@"'-> Found JIT mmap");
        //flags &= ~MAP_JIT;
    }

    // raise(SIGINT);
    return orig_mmap(addr, len, prot, flags, fd, offset);
}
*/

char *hooked_realpath(const char *restrict path, char *restrict resolved_path) {
    //NSLog(@"hook realpath %s", path);
    const char *javaHome = getenv("JAVA_HOME");
    if (0 == strncmp(path, javaHome, strlen(javaHome))) {
        strcpy(resolved_path, path);
        return resolved_path;
    } else {
        return orig_realpath(path, resolved_path);
    }
}

/*
void hooked_sys_icache_invalidate(void *start, size_t len) {
    // mprotect(start, 16384, PROT_EXEC | PROT_READ);
    // NSLog(@"mprotect errno %d", errno);
    orig_sys_icache_invalidate(start, len);
}
*/

void init_hookFunctions() {
    // if (!started && strncmp(argv[0], "/Applications", 13)) 
    // Jailed only: hook some functions for symlinked JRE home dir
    int retval = rebind_symbols((struct rebinding[3]){
        {"dladdr", hooked_dladdr, (void *)&orig_dladdr},
        {"dlopen", hooked_dlopen, (void *)&orig_dlopen}, 
        //{"realpath", hooked_realpath, (void *)&orig_realpath},
        {"realpath$DARWIN_EXTSN", hooked_realpath, (void *)&orig_realpath}
        //{"mmap", hooked_mmap, (void *)&orig_mmap},
        //{"sys_icache_invalidate", hooked_sys_icache_invalidate, (void *)&orig_sys_icache_invalidate}
    }, 3);
    NSLog(@"hook retval = %d", retval);
}
