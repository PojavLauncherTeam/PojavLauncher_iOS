#import "CustomControlsViewController.h"
#import "customcontrols/ControlDrawer.h"
#import "customcontrols/ControlLayout.h"
#import "utils.h"

@implementation CustomControlsViewController(UndoManager)

- (void)doAddButton:(ControlButton *)button atIndex:(NSNumber *)index {
    NSUndoManager *undo = self.undoManager;

    if ([button isKindOfClass:[ControlSubButton class]]) {
        undo.actionName = localize(@"custom_controls.button_menu.add_subbutton", nil);

        [self.ctrlView addSubview:button];
        ControlDrawer *drawer = ((ControlSubButton *)button).parentDrawer;
        [drawer.buttons insertObject:button atIndex:index.intValue]; 
        [drawer.drawerData[@"buttonProperties"] insertObject:button.properties atIndex:index.intValue];
        [drawer syncButtons];
    } else if ([button isKindOfClass:[ControlDrawer class]]) {
        undo.actionName = localize(@"custom_controls.control_menu.add_drawer", nil);

        for (ControlSubButton *subButton in ((ControlDrawer *)button).buttons) {
            [self.ctrlView addSubview:subButton];
        }
        [self.ctrlView.layoutDictionary[@"mDrawerDataList"] insertObject:((ControlDrawer *)button).drawerData atIndex:index.intValue];
        [self.ctrlView addSubview:button];
    } else {
        undo.actionName = localize(@"custom_controls.control_menu.add_button", nil);
        [self.ctrlView.layoutDictionary[@"mControlDataList"] insertObject:button.properties atIndex:index.intValue];
        [self.ctrlView addSubview:button];
    }

    [[undo prepareWithInvocationTarget:self] doRemoveButton:button];
    if (undo.isUndoing) {
        undo.actionName = localize(@"Remove", nil);
    }
}

- (void)doRemoveButton:(ControlButton *)button {
    NSNumber *index;
    if ([button isKindOfClass:[ControlSubButton class]]) {
        ControlDrawer *parent = ((ControlSubButton *)button).parentDrawer;
        index = @([parent.drawerData[@"buttonProperties"] indexOfObject:button.properties]);
        [parent.buttons removeObject:button];
        [parent.drawerData[@"buttonProperties"] removeObject:button.properties];
        [parent syncButtons];
    } else if ([button isKindOfClass:[ControlDrawer class]]) {
        ControlDrawer *drawer = (ControlDrawer *)button;
        index = @([self.ctrlView.layoutDictionary[@"mDrawerDataList"] indexOfObject:drawer.drawerData]);
        [drawer.buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.ctrlView.layoutDictionary[@"mDrawerDataList"] removeObject:drawer.drawerData];
    } else {
        index = @([self.ctrlView.layoutDictionary[@"mControlDataList"] indexOfObject:button.properties]);
        [self.ctrlView.layoutDictionary[@"mControlDataList"] removeObject:button.properties];
    }
    [button removeFromSuperview];
    self.resizeView.hidden = YES;

    NSUndoManager *undo = self.undoManager;
    [[undo prepareWithInvocationTarget:self] undoRemoveButton:button atIndex:index];
    if (!undo.isUndoing) {
        undo.actionName = localize(@"Remove", nil);
    }
}

- (void)undoRemoveButton:(ControlButton *)button atIndex:(NSNumber *)index {
    NSUndoManager *undo = self.undoManager;
    if (!undo.isUndoing) {
        undo.actionName = localize(@"Remove", nil);
    }
    [self doAddButton:button atIndex:index];
}

- (void)doMoveOrResizeButton:(ControlButton *)button from:(CGRect)from to:(CGRect)to
{
    NSUndoManager *undo = self.undoManager;
    [[undo prepareWithInvocationTarget:self] doMoveOrResizeButton:button from:to to:from];
    if (!undo.isUndoing) {
        if (CGSizeEqualToSize(from.size, to.size)) {
            undo.actionName = localize(@"Move", nil);
        } else {
            undo.actionName = localize(@"Resize", nil);
        }
    }

    [button snapAndAlignX:to.origin.x Y:to.origin.y];
    button.properties[@"width"] = @(to.size.width);
    button.properties[@"height"] = @(to.size.height);
    [button update];
    self.resizeView.frame = CGRectMake(CGRectGetMaxX(button.frame), CGRectGetMaxY(button.frame), self.resizeView.frame.size.width, self.resizeView.frame.size.height);
}

- (void)doUpdateButton:(ControlButton *)button from:(NSMutableDictionary *)from to:(NSMutableDictionary *)to
{
    NSUndoManager *undo = self.undoManager;
    [[undo prepareWithInvocationTarget:self] doUpdateButton:button from:to to:from];
    if (!undo.isUndoing) {
        undo.actionName = localize(@"Edit", nil);
    }

    for (NSString *key in to) {
        button.properties[key] = to[key];
    }

    @try {
        [button update];
    } @catch (NSException *exception) {
        button.properties[@"dynamicX"] = to[@"dynamicX"] = from[@"dynamicX"];
        button.properties[@"dynamicY"] = to[@"dynamicY"] = from[@"dynamicY"];
        @throw exception;
    }
}

@end
