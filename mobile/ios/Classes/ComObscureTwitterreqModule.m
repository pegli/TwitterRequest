/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */

#import <Accounts/Accounts.h>

#import "ComObscureTwitterreqModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation ComObscureTwitterreqModule

#pragma mark Internal

-(id)moduleGUID {
	return @"bc68f0fc-621d-4768-a44e-2eb09b6cc770";
}

-(NSString*)moduleId {
	return @"com.obscure.twitterreq";
}

#pragma mark Lifecycle

-(void)startup {
	[super startup];
	
	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender {
	[super shutdown:sender];
}

#pragma mark -
#pragma mark Public API

- (void)requestAccountInformation:(id)args {
    KrollCallback * callback;
    ENSURE_ARG_AT_INDEX(callback, args, 0, KrollCallback)
    
	ACAccountStore * accountStore = [[ACAccountStore alloc] init];
    ACAccountType * accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        NSDictionary * dict = nil;
        if (granted) {
            NSArray * accountsArray = [accountStore accountsWithAccountType:accountType];
            if ([accountsArray count] > 0) {
                ACAccount * twitterAccount = [accountsArray objectAtIndex:0];
                dict = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(YES), @"granted",
                        twitterAccount.username, @"username",
                        twitterAccount.identifier, @"identifier",
                        nil];
            }
        }
        else {
            dict = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"granted", nil];
        }
        TiThreadPerformOnMainThread(^{
            [callback call:[NSArray arrayWithObject:dict] thisObject:nil];
        }, YES);
    }];
}

@end
