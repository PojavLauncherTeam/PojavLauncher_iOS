#import <MetalKit/MetalKit.h>
#import <UIKit/UIKit.h>

@interface GameSurfaceView : UIView
{
    CALayer* layer;
    CGColorSpaceRef colorSpace;
    CGDataProviderDirectCallbacks callbacks;
}

- (void)displayLayer;
@end
