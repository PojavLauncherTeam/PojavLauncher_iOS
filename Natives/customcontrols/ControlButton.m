#import "ControlButton.h"
#import "CustomControlsUtils.h"
#import "../LauncherPreferences.h"

#define INSERT_VALUE(KEY, VALUE) \
  string = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"${%@}", @(KEY)] withString:VALUE];

@implementation ControlButton
@synthesize properties;

/**
 * TODO implement:
 * - isDynamicBtn (???)
 * - scaledAt
 * - (maybe more)
 */

+ (id)initWithProperties:(NSMutableDictionary *)propArray {
    ControlButton *instance = [ControlButton buttonWithType:UIButtonTypeRoundedRect];
    [instance setTitle:propArray[@"name"] forState:UIControlStateNormal];
    instance.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    instance.tintColor = [UIColor whiteColor];
    instance.properties = propArray;
    [instance update];
    
    return instance;
}

+ (id)initWithName:(NSString *)name keycode:(int)keycode rect:(CGRect)rect transparency:(float)transparency {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;

    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[@"name"] = name;
    properties[@"dynamicX"] = @((screenBounds.size.width - insets.left - insets.right) / rect.origin.x);
    properties[@"dynamicY"] = @(screenBounds.size.height / rect.origin.y);
    properties[@"width"] = @(rect.size.width);
    properties[@"height"] = @(rect.size.height);
    properties[@"keycode"] = @(keycode);
    properties[@"opacity"] = @((100.0 - transparency) / 100.0);
    properties[@"cornerRadius"] = @(0);

    return [ControlButton initWithProperties:properties];
}

- (NSString *)processFunctions:(NSString *)string {
    NSString *tmpStr;
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    // Since NSExpression doesn't support calling as "custom_function(parameter)", we do direct replaces here

    // float dp(float px) => px / screenScale
    // Without a state machine to do "px / screenScale", just do "1 / screenScale * px" :)
    tmpStr = [string stringByReplacingOccurrencesOfString:@"dp(" withString:[NSString stringWithFormat:@"(1.0 / %f * ", screenScale]];

    // float px(float dp) => screenScale * dp
    tmpStr = [tmpStr stringByReplacingOccurrencesOfString:@"px(" withString:[NSString stringWithFormat:@"(%f * ", screenScale]];
    return tmpStr;
}

- (CGFloat)calculateDynamicPos:(NSString *)string {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;

    // width: offset the notch parts
    CGFloat screenWidth = (screenBounds.size.width - insets.left - insets.right) * screenScale;
    CGFloat screenHeight = screenBounds.size.height * screenScale;
    
    CGFloat width = [self.properties[@"width"] floatValue];
    CGFloat height = [self.properties[@"height"] floatValue];

    // Insert value to ${variable}
    INSERT_VALUE("top", @"0");
    INSERT_VALUE("left", @"0");
    INSERT_VALUE("right", ([NSString stringWithFormat:@"%f", screenWidth - width * screenScale]));
    INSERT_VALUE("bottom", ([NSString stringWithFormat:@"%f", screenHeight - height * screenScale]));
    INSERT_VALUE("width", ([NSString stringWithFormat:@"%f", width * screenScale]));
    INSERT_VALUE("height", ([NSString stringWithFormat:@"%f", height * screenScale]));
    INSERT_VALUE("screen_width", ([NSString stringWithFormat:@"%f", screenWidth]));
    INSERT_VALUE("screen_height", ([NSString stringWithFormat:@"%f", screenHeight]));
    INSERT_VALUE("margin", ([NSString stringWithFormat:@"%f", 2.0 * screenScale]));
    INSERT_VALUE("preferred_scale", ([NSString stringWithFormat:@"%f", [getPreference(@"button_scale") floatValue]]));

    string = [self processFunctions:string];
    // NSLog(@"After insert: %@", string);

    // Calculate, since the dynamic position contains some math equations
    NSExpression *expression = [NSExpression expressionWithFormat:string];
    return [[expression expressionValueWithObject:nil context:nil] floatValue] / screenScale;
}

- (void)setDefaultValueForKey:(NSString *)key value:(id)value {
    if (self.properties[key] == nil || self.properties[key] == [NSNull null]) {
        self.properties[key] = value;
    }
}

- (void)update {
    // net/kdt/pojavlaunch/customcontrols/ControlData.update()

    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;

    NSString *propDynamicX = (NSString *) self.properties[@"dynamicX"];
    NSString *propDynamicY = (NSString *) self.properties[@"dynamicY"];

    CGFloat propW = [self.properties[@"width"] floatValue];
    CGFloat propH = [self.properties[@"height"] floatValue];
    float propCornerRadius = [self.properties[@"cornerRadius"] floatValue];
    float propStrokeWidth = [self.properties[@"strokeWidth"] floatValue];
    int propBackgroundColor = [self.properties[@"bgColor"] intValue];
    int propStrokeColor = ((NSNumber *)self.properties[@"strokeColor"]).intValue;

    // Calculate dynamic position
    CGFloat propX = [self calculateDynamicPos:propDynamicX];
    CGFloat propY = [self calculateDynamicPos:propDynamicY];

    // Update other properties
    self.frame = CGRectMake(propX + insets.left, propY, propW, propH);
    self.alpha = [[properties valueForKey:@"opacity"] floatValue];
    self.backgroundColor = convertARGB2UIColor(propBackgroundColor);

    self.layer.borderColor = [convertARGB2UIColor(propStrokeColor) CGColor];
    if (propCornerRadius > 0) {
        self.layer.cornerRadius = MIN(self.frame.size.width, self.frame.size.height) / 200.0 * propCornerRadius;
    }
    if (propStrokeWidth > 0) {
        self.layer.borderWidth = MAX(self.frame.size.width, self.frame.size.height) / 200.0 * propStrokeWidth;
    }
    self.clipsToBounds = YES;
}

@end
