#import "GameSurfaceView.h"
#import "LauncherPreferences.h"
#import "utils.h"

@implementation GameSurfaceView
const void * _CGDataProviderGetBytePointerCallbackOSMESA(void *info) {
    return gbuffer;
}

- (void)displayLayer {
    CGDataProviderRef bitmapProvider = CGDataProviderCreateDirect(NULL, windowWidth * windowHeight * 4, &callbacks);
    CGImageRef bitmap = CGImageCreate(windowWidth, windowHeight, 8, 32, 4 * windowWidth, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder16Little, bitmapProvider, NULL, FALSE, kCGRenderingIntentDefault);     

    self.layer.contents = (__bridge id) bitmap;
    CGImageRelease(bitmap);
    CGDataProviderRelease(bitmapProvider);
   //  CGColorSpaceRelease(colorSpace);
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.layer.drawsAsynchronously = YES;
    self.layer.opaque = YES;

    if ([getPreference(@"renderer") hasPrefix:@"libOSMesaOverride"]) {

        colorSpace = CGColorSpaceCreateDeviceRGB();

        callbacks.version = 0;
        callbacks.getBytePointer = _CGDataProviderGetBytePointerCallbackOSMESA;
        callbacks.releaseBytePointer = _CGDataProviderReleaseBytePointerCallback;
        callbacks.getBytesAtPosition = NULL;
        callbacks.releaseInfo = NULL;
    }

    return self;
}

+ (Class)layerClass {
    if ([getPreference(@"renderer") hasPrefix:@"libOSMesa"]) {
        return CALayer.class;
    } else {
        return CAMetalLayer.class;
    }
}

@end
