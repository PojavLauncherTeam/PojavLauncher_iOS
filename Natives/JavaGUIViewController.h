#import <UIKit/UIKit.h>

@interface SurfaceView : UIView {
    CALayer* layer;
    CGColorSpaceRef colorSpace;
    CGDataProviderDirectCallbacks callbacks;
}
@end

@interface JavaGUIViewController : UIViewController
    @property NSString* filepath;
@end
