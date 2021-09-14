#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>
#import "MGLKit.h"

@interface GameSurfaceView : UIView
{
CALayer* layer;
CGColorSpaceRef colorSpace;
CGDataProviderDirectCallbacks callbacks;
}
@end

@interface SurfaceViewController : UIViewController

@property(nonatomic, strong) UIView* surfaceView;

@end
