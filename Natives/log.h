#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void regLog(const char *message, ...) __attribute__((format(printf, 1, 2)));
void debugLog(const char *message, ...) __attribute__((format(printf, 1, 2)));

#ifdef __cplusplus
}
#endif

