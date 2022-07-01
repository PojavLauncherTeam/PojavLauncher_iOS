#import <UIKit/UIKit.h>

#import "GameSurfaceView.h"

CGRect virtualMouseFrame;
CGPoint lastVirtualMousePoint;


@interface SurfaceViewController : UIViewController

@property(nonatomic, strong) GameSurfaceView* surfaceView;
@property UIImageView* mousePointerView;
@property UIPanGestureRecognizer* scrollPanGesture;

@end
