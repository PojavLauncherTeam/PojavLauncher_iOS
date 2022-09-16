#import "JavaGUIViewController.h"
#import "JavaLauncher.h"
#import "LauncherPreferences.h"
#import "ios_uikit_bridge.h"
#include "utils.h"

static int* rgbArray;
SurfaceView* surfaceView;

jclass class_CTCAndroidInput;
jmethodID method_ReceiveInput;

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_refreshAWTBuffer(JNIEnv* env, jclass clazz, jintArray jreRgbArray) {
    if (!runtimeJNIEnvPtr) {
        dispatch_async(dispatch_get_main_queue(), ^{
            (*runtimeJavaVMPtr)->AttachCurrentThread(runtimeJavaVMPtr, &runtimeJNIEnvPtr, NULL);
        });
    }

    int *tmpArray = (*env)->GetIntArrayElements(env, jreRgbArray, 0);
    memcpy(rgbArray, tmpArray, windowWidth * windowHeight * 4);
    (*env)->ReleaseIntArrayElements(env, jreRgbArray, tmpArray, JNI_ABORT);
    dispatch_async(dispatch_get_main_queue(), ^{
        [surfaceView displayLayer];
    });
}

@implementation SurfaceView
const void * _CGDataProviderGetBytePointerCallbackAWT(void *info) {
	return (const void *)rgbArray;
}
   
- (void)displayLayer {
    CGDataProviderRef bitmapProvider = CGDataProviderCreateDirect(NULL, windowWidth * windowHeight * 4, &callbacks);
    CGImageRef bitmap = CGImageCreate(windowWidth, windowHeight, 8, 32, 4 * windowWidth, colorSpace, kCGImageAlphaFirst | kCGBitmapByteOrder32Little, bitmapProvider, NULL, FALSE, kCGRenderingIntentDefault);     

    self.layer.contents = (__bridge id) bitmap;
    CGImageRelease(bitmap);
    CGDataProviderRelease(bitmapProvider);
   //  CGColorSpaceRelease(colorSpace);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    self.layer.opaque = YES;

    colorSpace = CGColorSpaceCreateDeviceRGB();

    callbacks.version = 0;
    callbacks.getBytePointer = _CGDataProviderGetBytePointerCallbackAWT;
    callbacks.releaseBytePointer = _CGDataProviderReleaseBytePointerCallback;
    callbacks.getBytesAtPosition = NULL;
    callbacks.releaseInfo = NULL;

    return self;
}
@end

@interface JavaGUIViewController ()<UIGestureRecognizerDelegate, UIScrollViewDelegate> {
}

// - (void)method

@end

@implementation JavaGUIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height);
    float resolution = [getPreference(@"resolution") floatValue] / 100.0;

    windowWidth = roundf(width * screenScale * resolution);
    windowHeight = roundf(height * screenScale * resolution);

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.delegate = self;
    scrollView.minimumZoomScale = 1;
    scrollView.maximumZoomScale = 5;
    scrollView.zoomScale = 1;

    surfaceView = [[SurfaceView alloc] initWithFrame:self.view.frame];
    [scrollView addSubview:surfaceView];

    [self.view addSubview:scrollView];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnClick:)];
    tapGesture.delegate = self;
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    tapGesture.cancelsTouchesInView = NO;
    [surfaceView addGestureRecognizer:tapGesture];

    rgbArray = calloc(4, (size_t) (windowWidth * windowHeight));

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        launchJVM(nil, self.filepath, windowWidth, windowHeight, 8);
    });
}

- (void)surfaceOnClick:(UITapGestureRecognizer *)sender {
    if (runtimeJNIEnvPtr == NULL) {
        return;
    }

    if (method_ReceiveInput == NULL) {
        class_CTCAndroidInput = (*runtimeJNIEnvPtr)->FindClass(runtimeJNIEnvPtr, "net/java/openjdk/cacio/ctc/CTCAndroidInput");
        if ((*runtimeJNIEnvPtr)->ExceptionCheck(runtimeJNIEnvPtr) == JNI_TRUE) {
            (*runtimeJNIEnvPtr)->ExceptionClear(runtimeJNIEnvPtr);
            class_CTCAndroidInput = (*runtimeJNIEnvPtr)->FindClass(runtimeJNIEnvPtr, "com/github/caciocavallosilano/cacio/ctc/CTCAndroidInput");
        }
        assert(class_CTCAndroidInput != NULL);
        method_ReceiveInput = (*runtimeJNIEnvPtr)->GetStaticMethodID(runtimeJNIEnvPtr, class_CTCAndroidInput, "receiveData", "(IIIII)V");
        assert(method_ReceiveInput != NULL);
    }

    if (sender.state == UIGestureRecognizerStateRecognized) {
        float resolution = ((NSNumber *)getPreference(@"resolution")).floatValue / 100.0;
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGPoint location = [sender locationInView:sender.view];
        CGFloat x = location.x * screenScale * resolution;
        CGFloat y = location.y * screenScale * resolution;
        (*runtimeJNIEnvPtr)->CallStaticVoidMethod(
            runtimeJNIEnvPtr,
            class_CTCAndroidInput,
            method_ReceiveInput,
            EVENT_TYPE_CURSOR_POS, (int)x, (int)y, 0, 0
        );
        (*runtimeJNIEnvPtr)->CallStaticVoidMethod(
            runtimeJNIEnvPtr,
            class_CTCAndroidInput,
            method_ReceiveInput,
            EVENT_TYPE_MOUSE_BUTTON, BUTTON1_DOWN_MASK, 1, 0, 0
        );
        (*runtimeJNIEnvPtr)->CallStaticVoidMethod(
            runtimeJNIEnvPtr,
            class_CTCAndroidInput,
            method_ReceiveInput,
            EVENT_TYPE_MOUSE_BUTTON, BUTTON1_DOWN_MASK, 0, 0, 0
        );
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return surfaceView;
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeBottom;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return NO;
}

@end
