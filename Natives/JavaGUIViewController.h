#import <UIKit/UIKit.h>

@interface SurfaceView : UIView {
    CGColorSpaceRef colorSpace;
    CGDataProviderDirectCallbacks callbacks;
}

- (void)displayLayer;
@end

@interface JavaGUIViewController : UIViewController
    @property NSString* filepath;
@end
