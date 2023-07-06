#import "PLPickerView.h"

@implementation PLPickerView
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.imageView.image = [(id<PLPickerViewDelegate>)self.delegate pickerView:self imageForRow:indexPath.row forComponent:indexPath.section];
    return cell;
}

- (UIImage *)imageAtRow:(NSInteger)row column:(NSInteger)column {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:column];
    return [self tableView:[self tableViewForColumn:0] cellForRowAtIndexPath:indexPath].imageView.image;
}
@end
