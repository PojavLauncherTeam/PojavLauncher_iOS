#import <UIKit/UIKit.h>

#import "GameSurfaceView.h"

BOOL canAppendToLog;

CGRect virtualMouseFrame;
CGPoint lastVirtualMousePoint;

@interface SurfaceViewController : UIViewController

@property(nonatomic) GameSurfaceView* surfaceView;
@property UIImageView* mousePointerView;
@property(nonatomic) UIPanGestureRecognizer* scrollPanGesture;

@property(nonatomic) UIView* rootView;

- (void)sendTouchPoint:(CGPoint)location withEvent:(int)event;

+ (BOOL)isRunning;

// LogView category
@property(nonatomic) UITableView* logTableView;
@property(nonatomic) UIView* logOutputView;

// Navigation category
@property(nonatomic) NSArray *menuArray;
@property(nonatomic) UITableView *menuView;

@end

@interface SurfaceViewController(LogView)

+ (void)appendToLog:(NSString *)line;
+ (void)handleExitCode:(int)code;

@end
