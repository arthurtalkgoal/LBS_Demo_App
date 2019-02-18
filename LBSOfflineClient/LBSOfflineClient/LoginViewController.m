//
//  LoginViewController.m
//  LBSOfflineClient
//
//  Created by HU Siyan on 12/12/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//

#import "LoginViewController.h"

#import <MBProgressHUD/MBProgressHUD.h>
#import "network/NWHandler.h"

@interface LoginViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate> {
    BOOL access_granted;
    NSString *user_name, *pass_word;
}

@property (nonatomic, strong) IBOutlet UITextField *username_field, *password_field;
@property (nonatomic, weak) IBOutlet UIView *touchView;
@property (nonatomic, weak) IBOutlet UIButton *login_button;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.username_field setDelegate:self];
    [self.password_field setDelegate:self];
    access_granted = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.login_button) {
        [self.login_button setEnabled:access_granted];
    }
    
     UITapGestureRecognizer *tapping = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
    [tapping setDelegate: self];
    [self.touchView addGestureRecognizer:tapping];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MapSegue"]) {
    }
}

- (IBAction)loginSelected:(id)sender {
    
    [self grant_permitted];
    
//    if (![pass_word length] || ![user_name length]) {
//        return;
//    }
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    [self logInWith:user_name andPassword:pass_word];
}

- (void)handleTap:(UITapGestureRecognizer *)recorgnizer {
    [self.username_field resignFirstResponder];
    [self.password_field resignFirstResponder];
}

- (void)keyboardDidShow: (NSNotification *) notif {
    
}

- (void)keyboardDidHide: (NSNotification *) notif {
    
}

#pragma mark - Network Handler
- (void)logInWith:(NSString *)username andPassword:(NSString *)password {
    [NWHandler instance];
    [[NWHandler instance] serverAccessGrantByUserName:username andPssword:password success:^(id  _Nonnull responseObject) {
        [self recordCookies];
    } failure:^(NSError * _Nonnull error) {
        [self grant_refused];
        NSLog(@"Grant User Error: %@", error);
    }];
}

- (void)recordCookies {
    [[NWHandler instance] serverAccessUserID:^(id  _Nonnull responseObject) {
        [self grant_permitted];
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Grant User Error: %@", error);
//        [self grant_refused];[
        [self grant_refused];
    }];
}

- (void)grant_permitted {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    access_granted = YES;
    [self performSegueWithIdentifier:@"MapSegue" sender:self];
}

- (void)grant_refused {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    access_granted = NO;
    user_name = @"";
    pass_word = @"";
}

#pragma mark - UITextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (![[textField text] length]) {
        return NO;
    }
    if (textField.tag == 2) {
        pass_word = [textField text];
    } else {
        user_name = [textField text];
        [self.password_field becomeFirstResponder];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField reason:(UITextFieldDidEndEditingReason)reason {
    if (textField.tag == 2) {
        pass_word = [textField text];
    } else {
        user_name = [textField text];
        [self.password_field becomeFirstResponder];
    }
    
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField.tag == 2) {
        pass_word = @"";
    } else {
        user_name = @"";
    }
    return YES;
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
