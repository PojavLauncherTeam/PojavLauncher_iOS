#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

#define LOGE(...) printf(__VA_ARGS__)
#define LOGW(...) printf(__VA_ARGS__)
#define LOGI(...) printf(__VA_ARGS__)
#define LOGD(...) printf(__VA_ARGS__)

#ifdef DEBUG
# define DEBUG_LOGE(...) LOGE(__VA_ARGS__)
# define DEBUG_LOGW(...) LOGW(__VA_ARGS__)
# define DEBUG_LOGI(...) LOGI(__VA_ARGS__)
# define DEBUG_LOGD(...) LOGD(__VA_ARGS__)
#else
# define DEBUG_LOGE(...)
# define DEBUG_LOGW(...)
# define DEBUG_LOGI(...)
# define DEBUG_LOGD(...)
#endif

void regLog(const char *message, ...) __attribute__((format(printf, 1, 2)));
void debugLog(const char *message, ...) __attribute__((format(printf, 1, 2)));

#ifdef __cplusplus
}
#endif

