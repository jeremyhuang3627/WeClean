//
//  EditViewController.m
//  DormCatChat
//
//  Created by Huang Jie on 2/2/15.
//  Copyright (c) 2015 Huang Jie. All rights reserved.
//

#import "EditViewController.h"
#import "Macro.h"
#import <Firebase/Firebase.h>
#import "AppDelegate.h"

@interface EditViewController ()

@end

@implementation EditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if([self.editValue length] > 0){
        //NSLog(@"editValue %@",self.editValue);
        [self.textField setText:self.editValue];
    }
    self.view.backgroundColor = UIColorFromRGB(FLAT_GRAY);
    [self.textField becomeFirstResponder];
    
    if([self.editField isEqualToString:PHONE]){
        self.textField.keyboardType = UIKeyboardTypePhonePad;
    }else if([[self.editField lowercaseString] isEqualToString:@"price"]){
        self.textField.keyboardType = UIKeyboardTypeNumberPad;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated{
    [self save];
}

-(void)save
{
    if(self.editField){
        [self saveToFireBase];
    }
    
    [self.delegate updateNewValueAtRow:self.indexPath withValue:self.textField.text];
    //[self.navigationController popViewControllerAnimated:YES];
}

-(void)saveToFireBase
{
    Firebase *firebase = [[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userId = [defaults objectForKey:UID];
    
    NSString *key;
    if([self.editField isEqualToString:NAME]){
        key = @"displayName";
    }else{
        key = [self.editField lowercaseString];
    }
    
    Firebase *fieldBase = [firebase childByAppendingPath:[NSString stringWithFormat:@"users/%@/%@",userId,key]];
    [fieldBase setValue:self.textField.text];
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
