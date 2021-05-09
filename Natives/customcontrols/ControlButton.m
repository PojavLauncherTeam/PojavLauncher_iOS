#import "ControlButton.h"

#define INSERT_VALUE(KEY, VALUE) \
  string = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"${%@}", @(KEY)] withString:VALUE];
  
#define NUM2F(x) [(NSNumber *)x floatValue]

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
    [instance setTitle:[propArray valueForKey:@"name"]
      forState:UIControlStateNormal];
    instance.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    instance.tintColor = [UIColor whiteColor];
    
    instance.properties = propArray;
    [instance update];
    
    return instance;
}

+ (id)initWithName:(NSString *)name keycode:(int)keycode rect:(CGRect)rect transparency:(float)transparency {
    float screenScale = (float) 2.0; //[[UIScreen mainScreen] scale];

    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    [properties setObject:name forKey:@"name"];
    [properties setObject:@(rect.origin.x * screenScale) forKey:@"x"];
    [properties setObject:@(rect.origin.y * screenScale) forKey:@"y"];
    [properties setObject:@(rect.size.width * screenScale) forKey:@"width"];
    [properties setObject:@(rect.size.height * screenScale) forKey:@"height"];
    [properties setObject:@(keycode) forKey:@"keycode"];
    [properties setObject:@(transparency) forKey:@"transparency"];
    
    return [ControlButton initWithProperties:properties];
}

- (float)insertDynamicPos:(NSString*)string {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = 2.0; // [[UIScreen mainScreen] scale];
    UIEdgeInsets insets = [[[UIApplication sharedApplication] keyWindow] safeAreaInsets];

    // width: offset the notch parts
    int screenWidth = (int) roundf((screenBounds.size.width - insets.left - insets.right) * screenScale);
    int screenHeight = (int) roundf(screenBounds.size.height * screenScale);
    
    float width = NUM2F([self.properties valueForKey:@"width"]);
    float height = NUM2F([self.properties valueForKey:@"height"]);

    // Insert value to ${variable}
    INSERT_VALUE("top", @"0");
    INSERT_VALUE("left", @"0");
    INSERT_VALUE("right", ([NSString stringWithFormat:@"%f", screenWidth - width]));
    INSERT_VALUE("bottom", ([NSString stringWithFormat:@"%f", screenHeight - height]));
    INSERT_VALUE("width", ([NSString stringWithFormat:@"%f", width]));
    INSERT_VALUE("height", ([NSString stringWithFormat:@"%f", height]));
    INSERT_VALUE("screen_width", ([NSString stringWithFormat:@"%d", screenWidth]));
    INSERT_VALUE("screen_height", ([NSString stringWithFormat:@"%d", screenHeight]));
    INSERT_VALUE("margin", ([NSString stringWithFormat:@"%f", 2.0 * screenScale])); // FIXME is this correct?

    NSLog(@"Final math: %@", string);

    // Calculate, because the dynamic position contains some math equations
    NSExpression *expression = [NSExpression expressionWithFormat:string];
    return [[expression expressionValueWithObject:nil context:nil] floatValue];
}

- (void)update {
    // net/kdt/pojavlaunch/customcontrols/ControlData.update()

    float screenScale = (float) 2.0; // [[UIScreen mainScreen] scale];
    UIEdgeInsets insets = [[[UIApplication sharedApplication] keyWindow] safeAreaInsets];

    NSString *propDynamicX = (NSString *) [self.properties valueForKey:@"dynamicX"];
    NSString *propDynamicY = (NSString *) [self.properties valueForKey:@"dynamicY"];
    float propX = NUM2F([self.properties valueForKey:@"x"]);
    float propY = NUM2F([self.properties valueForKey:@"y"]);
    float propW = NUM2F([self.properties valueForKey:@"width"]);
    float propH = NUM2F([self.properties valueForKey:@"height"]);

    // If dynamic position is null, set value to fixed position
    if (propDynamicX == nil) {
        propDynamicX = [NSString stringWithFormat:@"%f", propX];
        [self.properties setObject:propDynamicX forKey:@"dynamicX"];
    } if (propDynamicY == nil) {
        propDynamicY = [NSString stringWithFormat:@"%f", propY];
        [self.properties setObject:propDynamicY forKey:@"dynamicY"];
    }

    // Calculate dynamic position
    propX = [self insertDynamicPos:propDynamicX];
    propY = [self insertDynamicPos:propDynamicY];
    // Set back to fixed position
/*
    [self.properties setObject:@(propX) forKey:@"x"];
    [self.properties setObject:@(propY) forKey:@"y"];
*/

    // Update other properties
    self.frame = CGRectMake(propX / screenScale + insets.left, propY / screenScale, propW / screenScale, propH / screenScale);
    self.alpha = 1.0f - NUM2F([properties valueForKey:@"transparency"]) / 100.0f;
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
}

@end
