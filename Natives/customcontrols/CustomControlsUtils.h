#import <UIKit/UIKit.h>
#import "ControlButton.h"

NSMutableDictionary* current_control_object;

UIColor* convertARGB2UIColor(int argb);
int convertUIColor2ARGB(UIColor* color);
int convertUIColor2RGB(UIColor* color);
BOOL convertLayoutIfNecessary(NSMutableDictionary* dict);
void generateAndSaveDefaultControl();
void loadControlObject(UIView* targetView, NSMutableDictionary* controlDictionary, void(^walkToButton)(ControlButton* button));
