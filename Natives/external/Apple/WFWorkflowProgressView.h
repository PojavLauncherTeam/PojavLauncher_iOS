// Source: /System/Library/PrivateFrameworks/WorkflowUIServices.framework/WorkflowUIServices
// Circular progress view used in Shortcuts app

#import <UIKit/UIKit.h>

@interface WFWorkflowProgressView : UIControl

@property(nonatomic, retain) UIColor* resolvedTintColor;
@property(assign, nonatomic) CGFloat fractionCompleted;

- (void)transistionToState:(NSInteger)state;

@end
