//
//  BecomeCleanerViewController.m
//  DormCatChat
//
//  Created by Huang Jie on 1/30/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "CleanerAccountViewController.h"
#import "AppDelegate.h"
#import "EditViewController.h"
#import <Firebase/Firebase.h>
#import "Macro.h"
#import "Utility.h"

static NSString *const CleanerAccountCellIdentifier = @"BecomeCleanerCell";

@interface CleanerAccountViewController ()

@end

@implementation CleanerAccountViewController{
    NSArray *titleArray;
    NSArray *detailArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    titleArray = [[NSArray alloc] initWithObjects:@"Phone",@"School",@"Price",@"Supplies",@"Service", nil];
    
    NSString *saveBtnString;
    
    if(self.displayDetailArray == nil || [titleArray count] != [self.displayDetailArray count]){
        detailArray = [[NSArray alloc] initWithObjects:@"Your phone number",@"Stern",@"15",@"I provide supplies",@"I clean dorm rooms and do your laundry too.", nil];
        saveBtnString = @"Submit";
    }else{
        detailArray = self.displayDetailArray;
        saveBtnString = @"Save";
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.navigationController.view.bounds.size.width, self.navigationController.view.bounds.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    UIBarButtonItem *submitItem = [[UIBarButtonItem alloc] initWithTitle:saveBtnString style:UIBarButtonItemStyleDone target:self action:@selector(submit)];
    submitItem.tintColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = submitItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)submit
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uid = [defaults objectForKey:UID];
    Firebase *cleanerbase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/cleaners/%@",FIREBASE_ROOT_URL,uid]];
    
    NSDictionary * userInfo = [defaults objectForKey:AUTH_DATA];
    
    NSMutableDictionary *cleaner_info = [[NSMutableDictionary alloc] init];
    
    if(uid != nil){
        [cleaner_info setObject:uid forKey:@"uid"];
    }
    
    NSString *name = userInfo[@"displayName"];
    if(name != nil){
        [cleaner_info setObject:name forKey:@"name"];
    }
    
    NSString *profile_url = userInfo[@"cachedUserProfile"][@"picture"][@"data"][@"url"];
    if(profile_url != nil){
        [cleaner_info setObject:profile_url forKey:@"profile_url"];
    }
    
    NSString *phone = [self.tableView cellForRowAtIndexPath:[NSIndexPath  indexPathForRow:0 inSection:0]].detailTextLabel.text;
    if(phone != nil && [self isNumberic:phone]){
        [cleaner_info setObject:phone forKey:@"phone"];
    }else{
        [Utility showMessage:@"Invalid phone number" withTitle:@"Oops"];
        return;
    }
    
    NSString *school = [self.tableView cellForRowAtIndexPath:[NSIndexPath  indexPathForRow:1 inSection:0]].detailTextLabel.text;
    if(school != nil){
        [cleaner_info setObject:school forKey:@"school"];
    }
    
    NSString *price = [self.tableView cellForRowAtIndexPath:[NSIndexPath  indexPathForRow:2 inSection:0]].detailTextLabel.text;
    if(price != nil && [self isNumberic:price]){
        [cleaner_info setObject:price forKey:@"price"];
    }else{
        [Utility showMessage:@"Price" withTitle:@"Oops"];
        return;
    }
    
    NSString *supplies = [self.tableView cellForRowAtIndexPath:[NSIndexPath  indexPathForRow:3 inSection:0]].detailTextLabel.text;
    if(supplies != nil){
        [cleaner_info setObject:supplies forKey:@"supplies"];
    }
    
    NSString *service = [self.tableView cellForRowAtIndexPath:[NSIndexPath  indexPathForRow:0 inSection:1]].detailTextLabel.text;
    if(service != nil){
        [cleaner_info setObject:service forKey:@"service"];
    }
    
    NSString *gender = userInfo[@"cachedUserProfile"][@"gender"];
    if(gender != nil){
        [cleaner_info setObject:gender forKey:@"gender"];
    }
    
    [cleanerbase updateChildValues:cleaner_info];
    [defaults setObject:cleaner_info forKey:CLEANER_INFO];
    [self.delegate updateUIAfterSubmission];
    // also save location data to database;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate updateLocation];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - table view methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CleanerAccountCellIdentifier];
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CleanerAccountCellIdentifier];
    }
    if(indexPath.section == 0){
        [cell.textLabel setText:titleArray[indexPath.row]];
        [cell.detailTextLabel setText:detailArray[indexPath.row]];
    }else{
        [cell.textLabel setText:[titleArray objectAtIndex:[titleArray count] - 1]];
        [cell.detailTextLabel setText:[detailArray objectAtIndex:[detailArray count] - 1]];
        cell.detailTextLabel.numberOfLines = 3;
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    [cell.textLabel setFont:[UIFont fontWithName:AVENIR_LIGHT size:18]];
    [cell.detailTextLabel setFont:[UIFont fontWithName:AVENIR_LIGHT size:18]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0){
        return 45;
    }else{
        return 150;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0){
        return [titleArray count]-1;
    }else{
        return 1;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell * currentCell = [tableView cellForRowAtIndexPath:indexPath];
    EditViewController *editViewController = [EditViewController new];
    editViewController.editField = currentCell.textLabel.text;
    editViewController.editValue = currentCell.detailTextLabel.text;
    editViewController.indexPath = indexPath;
    //  NSLog(@"description %@",currentCell.description);
    editViewController.delegate = self;
    [self.navigationController pushViewController:editViewController animated:YES];
}

-(void)updateNewValueAtRow:(NSIndexPath *)indexPath withValue:(NSString *)value
{
    [[self.tableView cellForRowAtIndexPath:indexPath].detailTextLabel setText:value];
}


-(BOOL)isNumberic:(NSString* )str{
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return ([str rangeOfCharacterFromSet:notDigits].location == NSNotFound);
}

@end
