#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

#define LOGE(...) printf(__VA_ARGS__)
#define LOGW(...) printf(__VA_ARGS__)
#define LOGI(...) printf(__VA_ARGS__)
#define LOGD(...) printf(__VA_ARGS__)

void debug(const char *message, ...) __attribute__((format(printf, 1, 2)));

#ifdef __cplusplus
}
#endif

