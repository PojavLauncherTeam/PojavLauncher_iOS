#import "customcontrols/ControlLayout.h"
#import "customcontrols/CustomControlsUtils.h"
#import "JavaGUIViewController.h"
#import "JavaLauncher.h"
#import "LauncherPreferences.h"
#import "TrackedTextField.h"
#import "ios_uikit_bridge.h"
#include "glfw_keycodes.h"
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

void AWTInputBridge_nativeSendData(int type, int i1, int i2, int i3, int i4) {
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

    (*runtimeJNIEnvPtr)->CallStaticVoidMethod(
        runtimeJNIEnvPtr,
        class_CTCAndroidInput,
        method_ReceiveInput,
        type, i1, i2, i3, i4
    );
}

void AWTInputBridge_sendChar(jchar keychar) {
    AWTInputBridge_nativeSendData(EVENT_TYPE_CHAR, (unsigned int)keychar, 0, 0, 0);
}

void AWTInputBridge_sendKey(int keycode) {
    // TODO: iOS -> AWT keycode mapping
    AWTInputBridge_nativeSendData(EVENT_TYPE_KEY, 0, keycode, 0, 0);
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

@property BOOL virtualMouseEnabled;
@property CGRect virtualMouseFrame;
@property(nonatomic) TrackedTextField* inputTextField;
@property(nonatomic) UIImageView* mousePointerView;
@property(nonatomic) ControlLayout* ctrlView;

@end

@implementation JavaGUIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];

    CGRect screenBounds = self.view.bounds;
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height);
    float resolution = [getPreference(@"resolution") floatValue] / 100.0;

    windowWidth = roundf(width * screenScale * resolution);
    windowHeight = roundf(height * screenScale * resolution);

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    scrollView.delegate = self;
    scrollView.minimumZoomScale = 1;
    scrollView.maximumZoomScale = 5;
    scrollView.scrollEnabled = YES; // will be NO later for virtual mouse/touch
    scrollView.zoomScale = 1;

    surfaceView = [[SurfaceView alloc] initWithFrame:self.view.frame];
    [scrollView addSubview:surfaceView];

    [self.view addSubview:scrollView];

    self.inputTextField = [[TrackedTextField alloc] initWithFrame:CGRectMake(0, -32.0, self.view.frame.size.width, 30.0)];
    if (@available(iOS 13.0, *)) {
        self.inputTextField.backgroundColor = UIColor.secondarySystemBackgroundColor;
    } else {
        self.inputTextField.backgroundColor = UIColor.groupTableViewBackgroundColor;
    }
    self.inputTextField.font = [UIFont fontWithName:@"Menlo-Regular" size:20];
    self.inputTextField.clearsOnBeginEditing = YES;
    self.inputTextField.textAlignment = NSTextAlignmentCenter;
    self.inputTextField.sendChar = ^(jchar keychar){
        AWTInputBridge_sendChar(keychar);
    };
    self.inputTextField.sendKey = ^(int key, int scancode, int action, int mods) {
        if (action == 0) return;
        switch (key) {
            case GLFW_KEY_BACKSPACE:
                AWTInputBridge_sendKey('\b'); // VK_BACK_SPACE
                break;
            case GLFW_KEY_DPAD_LEFT:
                AWTInputBridge_sendKey(0xE2); // VK_KP_LEFT;
                break;
            case GLFW_KEY_DPAD_RIGHT:
                AWTInputBridge_sendKey(0xE3); // VK_KP_RIGHT;
                break;
        }
    };
    [self.view addSubview:self.inputTextField];

    self.virtualMouseEnabled = NO;
    //[getPreference(@"virtmouse_enable") boolValue];
    scrollView.bounces = !self.virtualMouseEnabled;
    self.virtualMouseFrame = CGRectMake(screenBounds.size.width / 2, screenBounds.size.height / 2, 18, 27);
    self.mousePointerView = [[UIImageView alloc] initWithFrame:self.virtualMouseFrame];
    self.mousePointerView.hidden = !self.virtualMouseEnabled;
    self.mousePointerView.image = [UIImage imageNamed:@"MousePointer"];
    self.mousePointerView.userInteractionEnabled = NO;
    [self.view addSubview:self.mousePointerView];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(surfaceOnClick:)];
    tapGesture.delegate = self;
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    tapGesture.cancelsTouchesInView = NO;
    [surfaceView addGestureRecognizer:tapGesture];

    // Borrowing custom controls, might be useful later (full-blown jar launcher with control support?)
    self.ctrlView = [[ControlLayout alloc] initWithFrame:UIEdgeInsetsInsetRect(self.view.frame, self.view.safeAreaInsets)];
    [self.view addSubview:self.ctrlView];
    [self loadCustomControls];

    rgbArray = calloc(4, (size_t) (windowWidth * windowHeight));

    setenv("POJAV_SKIP_JNI_GLFW", "1", 1);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        launchJVM(nil, self.filepath, windowWidth, windowHeight, 8);
    });
}

