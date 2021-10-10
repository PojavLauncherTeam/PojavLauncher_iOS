#import "ControlButton.h"
#import "CustomControlsUtils.h"
#import "../LauncherPreferences.h"
#import "../utils.h"

#define INSERT_VALUE(KEY, VALUE) \
  string = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"${%@}", @(KEY)] withString:VALUE];

@implementation ControlButton

/**
 * TODO implement:
 * - isDynamicBtn (???)
 * - scaledAt
 * - (maybe more)
 */

+ (id)buttonWithProperties:(NSMutableDictionary *)propArray willUpdate:(BOOL)update {
    //NSLog(@"DBG button prop = %@", propArray);
    ControlButton *instance = [self buttonWithType:UIButtonTypeRoundedRect];
    instance.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    instance.tintColor = [UIColor whiteColor];
    instance.properties = propArray;
    if (update) {
        [instance update];
    }

    return instance;
}

+ (id)buttonWithProperties:(NSMutableDictionary *)propArray {
    return [self buttonWithProperties:propArray willUpdate:YES];
}

/*
- (id)initWithName:(NSString *)name keycode:(int)keycode rect:(CGRect)rect transparency:(float)transparency {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;

    NSMutableDictionary *localProp = [[NSMutableDictionary alloc] init];
    localProp[@"name"] = name;
    localProp[@"dynamicX"] = @((screenBounds.size.width - insets.left - insets.right) / rect.origin.x);
    localProp[@"dynamicY"] = @(screenBounds.size.height / rect.origin.y);
    localProp[@"width"] = @(rect.size.width);
    localProp[@"height"] = @(rect.size.height);
    localProp[@"keycode"] = @(keycode);
    localProp[@"opacity"] = @((100.0 - transparency) / 100.0);
    localProp[@"cornerRadius"] = @(0);

    return [self initWithProperties:localProp];
}
*/

- (void)preProcessProperties {
    CGFloat currentScale = [current_control_object[@"scaledAt"] floatValue];
    CGFloat savedScale = [getPreference(@"button_scale") floatValue];
    if (currentScale != savedScale) {
        self.properties[@"width"] = @([self.properties[@"width"] floatValue] * savedScale / currentScale);
        self.properties[@"height"] = @([self.properties[@"height"] floatValue] * savedScale / currentScale);
    }
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
    CGFloat screenWidth = dpToPx(screenBounds.size.width - insets.left - insets.right);
    CGFloat screenHeight = dpToPx(screenBounds.size.height);
    
    CGFloat width = [self.properties[@"width"] floatValue];
    CGFloat height = [self.properties[@"height"] floatValue];

    // Insert value to ${variable}
    INSERT_VALUE("top", @"0");
    INSERT_VALUE("left", @"0");
    INSERT_VALUE("right", ([NSString stringWithFormat:@"%f", screenWidth - dpToPx(width)]));
    INSERT_VALUE("bottom", ([NSString stringWithFormat:@"%f", screenHeight - dpToPx(height)]));
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

// NOTE: Unlike Android's impl, this method uses dp instead of px (no call to dpToPx)
- (NSString *)generateDynamicX:(CGFloat)x {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;
    // width: offset the notch parts
    CGFloat physicalWidth = screenBounds.size.width - insets.left - insets.right;

    if (x + ([self.properties[@"width"] floatValue] / 2.0) > physicalWidth / 2.0) {
        return [NSString stringWithFormat:@"%f  * ${screen_width} - ${width}", (x + [self.properties[@"width"] floatValue]) / physicalWidth];
    } else{
        return [NSString stringWithFormat:@"%f  * ${screen_width}", x / physicalWidth];
    }
}

// NOTE: Unlike Android's impl, this method uses dp instead of px (no call to dpToPx)
- (NSString *)generateDynamicY:(CGFloat)y {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;

    CGFloat physicalHeight = screenBounds.size.height;

    if (y + ([self.properties[@"height"] floatValue] / 2.0) > physicalHeight / 2.0) {
        return [NSString stringWithFormat:@"%f  * ${screen_height} - ${height}", (y + [self.properties[@"height"] floatValue]) / physicalHeight];
    } else {
        return [NSString stringWithFormat:@"%f  * ${screen_height}", y / physicalHeight];
    }
}

- (void)update {
    // net/kdt/pojavlaunch/customcontrols/ControlData.update()
    [self preProcessProperties];

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
    self.alpha = [self.properties[@"opacity"] floatValue];
    self.backgroundColor = convertARGB2UIColor(propBackgroundColor);

    self.layer.borderColor = [convertARGB2UIColor(propStrokeColor) CGColor];
    self.layer.cornerRadius = MIN(self.frame.size.width, self.frame.size.height) / 200.0 * propCornerRadius;
    self.layer.borderWidth = MAX(self.frame.size.width, self.frame.size.height) / 200.0 * propStrokeWidth;
    self.clipsToBounds = YES;

    [self setTitle:self.properties[@"name"] forState:UIControlStateNormal];
}

// NOTE: Unlike Android's impl, this method uses dp instead of px (no call to dpToPx), "view.center" instead of "view.pos + view.size/2"
- (BOOL)canSnap:(ControlButton *)button {
    return button != self &&
      MathUtils_dist(button.center.x, button.center.y, self.center.x, self.center.y)
        <= MAX(button.frame.size.width/2.0 + self.frame.size.width/2.0,
               button.frame.size.height/2.0 + self.frame.size.height/2.0) + 8.0;
  }

@end
