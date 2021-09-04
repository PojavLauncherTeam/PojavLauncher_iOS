#import <UIKit/UIKit.h>
#import "ControlButton.h"

UIColor* convertARGB2UIColor(int argb);
int convertUIColor2ARGB(UIColor* color);
BOOL convertLayoutIfNecessary(NSMutableDictionary* dict);
void generateAndSaveDefaultControl();
void loadControlObject(UIView* targetView, NSMutableDictionary* controlDictionary, void(^walkToButton)(ControlButton* button));
