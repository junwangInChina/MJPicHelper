//
//  MJPicHelperManager.m
//  MJPicHelper
//
//  Created by wangjun on 2019/10/21.
//  Copyright © 2019 wangjun. All rights reserved.
//

#import "MJPicHelperManager.h"

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

@end
