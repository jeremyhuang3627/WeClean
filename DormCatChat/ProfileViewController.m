//
//  SecondViewController.m
//  DormCatChat
//
//  Created by Huang Jie on 1/18/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "ProfileViewController.h"
#import "CleanerProfileCell.h"
#import "ImageProcessor.h"
#import "AppDelegate.h"
#import "CleanerDetailViewController.h"
#import <Firebase/Firebase.h>
#import "Macro.h"
#import "MBProgressHUD.h"
#import "DXPopover.h"
#import "SortPopUpTableViewController.h"
#import "Utility.h"

static NSString *const CleanerCellIdentifier = @"CleanerProfileCell";

typedef enum {
    SortByDistance,
    SortByRating,
    SortByPrice
} SortMode;

@implementation ProfileViewController
{
    NSMutableArray *cleaners;
    NSMutableSet *uidSet;
    CLLocation * userLocation;
    DXPopover *popover;
    UITableView *sortPopUpTableView;
    SortPopUpTableViewController *sortPopUpTableViewController;
    NSCache *_imageCache;
}

-(void)viewDidLoad
{
    //imageProcessor = [ImageProcessor new];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    UINib *cellNib = [UINib nibWithNibName:CleanerCellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:CleanerCellIdentifier];
    self.tableView.rowHeight = 80;
   // [self.tableView layoutSubviews];
    
    AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _imageCache = appDelegate.globalImageCache;
    cleaners = [[NSMutableArray alloc] init];
    uidSet = [[NSMutableSet alloc] init];
    [self setUpSortPopUpContainer];
    [self loadData];
}

-(void)setUpSortPopUpContainer
{
    popover = [DXPopover new];
    sortPopUpTableViewController = [SortPopUpTableViewController new];
    sortPopUpTableViewController.delegate = self;
    sortPopUpTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 120, 150) style:UITableViewStyleGrouped];
    sortPopUpTableView.scrollEnabled = NO;
    sortPopUpTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, sortPopUpTableView.bounds.size.width, 0.01f)];
    sortPopUpTableView.rowHeight = 50;
    sortPopUpTableView.delegate = sortPopUpTableViewController;
    sortPopUpTableView.dataSource = sortPopUpTableViewController;
}

-(void)viewDidAppear:(BOOL)animated{
    UIBarButtonItem *sortItem = [[UIBarButtonItem alloc] initWithTitle:@"Sort" style:UIBarButtonItemStylePlain target:self action:@selector(sortBtnTapped)];
    sortItem.tintColor = [UIColor whiteColor];
    [sortItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
     [UIFont fontWithName:AVENIR_LIGHT size:18], NSFontAttributeName,nil] forState:UIControlStateNormal];
    
    UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh.png"] style:UIBarButtonItemStylePlain target:self action:@selector(loadData)];
    refreshItem.tintColor = [UIColor whiteColor];
    self.parentTabBarController.navigationItem.leftBarButtonItem = sortItem;
    self.parentTabBarController.navigationItem.rightBarButtonItem = refreshItem;
    [Utility addTitleLabelToNavigationItem:self.parentTabBarController.navigationController.navigationBar.topItem withText:@"Cleaners"];
    [self.tableView reloadData];
}

-(void)sortBtnTapped{
    if(popover.superview){
        [popover dismiss];
        return;
    }
    CGPoint showPoint = CGPointMake(5, 5);
    //showPoint.y += self.parentTabBarController.navigationController.view.frame.size.height;
    popover.maskType = DXPopoverMaskTypeNone;
    [popover showAtPoint:showPoint popoverPostion:DXPopoverPositionDown withContentView:sortPopUpTableView inView:self.view];
}

-(void)sortBy:(SortMode)mode{
    switch (mode) {
        case SortByDistance:
            cleaners = [[cleaners sortedArrayUsingComparator:^NSComparisonResult(id cleaner1, id cleaner2) {
                NSNumber *distance1 = cleaner1[@"distance"];
                NSNumber *distance2 = cleaner2[@"distance"];
                return [distance1 compare:distance2];
            }] mutableCopy];
            break;
        case SortByPrice:
            cleaners = [[cleaners sortedArrayUsingComparator:^NSComparisonResult(id cleaner1, id cleaner2) {
                NSNumber *price1 = [NSNumber numberWithDouble:[cleaner1[@"price"] doubleValue]];
                NSNumber *price2 = [NSNumber numberWithDouble:[cleaner2[@"price"] doubleValue]];
                
                NSLog(@"price1 %@ price2 %@",price1,price2);
                return [price1 compare:price2];
            }] mutableCopy];
            break;
        case SortByRating:
            cleaners = [[cleaners sortedArrayUsingComparator:^NSComparisonResult(id cleaner1, id cleaner2) {
                NSNumber *rating1 = [NSNumber numberWithDouble:[cleaner1[AVERAGE_REVIEW_RATING] doubleValue]];
                NSNumber *rating2 = [NSNumber numberWithDouble:[cleaner2[AVERAGE_REVIEW_RATING] doubleValue]];
                
                NSLog(@"rating1 %@ price2 %@",rating1,rating2);
                return [rating2 compare:rating1];
            }] mutableCopy];
            break;
        default:
            break;
    }
    [self.tableView reloadData];
}

