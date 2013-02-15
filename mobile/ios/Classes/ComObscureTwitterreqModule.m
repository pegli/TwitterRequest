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

#import "TWAPIManager.h"


@interface ComObscureTwitterreqModule ()
@property (nonatomic, retain) TWAPIManager * apiManager;
@end


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

	self.apiManager = [[TWAPIManager alloc] init];
    
	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender {
	[super shutdown:sender];
}


#pragma mark -
#pragma mark Public API

- (id)twitterAccountAvailable {
    return NUMBOOL([TWAPIManager isLocalTwitterAccountAvailable]);
}

- (void)requestAccountInformation:(id)args {
    KrollCallback * callback;
    ENSURE_ARG_AT_INDEX(callback, args, 0, KrollCallback)
    
	ACAccountStore * accountStore = [[ACAccountStore alloc] init];
    ACAccountType * accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        NSDictionary * dict = nil;
        if (granted) {
            NSArray * accountsArray = [accountStore accountsWithAccountType:accountType];
            NSMutableArray * accts = [NSMutableArray arrayWithCapacity:[accountsArray count]];
            
            for (ACAccount * twitterAccount in accountsArray) {
                [accts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                    twitterAccount.username, @"username",
                                    twitterAccount.identifier, @"identifier",
                                    nil]
                 ];
            }
            dict = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(YES), @"granted",
                    accts, @"accounts",
                    nil];
        }
        else {
            dict = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO), @"granted", nil];
        }
        
        TiThreadPerformOnMainThread(^{
            [callback call:[NSArray arrayWithObject:dict] thisObject:nil];
        }, YES);
    }];
}

- (void)requestReverseAuthToken:(id)args {
    NSString * username;
    NSString * consumerKey;
    NSString * consumerSecret;
    KrollCallback * callback;
    ENSURE_ARG_AT_INDEX(username, args, 0, NSString)
    ENSURE_ARG_AT_INDEX(consumerKey, args, 1, NSString)
    ENSURE_ARG_AT_INDEX(consumerSecret, args, 2, NSString)
    ENSURE_ARG_AT_INDEX(callback, args, 3, KrollCallback)

    ACAccountStore * accountStore = [[ACAccountStore alloc] init];
    ACAccountType * accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        if (!granted) {
            NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   NUMBOOL(NO), @"granted",
                                   [error description], @"error",
                                   nil];
            TiThreadPerformOnMainThread(^{
                [callback call:[NSArray arrayWithObject:dict] thisObject:nil];
            }, YES);
            NSLog(@"access not granted");
            return;
        }
        
        ACAccount * account = nil;
        for (ACAccount * a in [accountStore accountsWithAccountType:accountType]) {
            if ([username isEqualToString:a.username]) {
                account = a;
                break;
            }
        }

        if (!account) {
            NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   NUMBOOL(NO), @"granted",
                                   [NSString stringWithFormat:@"account '%@' not found", username], @"error",
                                   nil];
            TiThreadPerformOnMainThread(^{
                [callback call:[NSArray arrayWithObject:dict] thisObject:nil];
            }, YES);
            NSLog(@"account '%@' not found", username);
            return;
        }
        
        self.apiManager.consumerKey = consumerKey;
        self.apiManager.consumerSecret = consumerSecret;
        
        [self.apiManager performReverseAuthForAccount:account withHandler:^(NSData *responseData, NSError *error) {
            NSDictionary * dict = nil;
            if (responseData) {
                NSMutableDictionary * d = [NSMutableDictionary dictionary];
                [d setObject:NUMBOOL(YES) forKey:@"granted"];
                
                NSString * str = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                NSLog(@"success!  %@", str);
                NSArray * pairs = [str componentsSeparatedByString:@"&"];
                for (NSString * pair in pairs) {
                    NSArray * nv = [pair componentsSeparatedByString:@"="];
                    [d setObject:[(NSString *)[nv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[nv objectAtIndex:0]];
                }
                dict = d;
            }
            else {
                dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        NUMBOOL(YES), @"granted",
                        [error description], @"error",
                        nil];
            }
            
            TiThreadPerformOnMainThread(^{
                [callback call:[NSArray arrayWithObject:dict] thisObject:nil];
            }, YES);
            NSLog(@"called callback with %@", dict);
        }];
    }];
}

@end
