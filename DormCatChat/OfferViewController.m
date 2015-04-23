//
//  OfferViewController.m
//  WeClean
//
//  Created by Huang Jie on 4/12/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "OfferViewController.h"
#import "Macro.h"
#import "AppDelegate.h"

@interface OfferViewController ()

@end

static NSString * OfferViewCellIdentifier = @"OfferViewCellIdentifier";
static NSString * OfferDescriptionCellIdentifier = @"OfferDescriptionCellIdentifier";

@implementation OfferViewController{
    NSArray *titleArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CGSize windowSize = appDelegate.navigationController.view.frame.size;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, windowSize.width, windowSize.height) style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    UINib *cellNib = [UINib nibWithNibName:@"OfferDescriptionCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:OfferDescriptionCellIdentifier];
    titleArray = [NSArray arrayWithObjects:@"When",@"Where",@"Price",@"Details",nil];
    self.view.backgroundColor = UIColorFromRGB(CHAT_BACKGROUND);
    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:OfferViewCellIdentifier];
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:OfferViewCellIdentifier];
        [cell.textLabel setFont:[UIFont fontWithName:AVENIR_LIGHT size:15]];
        [cell.textLabel setTextColor:[UIColor grayColor]];
        [cell.detailTextLabel setFont:[UIFont fontWithName:AVENIR_LIGHT size:15]];
    }
    [cell.textLabel setText:[titleArray objectAtIndex:indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0){
        return 45;
    }else{
        return 80;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0){
        return 3;
    }else if(section == 1){
        return 1;
    }else{
        return 0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString * topBarString = cell.textLabel.text;
    EditViewController *editViewController = [EditViewController new];
    editViewController.delegate = self;
    editViewController.indexPath = indexPath;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //[appDelegate.navigationController.navigationBar.topItem setTitle:topBarString];
    [appDelegate.navigationController pushViewController:editViewController animated:YES];
}

-(void)updateNewValueAtRow:(NSIndexPath *)indexPath withValue:(NSString *)value;{
    UITableViewCell *cell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell.detailTextLabel setText:value];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
