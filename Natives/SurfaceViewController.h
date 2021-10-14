#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>
#import "MGLKit.h"

CGRect virtualMouseFrame;
CGPoint lastVirtualMousePoint;

@interface GameSurfaceView : UIView
{
    CALayer* layer;
    CGColorSpaceRef colorSpace;
    CGDataProviderDirectCallbacks callbacks;
}

- (void)displayLayer;
@end

@interface SurfaceViewController : UIViewController

@property(nonatomic, strong) GameSurfaceView* surfaceView;
@property UIImageView* mousePointerView;

@end
