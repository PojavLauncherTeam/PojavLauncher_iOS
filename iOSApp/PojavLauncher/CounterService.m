//
//  CounterService.m
//

#import "jni.h"
#import "CounterService.h"

static JavaVM *vm;
static jclass counterServiceClass;
static jmethodID increaseMethod;
static jmethodID getCountMethod;

@implementation CounterService

+ (void)init {

  JavaVMInitArgs vm_args;
  vm_args.version = JNI_VERSION_1_2;
  vm_args.nOptions = 0;
  vm_args.options = NULL;

  jint res;
  JNIEnv *env;
  res = JNI_CreateJavaVM(&vm, &env, &vm_args);
  if (res != JNI_OK) {
    [NSException raise:@"JNI_CreateJavaVM() failed" format:@"%d", res];
  }

  counterServiceClass = (*env)->FindClass(env, "org/robovm/samples/myjavaframework/CounterService");
  if (!counterServiceClass) {
    [NSException raise:@"Failed to find class org.robovm.samples.myjavaframework.CounterService" format:@""];
  }
  increaseMethod = (*env)->GetStaticMethodID(env, counterServiceClass, "increase", "()I");
  if (!increaseMethod) {
    [NSException raise:@"Failed to find method org.robovm.samples.myjavaframework.CounterService.increase()I" format:@""];
  }
  getCountMethod = (*env)->GetStaticMethodID(env, counterServiceClass, "getCount", "()I");
  if (!getCountMethod) {
    [NSException raise:@"Failed to find method org.robovm.samples.myjavaframework.CounterService.getCount()I" format:@""];
  }
}

+ (int)increase {
  // Calls CounterService.increase()
  JNIEnv *env;
  jint res = (*vm)->AttachCurrentThread(vm, (void**) &env, NULL);
  if (res != JNI_OK) {
    [NSException raise:@"AttachCurrentThread() failed" format:@"%d", res];
  }
  jint result = (*env)->CallStaticIntMethod(env, counterServiceClass, increaseMethod);
  (*vm)->DetachCurrentThread(vm);
  return result;
}

+ (int)getCount {
  // Calls CounterService.getCount()
  JNIEnv *env;
  jint res = (*vm)->AttachCurrentThread(vm, (void**) &env, NULL);
  if (res != JNI_OK) {
    [NSException raise:@"AttachCurrentThread() failed" format:@"%d", res];
  }
  jint result = (*env)->CallStaticIntMethod(env, counterServiceClass, getCountMethod);
  (*vm)->DetachCurrentThread(vm);
  return result;
}

@end
