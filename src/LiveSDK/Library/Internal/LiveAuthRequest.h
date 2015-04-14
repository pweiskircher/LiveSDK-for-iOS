//
//  LiveAuthRequest.h
//  Live SDK for iOS
//
//  Copyright 2015 Microsoft Corporation
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


#import <Foundation/Foundation.h>
#import "LiveAuthDelegate.h"
#import "LiveAuthDialog.h"
#import "LiveAuthDialogDelegate.h"
#import "LiveConnectSession.h"

@class LiveConnectClientCore;

// An enum type representing the user's session status.
typedef NS_ENUM(unsigned int, LiveAuthRequstStatus) 
{
    AuthNotStarted  = 0,
    AuthAuthorized = 1,
    AuthRefreshToken = 2,
    AuthTokenRetrieved = 3,
    AuthFailed = 4,
    AuthCompleted = 5
    
};

// Represents a Live service authorization request that handes
// 1) Ask the user to authorize the app for specific scopes.
// 2) Get access token with refresh token.
@interface LiveAuthRequest : NSObject<LiveAuthDialogDelegate>
{
@private 
    LiveConnectClientCore *_client;
    NSArray *_scopes;
    id<LiveAuthDelegate>_delegate;
    id _userState;
    
} 

@property (nonatomic, readonly) BOOL isUserInvolved;
@property (nonatomic) NSString *authCode;
@property (nonatomic) LiveConnectSession *session;
@property (nonatomic) UIViewController *currentViewController;
@property (nonatomic) LiveAuthDialog *authViewController;
@property (nonatomic) LiveAuthRequstStatus status;
@property (nonatomic) NSError *error;
@property (nonatomic) id tokenConnection;
@property (nonatomic) NSMutableData *tokenResponseData;

- (instancetype) initWithClient:(LiveConnectClientCore *)client
               scopes:(NSArray *)scopes
currentViewController:(UIViewController *)currentViewController
             delegate:(id<LiveAuthDelegate>)delegate
            userState:(id)userState NS_DESIGNATED_INITIALIZER;
                
- (void)execute;
- (void)process;
- (void)authorize;
- (void)retrieveToken;
- (void)complete;

@end
