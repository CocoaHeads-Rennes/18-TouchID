//
//  IPLoginViewController.m
//  iSpy
//
//  Created by Franck LETELLIER on 22/09/2014.
//  Copyright (c) 2014 cocoaHeads. All rights reserved.
//

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Imports

#import "ISLoginViewController.h"
#import "ISHomeViewController.h"
@import LocalAuthentication;

#pragma mark - Types

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Interface

@interface ISLoginViewController ()

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation

@implementation ISLoginViewController

#pragma mark - Setup & Teardown

#pragma mark - Public methods

#pragma mark - Private methods
-(void) displayFallbackPopup
{
    __weak ISLoginViewController* weakSelf = self;
    UIAlertController* vc = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"local.fallback.title",)
                                                                message:NSLocalizedString(@"local.fallback.message",)
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [vc addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"local.fallback.cancel",) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Actions
-(IBAction)loginAction:(id)sender
{
    LAContext *context = [[LAContext alloc] init];
    
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil] == NO)
    {
        return;
    }
    
    __weak ISLoginViewController* weakSelf = self;
    // set text for the localized fallback button
    context.localizedFallbackTitle = NSLocalizedString(@"local.fallback.text",nil);
    
    // show the authentication UI with our reason string
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:NSLocalizedString(@"touchID.setting.title", nil) reply:
     ^(BOOL success, NSError *authenticationError) {
         if (success)
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 ISHomeViewController* homeVC = [weakSelf.storyboard instantiateViewControllerWithIdentifier:ISHomeVCIdentifier];

                 [weakSelf presentViewController:homeVC animated:YES completion:nil];
             });
         }
         else
         {
             //TODO FALLBACK;
             switch (authenticationError.code)
             {
                 case LAErrorAuthenticationFailed:  NSLog(@"Authentication Failed");break;
                 case LAErrorUserCancel:            NSLog(@"User pressed Cancel button");break;
                 case LAErrorUserFallback:
                 {
                     [weakSelf displayFallbackPopup];
                 }
                 break;
                 default:   NSLog(@"Touch ID is not configured");break;
             }
         }
         
     }];
}




@end
