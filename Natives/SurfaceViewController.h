#import <UIKit/UIKit.h>

#import "GameSurfaceView.h"

BOOL canAppendToLog;
dispatch_group_t fatalExitGroup;

CGRect virtualMouseFrame;
CGPoint lastVirtualMousePoint;

@interface SurfaceViewController : UIViewController

@property(nonatomic) UIView *ctrlView;
@property(nonatomic) GameSurfaceView* surfaceView;
@property(nonatomic) UIView *touchView;
@property UIImageView* mousePointerView;
@property(nonatomic) UIPanGestureRecognizer* scrollPanGesture;

@property(nonatomic) UIView* rootView;

- (void)sendTouchPoint:(CGPoint)location withEvent:(int)event;
- (void)updateSavedResolution;

+ (BOOL)isRunning;

// LogView category
@property(nonatomic) UITableView* logTableView;
@property(nonatomic) UIView* logOutputView;

// Navigation category
@property(nonatomic) NSArray *menuArray;
@property(nonatomic) UITableView *menuView;

@end

@interface SurfaceViewController(ExternalDisplay)

- (void)switchToExternalDisplay;
- (void)switchToInternalDisplay;

@end

@interface SurfaceViewController(LogView)

+ (void)appendToLog:(NSString *)line;
+ (void)handleExitCode:(int)code;

- (void)viewWillTransitionToSize_LogView:(CGRect)frame;

@end

@interface SurfaceViewController(Navigation)<UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate>

- (void)viewWillTransitionToSize_Navigation:(CGRect)frame;

@end
