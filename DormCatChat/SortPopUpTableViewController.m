//
//  SortPopUpTableViewController.m
//  DormCatChat
//
//  Created by Huang Jie on 3/14/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "SortPopUpTableViewController.h"
#import "Macro.h"

@interface SortPopUpTableViewController ()

@end

static NSString *const SortPopUpTableViewCellIdentifier = @"SortPopUpTableViewCell";

@implementation SortPopUpTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SortPopUpTableViewCellIdentifier];
    
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SortPopUpTableViewCellIdentifier];
    }
    
    switch(indexPath.row){
        case 0:
            [cell.textLabel setText:@"by distance"];
            break;
        case 1:
            [cell.textLabel setText:@"by price"];
            break;
        case 2:
            [cell.textLabel setText:@"by rating"];
            break;
    }
    [cell.textLabel setFont:[UIFont fontWithName:AVENIR_LIGHT size:12]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.delegate cellTapped:indexPath];
}

@end
