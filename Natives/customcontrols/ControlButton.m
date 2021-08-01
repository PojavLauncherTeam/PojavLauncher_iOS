#import "ControlButton.h"
#import "CustomControlsUtils.h"
#import "../LauncherPreferences.h"

#define INSERT_VALUE(KEY, VALUE) \
  string = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"${%@}", @(KEY)] withString:VALUE];
  
#define NUM2F(x) (x == nil ? 0 : [(NSNumber *)x floatValue])

@implementation ControlButton
@synthesize properties;

/**
 * To compatible with Android, NSArray (ControlData)
 * will store the scaled values.
 *
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
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[@"name"] = name;
    properties[@"x"] = @(rect.origin.x);
    properties[@"y"] = @(rect.origin.y);
    properties[@"width"] = @(rect.size.width);
    properties[@"height"] = @(rect.size.height);
    properties[@"keycode"] = @(keycode);
    properties[@"opacity"] = @(100 - transparency);
    properties[@"cornerRadius"] = @(0);
    
    return [ControlButton initWithProperties:properties];
}

- (float)insertDynamicPos:(NSString*)string {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIEdgeInsets insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;

    // width: offset the notch parts
    int screenWidth = (int) roundf(screenBounds.size.width - insets.left - insets.right);
    int screenHeight = (int) roundf(screenBounds.size.height);
    
    float width = NUM2F(self.properties[@"width"]);
    float height = NUM2F(self.properties[@"height"]);

    // Insert value to ${variable}
    INSERT_VALUE("top", @"0");
    INSERT_VALUE("left", @"0");
    INSERT_VALUE("right", ([NSString stringWithFormat:@"%f", screenWidth - width]));
    INSERT_VALUE("bottom", ([NSString stringWithFormat:@"%f", screenHeight - height]));
    INSERT_VALUE("width", ([NSString stringWithFormat:@"%f", width]));
    INSERT_VALUE("height", ([NSString stringWithFormat:@"%f", height]));
    INSERT_VALUE("screen_width", ([NSString stringWithFormat:@"%d", screenWidth]));
    INSERT_VALUE("screen_height", ([NSString stringWithFormat:@"%d", screenHeight]));
    INSERT_VALUE("margin", ([NSString stringWithFormat:@"%f", 2.0])); // FIXME is this correct?

    // NSLog(@"Final math: %@", string);

    // Calculate, since the dynamic position contains some math equations
    NSExpression *expression = [NSExpression expressionWithFormat:string];
    return [[expression expressionValueWithObject:nil context:nil] floatValue];
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

    float propX = NUM2F(self.properties[@"x"]);
    float propY = NUM2F(self.properties[@"y"]);
    float propW = NUM2F(self.properties[@"width"]);
    float propH = NUM2F(self.properties[@"height"]);
    float propCornerRadius = NUM2F(self.properties[@"cornerRadius"]);
    float propStrokeWidth = NUM2F(self.properties[@"strokeWidth"]);
    int propBackgroundColor = ((NSNumber *)self.properties[@"bgColor"]).intValue;
    int propStrokeColor = ((NSNumber *)self.properties[@"strokeColor"]).intValue;

    // isRound is deprecated, only keep for old Android's controls backwards compatibility
    [self setDefaultValueForKey:@"isRound" value:@(NO)];
    BOOL propIsRound = self.properties[@"isRound"];
    [self setDefaultValueForKey:@"cornerRadius" value:@(propIsRound ? 8.0 : 0)];

    // If dynamic position is null, set value to fixed position
    if (propDynamicX == nil) {
        propDynamicX = [NSString stringWithFormat:@"%f", propX];
        self.properties[@"dynamicX"] = propDynamicX;
    } if (propDynamicY == nil) {
        propDynamicY = [NSString stringWithFormat:@"%f", propY];
        self.properties[@"dynamicY"] = propDynamicY;
    }

    // Calculate dynamic position
    propX = [self insertDynamicPos:propDynamicX];
    propY = [self insertDynamicPos:propDynamicY];
    // Set back to fixed position
    [self.properties setObject:@(propX) forKey:@"x"];
    [self.properties setObject:@(propY) forKey:@"y"];

    // Update other properties
    self.frame = CGRectMake(propX + insets.left, propY, propW, propH);
    self.alpha = NUM2F([properties valueForKey:@"opacity"]) / 100.0f;
    // self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
    self.backgroundColor = convertARGB2UIColor(propBackgroundColor);

    self.layer.borderColor = [convertARGB2UIColor(propStrokeColor) CGColor];
    if (propCornerRadius > 0) {
        self.layer.cornerRadius = self.frame.size.width / 200 * propCornerRadius;
    }
    if (propStrokeWidth > 0) {
        self.layer.borderWidth = self.frame.size.width / propStrokeWidth;
    }
    self.clipsToBounds = YES;
}

@end
