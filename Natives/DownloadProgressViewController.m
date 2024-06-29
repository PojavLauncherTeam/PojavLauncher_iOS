#import <dlfcn.h>
#import <objc/runtime.h>
#import "DownloadProgressViewController.h"
#import "WFWorkflowProgressView.h"

static void *CellProgressObserverContext = &CellProgressObserverContext;
static void *TotalProgressObserverContext = &TotalProgressObserverContext;

@interface DownloadProgressViewController ()
@property NSInteger fileListCount;
@end

@implementation DownloadProgressViewController

- (instancetype)initWithTask:(MinecraftResourceDownloadTask *)task {
    self = [super init];
    self.task = task;
    return self;
}

- (void)loadView {
    [super loadView];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(actionClose)];
    self.tableView.allowsSelection = NO;

    // Load WFWorkflowProgressView
    dlopen("/System/Library/PrivateFrameworks/WorkflowUIServices.framework/WorkflowUIServices", RTLD_GLOBAL);
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
[self.task.textProgress addObserver:self
        forKeyPath:@"fractionCompleted"
        options:NSKeyValueObservingOptionInitial
        context:TotalProgressObserverContext];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
[self.task.textProgress removeObserver:self forKeyPath:@"fractionCompleted"];
}

- (void)actionClose {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSProgress *progress = object;
    if (context == CellProgressObserverContext) {
        UITableViewCell *cell = objc_getAssociatedObject(progress, @"cell");
        if (!cell) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.detailTextLabel.text = progress.localizedAdditionalDescription;
            WFWorkflowProgressView *progressView = (id)cell.accessoryView;
            progressView.fractionCompleted = progress.fractionCompleted;
            if (progress.finished) {
                [progressView transitionCompletedLayerToVisible:YES animated:YES haptic:NO];
            }
        });
    } else if (context == TotalProgressObserverContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.title = progress.localizedDescription;
            if (self.fileListCount != self.task.fileList.count) {
                [self.tableView reloadData];
            }
            self.fileListCount = self.task.fileList.count;
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.task.fileList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        WFWorkflowProgressView *progressView = [[NSClassFromString(@"WFWorkflowProgressView") alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        progressView.resolvedTintColor = self.view.tintColor;
        progressView.stopSize = 0;
        cell.accessoryView = progressView;
    }

    // Unset the last cell displaying the progress
    NSProgress *lastProgress = objc_getAssociatedObject(cell, @"progress");
    if (lastProgress) {
        objc_setAssociatedObject(lastProgress, @"cell", nil, OBJC_ASSOCIATION_ASSIGN);
        @try {
            [lastProgress removeObserver:self forKeyPath:@"fractionCompleted"];
        } @catch(id anException) {}
    }

    NSProgress *progress = self.task.progressList[indexPath.row];
    objc_setAssociatedObject(cell, @"progress", progress, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(progress, @"cell", cell, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [progress addObserver:self
        forKeyPath:@"fractionCompleted"
        options:NSKeyValueObservingOptionInitial
        context:CellProgressObserverContext];

    WFWorkflowProgressView *progressView = (id)cell.accessoryView;
    if (lastProgress.finished) {
        [progressView reset];
    }
    progressView.fractionCompleted = progress.fractionCompleted;
    [progressView transitionCompletedLayerToVisible:progress.finished animated:NO haptic:NO];
    [progressView transitionRunningLayerToVisible:!progress.finished animated:NO];

    cell.textLabel.text = self.task.fileList[indexPath.row];
    cell.detailTextLabel.text = progress.localizedAdditionalDescription;
    return cell;
}

@end
