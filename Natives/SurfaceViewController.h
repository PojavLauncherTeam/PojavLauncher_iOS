#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>

@interface SurfaceView : UIView
{
    CALayer* layer;
    CGColorSpaceRef colorSpace;
    CGDataProviderDirectCallbacks callbacks;
}
@end

// MGLKView *glView;

SurfaceView *globalSurfaceView;
// MTKView *globalSurfaceView;

@interface SurfaceViewController : UIViewController
// MGLKViewController
// UIViewController

@end
