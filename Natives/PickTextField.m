#import "PickTextField.h"

@interface PickTextField()
@end

@implementation PickTextField

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return NO;
}

- (CGRect)caretRectForPosition:(UITextPosition*) position {
    return CGRectNull;
}

- (NSArray *)selectionRectsForRange:(UITextRange *)range {
    return nil;
}

@end
