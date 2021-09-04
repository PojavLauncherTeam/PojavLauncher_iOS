#import "ControlSubButton.h"
#import "CustomControlsUtils.h"
#import "../LauncherPreferences.h"

#define INSERT_VALUE(KEY, VALUE) \
  string = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"${%@}", @(KEY)] withString:VALUE];

@implementation ControlSubButton
@synthesize properties;

/*
- (id)initWithProperties:(NSMutableDictionary *)propArray {
    if (self = [self initWithProperties:propArray willUpdate:NO]) {
        [self update];
    }
    return self;
}
*/

// filterProperties
- (void)preProcessProperties {
    if (self.parentDrawer) {
        self.properties[@"width"] = self.parentDrawer.properties[@"width"];
        self.properties[@"height"] = self.parentDrawer.properties[@"height"];
        self.properties[@"isDynamicBtn"] = @(NO);
    }
}

- (void)setParentDrawer:(ControlDrawer *)drawer {
    _parentDrawer = drawer;
    [self preProcessProperties];
}

@end
