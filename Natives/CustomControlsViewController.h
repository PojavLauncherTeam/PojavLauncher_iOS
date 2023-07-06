#import <UIKit/UIKit.h>
#import "customcontrols/ControlButton.h"
#import "customcontrols/ControlLayout.h"

typedef NSString* (^GetDefaultCtrlBlock)();
typedef void (^SetDefaultCtrlBlock)(NSString *);

@interface ControlHandleView : UIView
@property(nonatomic, weak) ControlButton* target;
@end

@interface CustomControlsViewController : UIViewController

@property(nonatomic) GetDefaultCtrlBlock getDefaultCtrl;
@property(nonatomic) SetDefaultCtrlBlock setDefaultCtrl;

@property(nonatomic) UIGestureRecognizer* currentGesture;

@property(nonatomic) ControlLayout* ctrlView;
@property(nonatomic) ControlHandleView* resizeView;

@end

@interface CustomControlsViewController(UndoManager)
- (void)doAddButton:(ControlButton *)button atIndex:(NSNumber *)index;
- (void)doRemoveButton:(ControlButton *)button;
- (void)doMoveOrResizeButton:(ControlButton *)button from:(CGRect)from to:(CGRect)to;
- (void)doUpdateButton:(ControlButton *)button from:(NSMutableDictionary *)from to:(NSMutableDictionary *)to;
@end

@interface CCMenuViewController : UIViewController
@property(nonatomic) ControlButton* targetButton;
@end
