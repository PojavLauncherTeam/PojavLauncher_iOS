// Based on: https://blog.xpnsec.com/restoring-dyld-memory-loading
// https://github.com/xpn/DyldDeNeuralyzer/blob/main/DyldDeNeuralyzer/DyldPatch/dyldpatch.m

#import <Foundation/Foundation.h>

#include <dlfcn.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <sys/syscall.h>

#include "utils.h"

#define ASM(...) __asm__(#__VA_ARGS__)
// ldr x8, value; br x8; value: .ascii "\x41\x42\x43\x44\x45\x46\x47\x48"
char patch[] = {0x88,0x00,0x00,0x58,0x00,0x01,0x1f,0xd6,0x1f,0x20,0x03,0xd5,0x1f,0x20,0x03,0xd5,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41};

extern void* __mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset);
extern int __fcntl(int fildes, int cmd, void* param);

// Since we're patching libSystem, we must avoid calling to it
int builtin_cerror_nocancel(int err) {
    errno = err; // FIXME: rewrite this to asm
    return err ? -1 : 0;
}

static void builtin_memcpy(char *target, char *source, size_t size) {
    for (int i = 0; i < size; i++) {
        target[i] = source[i];
    }
}

int builtin_mprotect(void *addr, size_t len, int prot);
ASM(_builtin_mprotect:              \n
    mov x16, #0x4a                  \n
    svc #0x80                       \n
    b.lo #24                        \n
    stp x29, x30, [sp, #-0x10]!     \n
    mov x29, sp                     \n
    bl _builtin_cerror_nocancel     \n
    mov sp, x29                     \n
    ldp x29, x30, [sp], 0x10        \n
    ret
);

bool redirectFunction(void *patchAddr, void *target) {
    kern_return_t kret = vm_protect(mach_task_self(), (vm_address_t)patchAddr, sizeof(patch), false, PROT_READ | PROT_WRITE | VM_PROT_COPY);
    if (kret != KERN_SUCCESS) {
        NSDebugLog(@"[DyldLVBypass] vm_protect(RW) fails at line %d", __LINE__);
        return FALSE;
    }
    
    builtin_memcpy((char *)patchAddr, patch, sizeof(patch));
    *(void **)((char*)patchAddr + 16) = target;
    
    kret = builtin_mprotect((void *)((uint64_t)patchAddr & -PAGE_SIZE), PAGE_SIZE, PROT_READ | PROT_EXEC);
    //vm_protect(mach_task_self(), (vm_address_t)patchAddr, sizeof(patch), false, PROT_READ | PROT_EXEC);
    if (kret != KERN_SUCCESS) {
        NSDebugLog(@"[DyldLVBypass] mprotect(RX) fails at line %d", __LINE__);
        return FALSE;
    }
    
    NSDebugLog(@"[DyldLVBypass] hook %p succeed!", patchAddr);
    return TRUE;
}

void* hooked_mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset) {
    const char *homeDir = getenv("POJAV_HOME");
    void *alloc;
    char filePath[PATH_MAX];
    int newFlags;
    memset(filePath, 0, sizeof(filePath));
    
    // Check if the file is our "in-memory" file
    if (__fcntl(fd, F_GETPATH, filePath) != -1) {
        if (!strncmp(filePath, homeDir, strlen(homeDir))) {
            newFlags = MAP_PRIVATE | MAP_ANONYMOUS;
            if (addr != 0) {
                newFlags |= MAP_FIXED;
            }
            alloc = __mmap(addr, len, PROT_READ | PROT_WRITE, newFlags, 0, 0);
            
            void *memoryLoadedFile = __mmap(NULL, len, PROT_READ, MAP_PRIVATE, fd, offset);
            memcpy(alloc, memoryLoadedFile, len);
            munmap(memoryLoadedFile, len);
            
            //vm_protect(mach_task_self(), (vm_address_t)alloc, len, false, prot);
            mprotect(alloc, len, prot);
            return alloc;
        }
    }
    
    // If for another file, we pass through
    return __mmap(addr, len, prot, flags, fd, offset);
}

int hooked_fcntl(int fildes, int cmd, ...) {
    va_list ap;
    va_start(ap, cmd);
    void *param = va_arg(ap, void *);
    va_end(ap);
    
    if (cmd == F_ADDFILESIGS_RETURN) {
        const char *homeDir = getenv("POJAV_HOME");
        char filePath[PATH_MAX];
        memset(filePath, 0, sizeof(filePath));
        
        // Check if the file is our "in-memory" file
        if (__fcntl(fildes, F_GETPATH, filePath) != -1) {
            if (!strncmp(filePath, homeDir, strlen(homeDir))) {
                fsignatures_t *fsig = (fsignatures_t*)param;
                // called to check that cert covers file.. so we'll make it cover everything ;)
                fsig->fs_file_start = 0xFFFFFFFF;
                return 0;
            }
        }
    }
    
    // Signature sanity check by dyld
    else if (cmd == F_CHECK_LV) {
        // Just say everything is fine
        return 0;
    }
    
    // If for another command or file, we pass through
    return __fcntl(fildes, cmd, param);
}

void init_bypassDyldLibValidation() {
    NSDebugLog(@"[DyldLVBypass] init");
    dispatch_async(dispatch_get_main_queue(), ^{
        // Prevent main thread from executing stuff inside the memory page being modified
        usleep(10000);
    });
    redirectFunction(mmap, hooked_mmap);
    redirectFunction(fcntl, hooked_fcntl);
}
