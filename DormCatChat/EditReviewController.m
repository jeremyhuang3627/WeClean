//
//  AddReviewViewController.m
//  DormCatChat
//
//  Created by Huang Jie on 2/7/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "EditReviewController.h"
#import "Macro.h"
#import <Firebase/Firebase.h>

@interface EditReviewController ()

@end

@implementation EditReviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = UIColorFromRGB(FLAT_GRAY);
    
    if(self.reviewInfo == nil){
    [self.reviewInputView becomeFirstResponder];
    UIBarButtonItem *submitItem = [[UIBarButtonItem alloc] initWithTitle:@"Submit" style:UIBarButtonItemStyleDone target:self action:@selector(submit)];
    submitItem.tintColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = submitItem;
    }else{
        [self.reviewInputView setText:self.reviewInfo[@"review_text"]];
        self.reviewInputView.editable = NO;
        
        //adjustable reviewInputView.height leaves for future versions;
       // [self textViewDidChange:self.reviewInputView];
        
        self.starRatingView.rating = [self.reviewInfo[@"review_rating"] floatValue];
        self.starRatingView.maxRating = 5;
        self.starRatingView.canEdit = NO;
    }
    
    [self.reviewInputView setFont:[UIFont fontWithName:AVENIR_LIGHT size:17]];
    [self.reviewInputView setTextColor:[UIColor grayColor]];
}

-(void)submit
{
    Firebase *cleanerBase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/cleaners/%@",FIREBASE_ROOT_URL,self.cleanerUID]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *reviewDictionary = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:AUTH_DATA]];
    
    [reviewDictionary setObject:self.reviewInputView.text forKey:@"review_text"];
    [reviewDictionary setObject:[NSNumber numberWithFloat:self.starRatingView.rating] forKey:@"review_rating"];
    
    // the storage path is [root_url]/cleaners/[cleaner_id]/reviews/[reviewer_id]
    //NSLog(@"UID %@",NSStringFromClass([[defaults objectForKey:UID] class]));
    [[cleanerBase childByAppendingPath:[NSString stringWithFormat:@"reviews/%@",[defaults objectForKey:UID]]] setValue:reviewDictionary];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)textViewDidChange:(UITextView *)textView
{
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    newSize.height += 50; // increase height by 50 pixel;
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    NSLog(@"newSize.height %f",newFrame.size.height);
    textView.frame = newFrame;
    //textView.scrollEnabled = NO;
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
