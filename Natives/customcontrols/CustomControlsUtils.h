#import <UIKit/UIKit.h>
#import "ControlButton.h"

#define BTN_RECT 80.0, 30.0
#define BTN_SQUARE 50.0, 50.0

NSMutableDictionary* createButton(NSString* name, int* keycodes, NSString* dynamicX, NSString* dynamicY, CGFloat width, CGFloat height);

UIColor* convertARGB2UIColor(int argb);
int convertUIColor2ARGB(UIColor* color);
int convertUIColor2RGB(UIColor* color);
BOOL convertLayoutIfNecessary(NSMutableDictionary* dict);
void generateAndSaveDefaultControl();
void loadControlObject(UIView* targetView, NSMutableDictionary* controlDictionary);

void initKeycodeTable(NSMutableArray* keyCodeMap, NSMutableArray* keyValueMap);
