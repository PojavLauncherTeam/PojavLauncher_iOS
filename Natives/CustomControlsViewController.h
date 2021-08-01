#import <UIKit/UIKit.h>
#import "customcontrols/ControlButton.h"

@interface CustomControlsViewController : UIViewController

@end

@interface CCMenuViewController : UIViewController

@property(nonatomic, assign) BOOL shouldDisplayButtonEditor;
@property(nonatomic, weak) ControlButton* targetButton;

@end
