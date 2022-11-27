#import "SurfaceViewController.h"
#import "utils.h"

static BOOL fatalErrorOccurred;

extern UIWindow* currentWindow();

@interface LogDelegate : NSObject
@end

@interface LogDelegate()<UITableViewDataSource, UITableViewDelegate>
@end

static NSMutableArray* logLines;

@implementation LogDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return logLines.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.backgroundColor = UIColor.clearColor;
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"Menlo-Regular" size:16];
        cell.textLabel.textColor = UIColor.whiteColor;
    }
    cell.textLabel.text = logLines[indexPath.row];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *line = cell.textLabel.text;
    if (line.length == 0 || [line isEqualToString:@"\n"]) {
        return;
    }

    SurfaceViewController *vc = (id)currentWindow().rootViewController;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:line preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.sourceView = cell;
    alert.popoverPresentationController.sourceRect = cell.bounds;
    UIAlertAction *share = [UIAlertAction actionWithTitle:localize(localize(@"Share", nil), nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIView *navigationBar = vc.logOutputView.subviews[1];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[line] applicationActivities:nil];
        activityVC.popoverPresentationController.sourceView = navigationBar;
        activityVC.popoverPresentationController.sourceRect = navigationBar.bounds;
        [vc presentViewController:activityVC animated:YES completion:nil];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:share];
    [alert addAction:cancel];
    [vc presentViewController:alert animated:YES completion:nil];
}

@end

@implementation SurfaceViewController(LogView)

static LogDelegate* logDelegate;
static int logCharPerLine;

- (void)initCategory_LogView {
    logLines = NSMutableArray.new;
    logCharPerLine = self.view.frame.size.width / 10;

    self.logOutputView = [[UIView alloc] initWithFrame:CGRectOffset(self.view.frame, 0, self.view.frame.size.height)];
    self.logOutputView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.logOutputView.hidden = YES;

    UINavigationItem *navigationItem = [[UINavigationItem alloc] init];
    navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
            target:self action:@selector(actionToggleLogOutput)],
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
            target:self action:@selector(actionClearLogOutput)]
    ];
    UINavigationBar* navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    navigationBar.items = @[navigationItem];
    navigationBar.topItem.title = localize(@"game.menu.log_output", nil);
    [navigationBar sizeToFit];
    navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    self.logTableView = [[UITableView alloc] initWithFrame:self.view.frame];
    logDelegate = [[LogDelegate alloc] init];
    //self.logTableView.allowsSelection = NO;
    self.logTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.logTableView.backgroundColor = UIColor.clearColor;
    self.logTableView.contentInset = UIEdgeInsetsMake(navigationBar.frame.size.height, 0, 0, 0);
    self.logTableView.dataSource = logDelegate;
    self.logTableView.delegate = logDelegate;
    self.logTableView.layoutMargins = UIEdgeInsetsZero;
    self.logTableView.rowHeight = 20;
    self.logTableView.separatorInset = UIEdgeInsetsZero;
    self.logTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.logOutputView addSubview:self.logTableView];
    [self.logOutputView addSubview:navigationBar];
    [self.rootView addSubview:self.logOutputView];

    canAppendToLog = YES;
    [self actionStartStopLogOutput];
}

- (void)actionClearLogOutput {
    [logLines removeAllObjects];
    [self.logTableView reloadData];
}

- (void)actionShareLatestlog {
    UINavigationBar *navigationBar = self.logOutputView.subviews[1];
    NSString *latestlogPath = [NSString stringWithFormat:@"file://%s/latestlog.txt", getenv("POJAV_HOME")];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[@"latestlog.txt",
        [NSURL URLWithString:latestlogPath]] applicationActivities:nil];
    activityVC.popoverPresentationController.sourceView = navigationBar;
        activityVC.popoverPresentationController.sourceRect = navigationBar.bounds;
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)actionStartStopLogOutput {
    canAppendToLog = !canAppendToLog;
    UINavigationItem* item = ((UINavigationBar *)self.logOutputView.subviews[1]).items[0];
    item.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
            canAppendToLog ? UIBarButtonSystemItemPause : UIBarButtonSystemItemPlay
        target:self action:@selector(actionStartStopLogOutput)];
}

- (void)actionToggleLogOutput {
    if (fatalErrorOccurred) {
        [self performSelector:@selector(actionForceClose)];
        return;
    }

    UIViewAnimationOptions opt = self.logOutputView.hidden ? UIViewAnimationOptionCurveEaseOut : UIViewAnimationOptionCurveEaseIn;
    [UIView transitionWithView:self.logOutputView duration:0.4 options:UIViewAnimationOptionCurveEaseOut animations:^(void){
        CGRect frame = self.logOutputView.frame;
        frame.origin.y = self.logOutputView.hidden ? 0 : frame.size.height;
        self.logOutputView.hidden = NO;
        self.logOutputView.frame = frame;
    } completion: ^(BOOL finished) {
        self.logOutputView.hidden = self.logOutputView.frame.origin.y != 0;
    }];
}

+ (void)_appendToLog:(NSString *)line {
    if (line.length == 0) {
        return;
    }

    SurfaceViewController *instance = (id)currentWindow().rootViewController;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:logLines.count inSection:0];
    [logLines addObject:line];
    [instance.logTableView beginUpdates];
    [instance.logTableView
        insertRowsAtIndexPaths:@[indexPath]
        withRowAnimation:UITableViewRowAnimationNone];
    [instance.logTableView endUpdates];

    [instance.logTableView 
        scrollToRowAtIndexPath:indexPath
        atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

+ (void)appendToLog:(NSString *)string {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSArray *lines = [string componentsSeparatedByCharactersInSet:
            NSCharacterSet.newlineCharacterSet];
        for (NSString *line in lines) {
            [self _appendToLog:line];
        }
    });
}

+ (void)handleExitCode:(int)code {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        SurfaceViewController *instance = (id)currentWindow().rootViewController;

        if (instance.logOutputView.hidden) {
            [instance actionToggleLogOutput];
        }
        // Cleanup navigation bar
        UINavigationBar *navigationBar = instance.logOutputView.subviews[1];
        navigationBar.topItem.title = [NSString stringWithFormat:
            localize(@"game.title.exit_code", nil), code];
        navigationBar.items[0].leftBarButtonItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAction
            target:instance action:@selector(actionShareLatestlog)];
        UIBarButtonItem *exitItem = navigationBar.items[0].rightBarButtonItems[0];
        navigationBar.items[0].rightBarButtonItems = nil;
        navigationBar.items[0].rightBarButtonItem = exitItem;

        if (canAppendToLog) {
            canAppendToLog = NO;
            fatalErrorOccurred = YES;
            return;
        }
        [instance actionClearLogOutput];
        [self _appendToLog:@"... (latestlog.txt)"];
        NSString *latestlogPath = [NSString stringWithFormat:@"%s/latestlog.txt", getenv("POJAV_HOME")];
        NSString *linesStr = [NSString stringWithContentsOfFile:latestlogPath
            encoding:NSUTF8StringEncoding error:nil];
        NSArray *lines = [linesStr componentsSeparatedByCharactersInSet:
            NSCharacterSet.newlineCharacterSet];

        // Print last 100 lines from latestlog.txt
        for (int i = MAX(lines.count-100, 0); i < lines.count; i++) {
            [self _appendToLog:lines[i]];
        }

        fatalErrorOccurred = YES;
    });
}

- (void)viewWillTransitionToSize_LogView:(CGRect)frame {
    self.logOutputView.frame = frame;
}

@end
