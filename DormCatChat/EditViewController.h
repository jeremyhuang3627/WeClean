//
//  EditViewController.h
//  DormCatChat
//
//  Created by Huang Jie on 2/2/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditViewControllerDelegate <NSObject>
-(void)updateNewValueAtRow:(NSIndexPath *)indexPath withValue:(NSString *)value;
@end

@interface EditViewController : UIViewController
@property (nonatomic,strong) NSString * editField; // if this field is populated, the value for this field will be saved to firebase
@property (nonatomic,strong) NSString * editValue;
@property (nonatomic,strong) IBOutlet UITextField * textField;
@property (nonatomic,strong) NSIndexPath * indexPath;
@property (nonatomic,strong) id<EditViewControllerDelegate> delegate;
@end
