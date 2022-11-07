#import "LauncherPreferencesViewController2.h"
#import "SurfaceViewController.h"

@implementation SurfaceViewController(Navigation)

static UIView *menuSwipeView;
- (void)initCategory_Navigation {
    UIPanGestureRecognizer *menuPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightEdge:)];
    menuPanGesture.delegate = self;

    UIView *menuSwipeLineView = [[UIView alloc] initWithFrame:CGRectMake(11.0, self.view.frame.size.height/2 - 100.0, 8.0, 200.0)];
    menuSwipeLineView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    menuSwipeLineView.backgroundColor = UIColor.whiteColor;
    menuSwipeLineView.layer.cornerRadius = 4;
    menuSwipeLineView.userInteractionEnabled = NO;

    UIView *menuSwipeView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, 0, 30.0, self.view.frame.size.height)];
    menuSwipeView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    menuSwipeView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
    [menuSwipeView addGestureRecognizer:menuPanGesture];
    [menuSwipeView addSubview:menuSwipeLineView];
    [self.rootView addSubview:menuSwipeView];

    self.menuArray = @[@"game.menu.force_close", @"game.menu.log_output", @"Settings"];

    self.menuView = [[UITableView alloc] initWithFrame:CGRectMake(self.view.frame.size.width + 30.0, 0, 
        self.view.frame.size.width * 0.3 - 36.0 * 0.7, self.view.frame.size.height)];

    //menuView.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1];
    self.menuView.dataSource = self;
    self.menuView.delegate = self;
    self.menuView.layer.cornerRadius = 12;
    self.menuView.scrollEnabled = NO;
    self.menuView.separatorInset = UIEdgeInsetsZero;
    [self.view addSubview:self.menuView];
}

- (void)setupCategory_Navigation {
    UIScreenEdgePanGestureRecognizer *edgeGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightEdge:)];
    edgeGesture.edges = UIRectEdgeRight;
    edgeGesture.delegate = self;
    [self.surfaceView addGestureRecognizer:edgeGesture];
}

static CGPoint lastCenterPoint;
- (void)handleRightEdge:(UIPanGestureRecognizer *)sender {
    if (lastCenterPoint.y == 0) {
        lastCenterPoint.x = self.rootView.center.x;
        lastCenterPoint.y = 1;
    }

    CGFloat centerX = self.rootView.bounds.size.width / 2;
    CGFloat centerY = self.rootView.bounds.size.height / 2;

    CGPoint translation = [sender translationInView:sender.view];

    if (sender.state == UIGestureRecognizerStateBegan) {
        self.menuView.hidden = NO;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        self.rootView.center = CGPointMake(lastCenterPoint.x + translation.x/2, centerY + translation.y/10.0);
        CGFloat scale = MAX(0.7, self.rootView.center.x / centerX);
        self.rootView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);

        self.menuView.frame = CGRectMake(self.rootView.frame.size.width, self.rootView.frame.origin.y, self.menuView.frame.size.width,  self.menuView.contentSize.height);
        // scale is in range of 0.7-1
        // 1.1 - scale produces in range of 0.4-0.1
        // result in transform scale range of 1-0.25
        self.menuView.transform = CGAffineTransformScale(CGAffineTransformIdentity, (1.1-scale)*2.5, (1.1-scale)*2.5);
    } else {
        CGPoint velocity = [sender velocityInView:sender.view];
        CGFloat scale = (velocity.x >= 0) ? 1 : 0.7;

        // calculate duration to produce smooth movement
        // FIXME: any better way?
        CGFloat duration = fabs(self.rootView.center.x - centerX * scale) / centerX + 0.1;
        duration = MIN(0.4, duration);
        //(110 - MIN(100, fabs(velocity.x))) / 100

        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            lastCenterPoint.x = centerX * scale;
            self.rootView.center = CGPointMake(lastCenterPoint.x, centerY);
            self.rootView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
            self.menuView.transform = CGAffineTransformScale(CGAffineTransformIdentity, (1.1-scale)*2.5, (1.1-scale)*2.5);
            self.menuView.frame = CGRectMake(self.rootView.frame.size.width, self.rootView.frame.origin.y, self.menuView.frame.size.width, self.menuView.contentSize.height);
        } completion:^(BOOL finished) {
            self.menuView.hidden = scale == 1.0;
        }];
    }
}

- (void)actionForceClose {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
        message:NSLocalizedString(@"game.menu.confirm.force_close", nil)
        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:cancelAction];

    UIAlertAction* okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.rootView.center = CGPointMake(self.rootView.bounds.size.width/-2, self.rootView.center.y);
            self.menuView.frame = CGRectMake(self.view.frame.size.width, 0, 0, 0);
        } completion:^(BOOL finished) {
            if (fatalExitGroup == nil) {
                exit(0);
            } else {
                dispatch_group_leave(fatalExitGroup);
                fatalExitGroup = nil;
            }
        }];
    }];
    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)actionOpenPreferences {
    LauncherPreferencesViewController2 *vc = [[LauncherPreferencesViewController2 alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    if (@available(iOS 13.0, *)) {
        cell.backgroundColor = UIColor.systemFillColor;
    } else {
        cell.backgroundColor = UIColor.groupTableViewBackgroundColor;
    }

    cell.textLabel.text = NSLocalizedString(self.menuArray[indexPath.row], nil);

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case 0:
            [self actionForceClose];
            break;
        case 1:
            [self performSelector:@selector(actionToggleLogOutput)];
            break;
        case 2:
            [self actionOpenPreferences];
            break;
    }
}

- (void)viewWillTransitionToSize_Navigation:(CGRect)frame {
    if (self.rootView.transform.a != 0) {
        CGFloat centerX = self.rootView.bounds.size.width / 2;
        CGFloat centerY = self.rootView.bounds.size.height / 2;
        self.rootView.center = lastCenterPoint = CGPointMake(centerX * self.rootView.transform.a, centerY);
    }

    self.menuView.frame = CGRectMake(self.rootView.frame.size.width, self.rootView.frame.origin.y,
        frame.size.width*0.3 - 30.0*0.7, self.menuView.contentSize.height);
}

@end
