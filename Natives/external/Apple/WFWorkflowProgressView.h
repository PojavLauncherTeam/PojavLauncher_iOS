// Source: /System/Library/PrivateFrameworks/WorkflowUIServices.framework/WorkflowUIServices
// Circular progress view used in Shortcuts app

#import <UIKit/UIKit.h>

@interface WFWorkflowProgressView : UIControl

@property(nonatomic, retain) UIColor* resolvedTintColor;
@property(assign, nonatomic) CGFloat fractionCompleted, stopSize;

- (void)reset;
- (void)transitionCompletedLayerToVisible:(BOOL)visible animated:(BOOL)animated haptic:(BOOL)haptic;
- (void)transitionRunningLayerToVisible:(BOOL)visible animated:(BOOL)animated;

@end
