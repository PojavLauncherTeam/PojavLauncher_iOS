#import "GameSurfaceView.h"
#import "LauncherPreferences.h"
#import "PLProfiles.h"
#import "utils.h"

@implementation GameSurfaceView

- (void)displayLayer {
    CGDataProviderRef bitmapProvider = CGDataProviderCreateWithData(NULL, gbuffer, windowWidth * windowHeight * 4, NULL);
    CGImageRef bitmap = CGImageCreate(windowWidth, windowHeight, 8, 32, 4 * windowWidth, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault, bitmapProvider, NULL, FALSE, kCGRenderingIntentDefault);
    self.layer.contents = (__bridge id) bitmap;
    CGImageRelease(bitmap);
    CGDataProviderRelease(bitmapProvider);
    //CGColorSpaceRelease(colorSpace);
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.layer.drawsAsynchronously = YES;
    self.layer.opaque = YES;

    if ([[PLProfiles resolveKeyForCurrentProfile:@"renderer"] hasPrefix:@"libOSMesa"]) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }

    return self;
}

+ (Class)layerClass {
    if ([[PLProfiles resolveKeyForCurrentProfile:@"renderer"] hasPrefix:@"libOSMesa"]) {
        return CALayer.class;
    } else {
        return CAMetalLayer.class;
    }
}

@end
