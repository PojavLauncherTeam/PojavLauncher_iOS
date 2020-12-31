//
//  ViewController.m
//

#import "CounterService.h"
#import "ViewController.h"

@implementation ViewController

- (IBAction)clicked:(id)sender {
  [CounterService increase];
  self.label.text = [NSString stringWithFormat:@"Click Nr. %d", [CounterService getCount]];
}

@end
