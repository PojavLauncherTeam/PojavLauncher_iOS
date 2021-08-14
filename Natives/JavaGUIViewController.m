#import "JavaGUIViewController.h"
#import "LauncherPreferences.h"
#import "ios_uikit_bridge.h"
#include "utils.h"

static int* rgbArray;
SurfaceView* surfaceView;

jclass class_CTCAndroidInput;
jmethodID method_ReceiveInput;

JNIEXPORT void JNICALL Java_net_kdt_pojavlaunch_uikit_UIKit_refreshAWTBuffer(JNIEnv* env, jclass clazz, jintArray jreRgbArray) {
    int *tmpArray = (*env)->GetIntArrayElements(env, jreRgbArray, 0);
    memcpy(rgbArray, tmpArray, savedWidth * savedHeight * 4);
    (*env)->ReleaseIntArrayElements(env, jreRgbArray, tmpArray, JNI_ABORT);
    dispatch_async(dispatch_get_main_queue(), ^{
        [surfaceView displayLayer:surfaceView.layer];
    });
}

@implementation SurfaceView
const void * _CGDataProviderGetBytePointerCallback(void *info) {
	return (const void *)rgbArray;
}

void _CGDataProviderReleaseBytePointerCallback(void *info,const void *pointer) {
}
   
- (void)displayLayer:(CALayer *)theLayer
{
    CGDataProviderRef bitmapProvider = CGDataProviderCreateDirect(NULL, savedWidth * savedHeight * 4, &callbacks);
    CGImageRef bitmap = CGImageCreate(savedWidth, savedHeight, 8, 32, 4 * savedWidth, colorSpace, kCGImageAlphaFirst | kCGBitmapByteOrder32Little, bitmapProvider, NULL, FALSE, kCGRenderingIntentDefault);     

    theLayer.contents = (__bridge id) bitmap;
    CGImageRelease(bitmap);
    CGDataProviderRelease(bitmapProvider);
   //  CGColorSpaceRelease(colorSpace);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    layer = [self layer];
    layer.opaque = YES;

    colorSpace = CGColorSpaceCreateDeviceRGB();

    callbacks.version = 0;
    callbacks.getBytePointer = _CGDataProviderGetBytePointerCallback;
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
    viewController = self;
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height);
    float resolution = ((NSNumber *)getPreference(@"resolution")).floatValue / 100.0;

    savedWidth = roundf(width * screenScale * resolution);
    savedHeight = roundf(height * screenScale * resolution);

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.delegate = self;
    scrollView.minimumZoomScale = 1;
    scrollView.maximumZoomScale = 5;
    scrollView.zoomScale = 1;

    surfaceView = [[SurfaceView alloc] initWithFrame:self.view.frame];
    [scrollView addSubview:surfaceView];

    [self.view addSubview:scrollView];

    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnClick:)];
    tapGesture.delegate = self;
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    tapGesture.cancelsTouchesInView = NO;
    [surfaceView addGestureRecognizer:tapGesture];

    rgbArray = calloc(4, (size_t) (savedWidth * savedHeight));

    UIKit_launchJarFile(self.filepath.UTF8String);
}

- (void)surfaceOnClick:(UITapGestureRecognizer *)sender {
    if (method_ReceiveInput == NULL) {
        class_CTCAndroidInput = (*runtimeJNIEnvPtr_JRE)->FindClass(runtimeJNIEnvPtr_JRE, "net/java/openjdk/cacio/ctc/CTCAndroidInput");
        assert(class_CTCAndroidInput != NULL);
        method_ReceiveInput = (*runtimeJNIEnvPtr_JRE)->GetStaticMethodID(runtimeJNIEnvPtr_JRE, class_CTCAndroidInput, "receiveData", "(IIIII)V");
        assert(method_ReceiveInput != NULL);
    }

    if (sender.state == UIGestureRecognizerStateRecognized) {
        float resolution = ((NSNumber *)getPreference(@"resolution")).floatValue / 100.0;
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGPoint location = [sender locationInView:sender.view];
        CGFloat x = location.x * screenScale * resolution;
        CGFloat y = location.y * screenScale * resolution;
        (*runtimeJNIEnvPtr_JRE)->CallStaticVoidMethod(
            runtimeJNIEnvPtr_JRE,
            class_CTCAndroidInput,
            method_ReceiveInput,
            EVENT_TYPE_CURSOR_POS, (int)x, (int)y, 0, 0
        );
        (*runtimeJNIEnvPtr_JRE)->CallStaticVoidMethod(
            runtimeJNIEnvPtr_JRE,
            class_CTCAndroidInput,
            method_ReceiveInput,
            EVENT_TYPE_MOUSE_BUTTON, BUTTON1_DOWN_MASK, 1, 0, 0
        );
        (*runtimeJNIEnvPtr_JRE)->CallStaticVoidMethod(
            runtimeJNIEnvPtr_JRE,
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

-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if(@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            self.view.backgroundColor = [UIColor blackColor];
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
    }
}

@end
