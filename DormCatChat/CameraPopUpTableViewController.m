//
//  CameraPopUpViewController.m
//  DormCatChat
//
//  Created by Huang Jie on 2/23/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "CameraPopUpTableViewController.h"
#import "Macro.h"

static NSString *const CameraPopUpTableViewCellIdentifier = @"CameraPopUpTableViewCell";

@interface CameraPopUpTableViewController ()

@end

@implementation CameraPopUpTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CameraPopUpTableViewCellIdentifier];
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CameraPopUpTableViewCellIdentifier];
    }
    
    if(indexPath.row == 0){
        [cell.textLabel setText:@"Take Photo"];
    }else{
        [cell.textLabel setText:@"Choose Photo"];
    }
    [cell.textLabel setFont:[UIFont fontWithName:AVENIR_LIGHT size:12]];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //NSLog(@"chatPeople count %d",[chatPeople count]);
    return 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSLog(@"tapped %d",indexPath.row);
    [self.delegate cellTapped:indexPath];
}
@end
