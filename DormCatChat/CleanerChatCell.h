//
//  CleanerTableViewCell.h
//  DormCatChat
//
//  Created by Huang Jie on 1/18/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CleanerChatCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *userName;
@property (nonatomic, weak) IBOutlet UILabel *lastMessage;
@property (nonatomic, weak) IBOutlet UILabel *date;
@property (nonatomic, weak) IBOutlet UIImageView *profileImage;
@end
