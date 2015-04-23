//
//  OfferViewController.h
//  WeClean
//
//  Created by Huang Jie on 4/12/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditViewController.h"

@interface OfferViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,EditViewControllerDelegate>
@property (nonatomic,strong) UITableView *tableView;
@end
