#import <UIKit/UIKit.h>
#import "UIKit+hook.h"

#import "customcontrols/ControlLayout.h"
#import "GameSurfaceView.h"
#import "PLLogOutputView.h"

BOOL canAppendToLog;
dispatch_group_t fatalExitGroup;

CGRect virtualMouseFrame;
CGPoint lastVirtualMousePoint;

@interface SurfaceViewController : UIViewController

@property(nonatomic) ControlLayout *ctrlView;
@property(nonatomic) GameSurfaceView* surfaceView;
@property(nonatomic) UIView *touchView;
@property UIImageView* mousePointerView;
@property(nonatomic) UIPanGestureRecognizer* scrollPanGesture;

@property(nonatomic) UIView* rootView;

- (instancetype)initWithMetadata:(NSDictionary *)metadata;
- (void)sendTouchPoint:(CGPoint)location withEvent:(int)event;
- (void)updateSavedResolution;
- (void)updateGrabState;

+ (GameSurfaceView *)surface;
+ (BOOL)isRunning;

// LogView category
@property(nonatomic) PLLogOutputView* logOutputView;

// Navigation category
@property(nonatomic) NSArray *menuArray;
@property(nonatomic) UITableView *menuView;
@property(nonatomic) UIScreenEdgePanGestureRecognizer* edgeGesture;

@end

@interface SurfaceViewController(ExternalDisplay)

- (void)switchToExternalDisplay;
- (void)switchToInternalDisplay;

@end

@interface SurfaceViewController(LogView)

- (void)viewWillTransitionToSize_LogView:(CGRect)frame;

@end

@interface SurfaceViewController(Navigation)<UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate>

- (void)actionOpenNavigationMenu;
- (void)didSelectMenuItem:(int)item;
- (void)viewWillTransitionToSize_Navigation:(CGRect)frame;

@end
