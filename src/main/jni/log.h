#ifdef __ANDROID__
#include <android/log.h>

#define TAG "LaunchJVM"
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define LOGE(...) printf(__VA_ARGS__)
#define LOGW(...) printf(__VA_ARGS__)
#define LOGI(...) printf(__VA_ARGS__)
#define LOGD(...) printf(__VA_ARGS__)

#ifdef __cplusplus
}
#endif

