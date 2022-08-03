#import <UIKit/UIKit.h>
#import "customcontrols/ControlButton.h"

@interface CustomControlsViewController : UIViewController

@property(nonatomic) UIGestureRecognizer* currentGesture;

- (void)initKeyCodeMap;

@end

@interface CCMenuViewController : UIViewController

@property(nonatomic) ControlButton* targetButton;

@end
