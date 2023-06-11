#import <UIKit/UIKit.h>

@interface SurfaceView : UIView {
    CGColorSpaceRef colorSpace;
    CGDataProviderDirectCallbacks callbacks;
}

- (void)displayLayer;
@end

@interface JavaGUIViewController : UIViewController
    @property(nonatomic) NSString* filepath;
    @property(nonatomic, readonly) int requiredJavaVersion;
@end
