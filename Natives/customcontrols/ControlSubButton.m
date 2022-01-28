#import "ControlSubButton.h"
#import "CustomControlsUtils.h"
#import "../LauncherPreferences.h"

#define INSERT_VALUE(KEY, VALUE) \
  string = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"${%@}", @(KEY)] withString:VALUE];

@implementation ControlSubButton

// filterProperties
- (void)preProcessProperties {
    if (self.parentDrawer && ![self.parentDrawer.drawerData[@"orientation"] isEqualToString:@"FREE"]) {
        self.properties[@"width"] = self.parentDrawer.properties[@"width"];
        self.properties[@"height"] = self.parentDrawer.properties[@"height"];
        self.properties[@"isDynamicBtn"] = @(NO);
    }
}

- (void)setParentDrawer:(ControlDrawer *)drawer {
    _parentDrawer = drawer;
    [self preProcessProperties];
    //NSLog(@"DEBUG: SubButton properties %@", self.properties);
}

@end
