#import "GameSurfaceView.h"
#import "LauncherPreferences.h"
#import "utils.h"

@implementation GameSurfaceView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    return self;
}

+ (Class)layerClass {
    return CAMetalLayer.class;
}

@end