- (void)loadCustomControls {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"version"] = @(4);
    dict[@"scaledAt"] = @(100);
    dict[@"mControlDataList"] = [[NSMutableArray alloc] init];
    //dict[@"mDrawerDataList"] = [[NSMutableArray alloc] init];
    [dict[@"mControlDataList"] addObject:createButton(@"Keyboard",
        (int[]){SPECIALBTN_KEYBOARD,0,0,0},
        @"${margin}", @"${margin}",
        BTN_RECT
    )];
#if 0 // WIP: virtual mouse
    [dict[@"mControlDataList"] addObject:createButton(@"Mouse",
        (int[]){SPECIALBTN_VIRTUALMOUSE,0,0,0},
        @"${right} - ${margin}", @"${margin}",
        BTN_RECT
    )];
#endif
    [dict[@"mControlDataList"] addObject:createButton(@"PRI",
        (int[]){SPECIALBTN_MOUSEPRI,0,0,0},
        @"${margin}", @"${bottom} - ${margin}",
        BTN_RECT
    )];
    [dict[@"mControlDataList"] addObject:createButton(@"SEC",
        (int[]){SPECIALBTN_MOUSESEC,0,0,0},
        @"${margin} * 2 + ${width}", @"${bottom} - ${margin}",
        BTN_RECT
    )];
    [self.ctrlView loadControlLayout:dict];

    // Implement a subset of custom controls functionalites enough for few buttons
    for (ControlButton *button in self.ctrlView.subviews) {
        [button addTarget:self action:@selector(executebtn_down:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(executebtn_up:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    }
}

- (void)executebtn:(ControlButton *)sender withAction:(int)action {
    int held = action == ACTION_DOWN;
    for (int i = 0; i < 4; i++) {
        int keycode = ((NSNumber *)sender.properties[@"keycodes"][i]).intValue;
        if (keycode < 0) {
            switch (keycode) {
                case SPECIALBTN_KEYBOARD:
                    if (held) return;
                    [self toggleSoftKeyboard];
                    break;

                case SPECIALBTN_MOUSEPRI:
                    AWTInputBridge_nativeSendData(EVENT_TYPE_MOUSE_BUTTON, BUTTON1_DOWN_MASK, held, 0, 0);
                    break;

                case SPECIALBTN_MOUSEMID:
                    AWTInputBridge_nativeSendData(EVENT_TYPE_MOUSE_BUTTON, BUTTON2_DOWN_MASK, held, 0, 0);
                    break;

                case SPECIALBTN_MOUSESEC:
                    AWTInputBridge_nativeSendData(EVENT_TYPE_MOUSE_BUTTON, BUTTON3_DOWN_MASK, held, 0, 0);
                    break;

                case SPECIALBTN_VIRTUALMOUSE:
                    if (held) return;
                    virtualMouseEnabled = !virtualMouseEnabled;
                    self.mousePointerView.hidden = !virtualMouseEnabled;
                    setPreference(@"virtmouse_enable", @(virtualMouseEnabled));
                    break;

                default:
                    NSLog(@"Warning: button %@ sent unknown special keycode: %d", sender.titleLabel.text, keycode);
                    break;
            }
        } else if (keycode > 0) {
            // unimplemented
        }
    }
}

- (void)executebtn_down:(ControlButton *)button {
    [self executebtn:button withAction:ACTION_DOWN];
}

- (void)executebtn_up:(ControlButton *)button {
    [self executebtn:button withAction:ACTION_UP];
}

- (void)surfaceOnClick:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        float resolution = ((NSNumber *)getPreference(@"resolution")).floatValue / 100.0;
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGPoint location = [sender locationInView:sender.view];
        CGFloat x = location.x * screenScale * resolution;
        CGFloat y = location.y * screenScale * resolution;
        AWTInputBridge_nativeSendData(EVENT_TYPE_CURSOR_POS, (int)x, (int)y, 0, 0);
        AWTInputBridge_nativeSendData(EVENT_TYPE_MOUSE_BUTTON, BUTTON1_DOWN_MASK, 1, 0, 0);
        AWTInputBridge_nativeSendData(EVENT_TYPE_MOUSE_BUTTON, BUTTON1_DOWN_MASK, 0, 0, 0);
    }
}

/*
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x == 0) {
        
    }
    if (scrollView.contentOffset.y == 0) {
        
    }
}
*/

- (void)toggleSoftKeyboard {
    if (self.inputTextField.isFirstResponder) {
        [self.inputTextField resignFirstResponder];
    } else {
        [self.inputTextField becomeFirstResponder];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return surfaceView;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.ctrlView.frame = UIEdgeInsetsInsetRect(self.view.frame, self.view.safeAreaInsets);
        [self.ctrlView.subviews makeObjectsPerformSelector:@selector(update)];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.virtualMouseFrame = self.mousePointerView.frame;
    }];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeBottom;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
