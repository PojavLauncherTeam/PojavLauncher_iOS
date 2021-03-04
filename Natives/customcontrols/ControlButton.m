#import "ControlButton.h"

#define NUM2F(x) [(NSNumber *)x floatValue]

@implementation ControlButton
@synthesize properties;

/**
 * To compatible with Android, NSArray (ControlData)
 * will store the scaled values.
 */

+ (id)initWithProperties:(NSMutableDictionary *)propArray {
    float screenScale = (float) [[UIScreen mainScreen] scale];

    float propX = NUM2F([propArray valueForKey:@"x"]) / screenScale;
    float propY = NUM2F([propArray valueForKey:@"y"]) / screenScale;
    float propW = NUM2F([propArray valueForKey:@"width"]) / screenScale;
    float propH = NUM2F([propArray valueForKey:@"height"]) / screenScale;
    ControlButton *instance = [ControlButton buttonWithType:UIButtonTypeRoundedRect];
    [instance setTitle:[propArray valueForKey:@"name"]
      forState:UIControlStateNormal];
    instance.frame = CGRectMake(propX, propY, propW, propH);
    instance.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    instance.alpha = 1.0f - NUM2F([propArray valueForKey:@"transparency"]) / 100.0f;
    instance.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
    instance.tintColor = [UIColor whiteColor];
    
    instance.properties = propArray;
    return instance;
}

+ (id)initWithName:(NSString *)name keycode:(int)keycode rect:(CGRect)rect transparency:(float)transparency {
    float screenScale = (float) [[UIScreen mainScreen] scale];

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

@end
