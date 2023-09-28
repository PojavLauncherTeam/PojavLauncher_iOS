#import "NSPredicateUtilitiesExternal.h"

@implementation NSPredicateUtilitiesExternal

#if 0 // FIXME: doesn't work on certain iOS versions
+ (NSNumber *)dp:(NSNumber *)number {
    return @(number.doubleValue / UIScreen.mainScreen.scale);
}
+ (NSNumber *)px:(NSNumber *)number {
    return @(number.doubleValue * UIScreen.mainScreen.scale);
}
#endif

+ (NSNumber *)cbrt:(NSNumber *)number {
    return @(cbrt(number.doubleValue));
}

+ (NSNumber *)ceil:(NSNumber *)number {
    return @(ceil(number.doubleValue));
}

+ (NSNumber *)signum:(NSNumber *)number {
    if (number.doubleValue > 0) {
        return @(1);
    } else if (number.doubleValue < 0) {
        return @(-1);
    } else {
        return @(0);
    }
}

+ (NSNumber *)asin:(NSNumber *)number {
    return @(asin(number.doubleValue));
}
+ (NSNumber *)sin:(NSNumber *)number {
    return @(sin(number.doubleValue));
}
+ (NSNumber *)sinh:(NSNumber *)number {
    return @(sinh(number.doubleValue));
}

+ (NSNumber *)acos:(NSNumber *)number {
    return @(acos(number.doubleValue));
}
+ (NSNumber *)cos:(NSNumber *)number {
    return @(cos(number.doubleValue));
}
+ (NSNumber *)cosh:(NSNumber *)number {
    return @(cosh(number.doubleValue));
}

+ (NSNumber *)atan:(NSNumber *)number {
    return @(atan(number.doubleValue));
}
+ (NSNumber *)tan:(NSNumber *)number {
    return @(tan(number.doubleValue));
}
+ (NSNumber *)tanh:(NSNumber *)number {
    return @(tanh(number.doubleValue));
}

+ (NSNumber *)log2:(NSNumber *)number {
    return @(log2(number.doubleValue));
}
+ (NSNumber *)log10:(NSNumber *)number {
    return @(log10(number.doubleValue));
}

@end