-(void)loadData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [cleaners removeAllObjects];
        [uidSet removeAllObjects];
        Firebase *cleanersbase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/cleaners",FIREBASE_ROOT_URL]];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        userLocation = [[CLLocation alloc] initWithLatitude:[[defaults objectForKey:LATITUDE] doubleValue] longitude:[[defaults objectForKey:LONGITUDE] doubleValue]];
        
        [cleanersbase observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot){
            for(id key in snapshot.value){
                if(![uidSet containsObject:key]){
                    [uidSet addObject:key];
                    NSMutableDictionary *dict = [snapshot.value[key] mutableCopy];
                    CLLocation *cleanerLocation = [[CLLocation alloc] initWithLatitude:[dict[LATITUDE] doubleValue] longitude:[dict[LONGITUDE] doubleValue]];
                    CLLocationDistance distance = [userLocation distanceFromLocation:cleanerLocation];
                    [dict setObject:[NSNumber numberWithDouble:distance] forKey:@"distance"];
                    double totalReview = 0;
                    int count = 0;
                    for(NSString* key in dict[@"reviews"]){
                        totalReview += [dict[@"reviews"][key][@"review_rating"] intValue];
                        count++;
                    }
                    
                    NSNumber *averageRating;
                    
                    if(count > 0){
                        averageRating = [NSNumber numberWithDouble:totalReview/count];
                    }else{
                        averageRating = [NSNumber numberWithDouble:0];
                    }
                    
                    [dict setObject:averageRating forKey:AVERAGE_REVIEW_RATING];
                    [cleaners addObject:dict];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
    });
}

#pragma mark - SortPopUpTableViewControllerDelegate methods

-(void)cellTapped:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            [self sortBy:SortByDistance];
            break;
        case 1:
            [self sortBy:SortByPrice];
            break;
        case 2:
            [self sortBy:SortByRating];
            break;
    }
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CleanerProfileCell *cell = (CleanerProfileCell *)[tableView dequeueReusableCellWithIdentifier:CleanerCellIdentifier];
    NSDictionary *cleaner = cleaners[indexPath.row];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // cleaner profile image;
        NSString *imageStringURLString = cleaner[@"profile_url"];
        UIImage *img;
        if([_imageCache objectForKey:imageStringURLString]==nil){
            img =  [ImageProcessor imageFromURL:imageStringURLString];
            if(img != nil){
                [_imageCache setObject:img forKey:imageStringURLString];
            }else{
                img = [UIImage imageNamed:@"missingAvatar.png"];
            }
        }else{
            img = [_imageCache objectForKey:imageStringURLString];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell.profileImage setImage:[ImageProcessor roundCorneredImage:img radius:8]];
        });
    });
    
    [cell.distance setText:[NSString stringWithFormat:@" %@",[Utility friendlyDistance:cleaner[@"distance"]]]];
    cell.staticStarRatingView.rating = [cleaner[AVERAGE_REVIEW_RATING] doubleValue];
    cell.staticStarRatingView.canEdit = NO;
    cell.staticStarRatingView.delegate = self;
    if([cleaner[@"gender"] isEqualToString:@"male"]){
        [cell.genderIcon setImage:[UIImage imageNamed:@"male.png"]];
    }else{
        [cell.genderIcon setImage:[UIImage imageNamed:@"female.png"]];
    }
    
    [cell.username setText:[NSString stringWithFormat:@" %@",cleaner[@"name"]]];
    [cell.details setText:[NSString stringWithFormat:@" %@",cleaner[@"service"]]];
    // cleaner price tag
    [cell.priceLabel setText:[NSString stringWithFormat:@" $%@/h",cleaner[@"price"]]];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //NSLog(@"cleaners count %d",[cleaners count]);
    return [cleaners count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CleanerDetailViewController *cleanerDetailViewController = [CleanerDetailViewController new];
    cleanerDetailViewController.cleanerInfo = [cleaners objectAtIndex:indexPath.row];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.navigationController pushViewController:cleanerDetailViewController animated:YES];
}

#pragma mark ASStarRatingViewDelegate methods

-(void)bubbleTouchUp:(NSSet *)touches{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchLocation];
    [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

@end
