#import <UIKit/UIKit.h>

typedef void(^CreateView)(UITableViewCell *, NSString *, NSDictionary *);
typedef id (^GetPreferenceBlock)(NSString *key);
typedef void (^SetPreferenceBlock)(NSString *key, id value);

@interface PLPrefTableViewController : UITableViewController<UITextFieldDelegate>

@property(nonatomic) CreateView typeButton, typeChildPane, typePickField, typeTextField, typeSlider, typeSwitch;

@property(nonatomic) GetPreferenceBlock getPreference;
@property(nonatomic) SetPreferenceBlock setPreference;

@property(nonatomic) NSArray<NSString*>* prefSections;
@property(nonatomic) NSMutableArray<NSNumber*>* prefSectionsVisibility;
@property(nonatomic) NSArray<NSArray<NSDictionary*>*>* prefContents;
@property(nonatomic) BOOL prefDetailVisible;

- (UIBarButtonItem *)drawHelpButton;

@end
