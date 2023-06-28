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

// Signatures to search for
char mmapSig[] = {0xB0, 0x18, 0x80, 0xD2, 0x01, 0x10, 0x00, 0xD4};
char fcntlSig[] = {0x90, 0x0B, 0x80, 0xD2, 0x01, 0x10, 0x00, 0xD4};

extern void* __mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset);
extern int __fcntl(int fildes, int cmd, void* param);

// Since we're patching libsystem_kernel, we must avoid calling to its functions
static void builtin_memcpy(char *target, char *source, size_t size) {
    for (int i = 0; i < size; i++) {
        target[i] = source[i];
    }
}

kern_return_t builtin_vm_protect(mach_port_name_t task, mach_vm_address_t address, mach_vm_size_t size, boolean_t set_max, vm_prot_t new_prot);
// Originated from _kernelrpc_mach_vm_protect_trap
ASM(_builtin_vm_protect: \n
    mov x16, #-0xe       \n
    svc #0x80            \n
    ret
);

bool redirectFunction(char *name, void *patchAddr, void *target) {
    kern_return_t kret = builtin_vm_protect(mach_task_self(), (vm_address_t)patchAddr, sizeof(patch), false, PROT_READ | PROT_WRITE | VM_PROT_COPY);
    if (kret != KERN_SUCCESS) {
        NSDebugLog(@"[DyldLVBypass] vm_protect(RW) fails at line %d", __LINE__);
        return FALSE;
    }
    
    builtin_memcpy((char *)patchAddr, patch, sizeof(patch));
    *(void **)((char*)patchAddr + 16) = target;
    
    kret = builtin_vm_protect(mach_task_self(), (vm_address_t)patchAddr, sizeof(patch), false, PROT_READ | PROT_EXEC);
    if (kret != KERN_SUCCESS) {
        NSDebugLog(@"[DyldLVBypass] vm_protect(RX) fails at line %d", __LINE__);
        return FALSE;
    }
    
    NSDebugLog(@"[DyldLVBypass] hook %s succeed!", name);
    return TRUE;
}

bool searchAndPatch(char *name, char *base, char *signature, int length, void *target) {
    char *patchAddr = NULL;
    kern_return_t kret;
    
    for(int i=0; i < 0x100000; i++) {
        if (base[i] == signature[0] && memcmp(base+i, signature, length) == 0) {
            patchAddr = base + i;
            break;
        }
    }
    
    if (patchAddr == NULL) {
        NSDebugLog(@"[DyldLVBypass] hook fails line %d", __LINE__);
        return FALSE;
    }
    
    NSDebugLog(@"[DyldLVBypass] found %s at %p", name, patchAddr);
    return redirectFunction(name, patchAddr, target);
}

void *getDyldBase(void) {
    struct task_dyld_info dyld_info;
    mach_vm_address_t image_infos;
    struct dyld_all_image_infos *infos;
    
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    kern_return_t ret;
    
    ret = task_info(mach_task_self_,
                    TASK_DYLD_INFO,
                    (task_info_t)&dyld_info,
                    &count);
    
    if (ret != KERN_SUCCESS) {
        return NULL;
    }
    
    image_infos = dyld_info.all_image_info_addr;
    
    infos = (struct dyld_all_image_infos *)image_infos;
    return (void *)infos->dyldImageLoadAddress;
}

void* hooked_mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset) {
    char filePath[PATH_MAX];
    memset(filePath, 0, sizeof(filePath));
    
    // Check if the file is our "in-memory" file
    if (fd && __fcntl(fd, F_GETPATH, filePath) != -1) {
        const char *homeDir = getenv("POJAV_HOME");
        if (!strncmp(filePath, homeDir, strlen(homeDir))) {
            int newFlags = MAP_PRIVATE | MAP_ANONYMOUS;
            if (addr != 0) {
                newFlags |= MAP_FIXED;
            }
            void *alloc = __mmap(addr, len, PROT_READ | PROT_WRITE, newFlags, 0, 0);
            
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

int hooked___fcntl(int fildes, int cmd, void *param) {
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

int hooked_fcntl(int fildes, int cmd, ...) {
    va_list ap;
    va_start(ap, cmd);
    void *param = va_arg(ap, void *);
    va_end(ap);
    return hooked___fcntl(fildes, cmd, param);
}

void init_bypassDyldLibValidation() {
    static BOOL bypassed;
    if (bypassed) return;
    bypassed = YES;

    NSDebugLog(@"[DyldLVBypass] init");
    
    // Modifying exec page during execution may cause SIGBUS, so ignore it now
    // Before calling JLI_Launch, this will be set back to SIG_DFL
    signal(SIGBUS, SIG_IGN);
    
    char *dyldBase = getDyldBase();
    redirectFunction("mmap", mmap, hooked_mmap);
    redirectFunction("fcntl", fcntl, hooked_fcntl);
    searchAndPatch("dyld_mmap", dyldBase, mmapSig, sizeof(mmapSig), hooked_mmap);
    searchAndPatch("dyld_fcntl", dyldBase, fcntlSig, sizeof(fcntlSig), hooked___fcntl);
}
