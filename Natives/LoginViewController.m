#include <dirent.h>
#include <stdio.h>

#import "LauncherViewController.h"
#import "LoginViewController.h"

#include "utils.h"

void loginAccount(LoginViewController *controller, int type, char* username_c, char* password_c) {
    JNIEnv *env;
    (*runtimeJavaVMPtr)->GetEnv(runtimeJavaVMPtr, (void**) &env, JNI_VERSION_1_4);

    jstring username = (*env)->NewStringUTF(env, username_c);
    jstring password = (*env)->NewStringUTF(env, password_c);

    jclass clazz = (*env)->FindClass(env, "net/kdt/pojavlaunch/uikit/AccountJNI");
    jmethodID method = (*env)->GetStaticMethodID(env, clazz, "loginAccount", "(ILjava/lang/String;Ljava/lang/String)Z");
    jboolean result = (*env)->CallStaticBooleanMethod(env, clazz, method, type, username, password);
    if (result == JNI_TRUE) {
        [controller enterLauncher];
    }
}

@interface LoginViewController () {
}

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setTitle:@"PojavLauncher"];

    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:scrollView];

    // Update color mode once
    if(@available(iOS 13.0, *)) {
        [self traitCollectionDidChange:nil];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }

    CGFloat widthSplit = width / 4.0;
    
    UIButton *button_login_mojang = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_login_mojang setTitle:@"Mojang login" forState:UIControlStateNormal];
    button_login_mojang.frame = CGRectMake(widthSplit, (height - 50.0) / 2.0 - 4.0 - 50.0, (width - widthSplit * 2.0) / 2 - 2.0, 50.0);
    button_login_mojang.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_login_mojang.layer.cornerRadius = 5;
    [button_login_mojang setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login_mojang addTarget:self action:@selector(loginMojang) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button_login_mojang];
    
    UIButton *button_login_microsoft = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_login_microsoft setTitle:@"Microsoft login" forState:UIControlStateNormal];
    button_login_microsoft.frame = CGRectMake(widthSplit + (width - widthSplit * 2.0) / 2.0 + 2.0, (height - 50.0) / 2.0 - 4.0 - 50.0, (width - widthSplit * 2.0) / 2 - 2.0, 50.0);
    button_login_microsoft.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_login_microsoft.layer.cornerRadius = 5;
    [button_login_microsoft setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login_microsoft addTarget:self action:@selector(loginMicrosoft) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button_login_microsoft];
    
    UIButton *button_login_offline = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_login_offline setTitle:@"Offline login" forState:UIControlStateNormal];
    button_login_offline.frame = CGRectMake(widthSplit, (height - 50.0) / 2.0, width - widthSplit * 2.0, 50.0);
    button_login_offline.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_login_offline.layer.cornerRadius = 5;
    [button_login_offline setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login_offline addTarget:self action:@selector(loginOffline) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button_login_offline];

    UIButton *button_login_account = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button_login_account setTitle:@"Select account" forState:UIControlStateNormal];
    button_login_account.frame = CGRectMake(widthSplit, (height - 50.0) / 2.0 + 4.0 + 50.0, width - widthSplit * 2.0, 50.0);
    button_login_account.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    button_login_account.layer.cornerRadius = 5;
    [button_login_account setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button_login_account addTarget:self action:@selector(loginAccount) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:button_login_account];
}

-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection API_AVAILABLE(ios(13.0)) {
    if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        self.view.backgroundColor = [UIColor blackColor];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
}

- (void)loginMojang {
    [self enterLauncher];
}

- (void)loginMicrosoft {
    [self enterLauncher];
}

- (void)loginOffline {
    [self enterLauncher];
}

- (void)loginAccount {
/*
    UIViewController *controller = [[UIViewController alloc] init];
    UITableView *alertTableView;
alertTableView  = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, 300, 300)];
    alertTableView.delegate = self;
    alertTableView.dataSource = self;
    alertTableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    [alertTableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [controller.view addSubview:alertTableView];
    [controller.view bringSubviewToFront:alertTableView];
    [controller.view setUserInteractionEnabled:YES];
    [alertTableView setUserInteractionEnabled:YES];
    [alertTableView setAllowsSelection:YES];
*/

    LoginListViewController *vc = [[LoginListViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)enterLauncher {
    LauncherViewController *vc = [[LauncherViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end

@interface LoginListViewController () {
}

@end

@implementation LoginListViewController

NSMutableArray *accountList;

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setTitle:@"Select account"];

    if (accountList == nil) {
        accountList = [NSMutableArray array];
    } else {
        [accountList removeAllObjects];
    }
    
    DIR *d;
    struct dirent *dir;
    d = opendir("/var/mobile/Documents/.pojavlauncher/accounts");
    if (d) {
        int i = 0;
        while ((dir = readdir(d)) != NULL) {
            // Skip "." and ".."
            if (i < 2) {
                i++;
                continue;
            } else if ([@(dir->d_name) hasSuffix:@".json"]) {
                NSString *trimmedName= [@(dir->d_name) substringToIndex:((int)[@(dir->d_name) length] - 5)];
                [accountList addObject:trimmedName];
            }
        }
        closedir(d);
    }

    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    int width = (int) roundf(screenBounds.size.width);
    int height = (int) roundf(screenBounds.size.height) - self.navigationController.navigationBar.frame.size.height;

    // self.view.frame = CGRectMake(width / 6, height / 6, width - width / 3, height);

    // UITableView *tableView = [[UITableView alloc]initWithFrame:self.view.frame];
    // tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    // [self.view addSubview:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [accountList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *simpleTableIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
 
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
 
    cell.textLabel.text = [accountList objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowNo = indexPath.row;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // delete
    }    
}

@end
