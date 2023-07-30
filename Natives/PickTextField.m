#import "PickTextField.h"
#import "utils.h"

@interface PickViewController : UIViewController
@property(nonatomic, assign) UITextField *textField;
@end

@implementation PickViewController
- (void)loadView {
    [super loadView];
    [self.view addSubview:self.textField.inputAccessoryView];
    [self.view addSubview:self.textField.inputView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGRect frame = CGRectMake(
        self.view.safeAreaInsets.left,
        self.view.safeAreaInsets.top,
        MIN(self.view.frame.size.width - self.view.safeAreaInsets.right, self.preferredContentSize.width),
        MIN(self.view.frame.size.height - self.view.safeAreaInsets.bottom, self.preferredContentSize.height));
    self.textField.inputAccessoryView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, self.textField.inputAccessoryView.frame.size.height);
    self.textField.inputView.frame = CGRectMake(frame.origin.x, CGRectGetMaxY(self.textField.inputAccessoryView.frame), frame.size.width, frame.size.height - CGRectGetMaxY(self.inputAccessoryView.frame));
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.textField.delegate textFieldDidEndEditing:self.textField];
}

@end

@interface PickTextField()
@property(nonatomic) PickViewController *vc;
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

- (BOOL)becomeFirstResponder {
    if (!NSProcessInfo.processInfo.isMacCatalystApp) {
        return [super becomeFirstResponder];
    }

    self.vc = [[PickViewController alloc] init];
    self.vc.modalPresentationStyle = UIModalPresentationPopover;
    self.vc.preferredContentSize = CGSizeMake(500, 250);
    self.vc.textField = self;

    UIPopoverPresentationController *popoverController = [self.vc popoverPresentationController];
    popoverController.sourceView = self;
    popoverController.sourceRect = self.frame;

    UIViewController *showingVC = (id)self.nextResponder;
    while (![showingVC isKindOfClass:UIViewController.class]) {
        showingVC = (id)showingVC.nextResponder;
    }
    [showingVC presentViewController:self.vc animated:YES completion:nil];

    return YES;
}

- (BOOL)endEditing:(BOOL)force {
    if (!NSProcessInfo.processInfo.isMacCatalystApp) {
        return [super endEditing:force];
    }

    [self.vc dismissViewControllerAnimated:YES completion:NULL];
    self.vc = nil;
    return YES;
}

@end
