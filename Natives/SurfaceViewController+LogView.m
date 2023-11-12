#import "SurfaceViewController.h"
#import "utils.h"

@implementation SurfaceViewController(LogView)

- (void)initCategory_LogView {
    self.logOutputView = [[PLLogOutputView alloc] initWithFrame:self.view.frame];
    [self.rootView addSubview:self.logOutputView];
}

- (void)viewWillTransitionToSize_LogView:(CGRect)frame {
    self.logOutputView.frame = frame;
}

@end
