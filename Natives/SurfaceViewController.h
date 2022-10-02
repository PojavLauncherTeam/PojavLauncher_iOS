#import <UIKit/UIKit.h>

#import "GameSurfaceView.h"

CGRect virtualMouseFrame;
CGPoint lastVirtualMousePoint;

@interface SurfaceViewController : UIViewController

@property(nonatomic) GameSurfaceView* surfaceView;
@property UIImageView* mousePointerView;
@property(nonatomic) UIPanGestureRecognizer* scrollPanGesture;

- (void)sendTouchPoint:(CGPoint)location withEvent:(int)event;

@end
