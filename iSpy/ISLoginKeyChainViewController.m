//
//  ISLoginKeyChainViewController.m
//  iSpy
//
//  Created by Franck LETELLIER on 22/09/2014.
//  Copyright (c) 2014 cocoaHeads. All rights reserved.
//

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Imports

#import "ISLoginKeyChainViewController.h"
#import "ISHomeViewController.h"
#pragma mark - Types

#pragma mark - Defines & Constants
static NSString* const kSecAttrServiceValue = @"iSpyService";

#pragma mark - Macros

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Interface

@interface ISLoginKeyChainViewController ()

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UITextField *loginField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@property (weak, nonatomic) IBOutlet UILabel* errorLabel;


#pragma mark - Private Properties
@property (assign, nonatomic, getter = hasKeychainItem) BOOL keychainItem;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation

@implementation ISLoginKeyChainViewController

#pragma mark - Setup & Teardown

#pragma mark - Superclass Overrides

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.loginField.text = @"bond";
    self.keychainItem = YES;
    [self hideError];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    __weak ISLoginKeyChainViewController* weakSelf = self;
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: kSecAttrServiceValue,
                            (__bridge id)kSecReturnData: @YES,
                            (__bridge id)kSecUseOperationPrompt: NSLocalizedString(@"login.touchID.message", nil)
                            };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        CFTypeRef dataTypeRef = NULL;
        
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (status == errSecSuccess)
            {
                NSData *resultData = ( __bridge_transfer NSData *)dataTypeRef;
                NSString * result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
                
                if ([self checkLogin:self.loginField.text password:result])
                {
                    ISHomeViewController* homeVC = [weakSelf.storyboard instantiateViewControllerWithIdentifier:ISHomeVCIdentifier];
                    [weakSelf presentViewController:homeVC animated:YES completion:^{
                        
                    }];
                }
                else
                {
                    //mdp incorrect
                    [self displayErrorWithMessage:NSLocalizedString(@"login.fail", nil)];
                }
                
            }
            else if (status == errSecItemNotFound)
            {
                self.keychainItem = NO;
            }
            else if (status == errSecAuthFailed)
            {
            }
            else if (status == errSecUserCanceled)
            {
            }
            else
            {
            }
            
        });
        
    });


}




-(BOOL)checkLogin:(NSString*)login password:(NSString*)password
{
    return [login isEqualToString:@"bond"] && [password isEqualToString:@"007"];
}

-(void)processLogin
{
    
    NSString* password = self.passwordField.text;
     __weak ISLoginKeyChainViewController* weakSelf = self;
    if ([self checkLogin:self.loginField.text password:password])
    {
        if (self.hasKeychainItem)
        {
            [self deletePassword:^{
                [weakSelf addPassword:password];
            }];
        }
        else
        {
            [self addPassword:password];
        }
    
        ISHomeViewController* homeVC = [self.storyboard instantiateViewControllerWithIdentifier:ISHomeVCIdentifier];
        [self presentViewController:homeVC animated:YES completion:^{
            
        }];
    }
    else
    {
        [self displayErrorWithMessage:NSLocalizedString(@"login.fail", nil)];
    }
    self.passwordField.text = nil;
}




-(void) addPassword:(NSString*)password
{
    
    CFErrorRef error = NULL;
    SecAccessControlRef sacObject;
    

    sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                kSecAccessControlUserPresence, &error);
    if(sacObject == NULL || error != NULL)
    {
        NSLog(@"can't create sacObject: %@", error);
        return;
    }
    

    NSDictionary *attributes = @{
                                 (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                 (__bridge id)kSecAttrService: kSecAttrServiceValue,
                                 (__bridge id)kSecValueData: [password dataUsingEncoding:NSUTF8StringEncoding],
                                 (__bridge id)kSecUseNoAuthenticationUI: @YES,
                                 (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
                                 };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
        switch (status) {
            case errSecSuccess:
                
                break;
            case errSecDuplicateItem:
                
                break;
            case errSecItemNotFound :
                
                break;
            case errSecAuthFailed:
                
                break;
            default:
                break;
        }
    });
}

-(void) deletePassword:(void(^)())completion
{
    
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: kSecAttrServiceValue
                            };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)(query));
        //TODO : Check error
        if(completion)
            completion();
    });
}







-(void)displayErrorWithMessage:(NSString*)message
{
    self.errorLabel.hidden = NO;
    self.errorLabel.text = message;
}

-(void)hideError
{
    self.errorLabel.hidden = YES;
}

#pragma mark - Actions
-(IBAction)loginAction:(id)sender
{
    [self.loginField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self processLogin];
}

#pragma mark - XXXDataSource / XXXDelegate methods

@end
