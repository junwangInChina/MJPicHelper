//
//  MJPicHelperManager.h
//  MJPicHelper
//
//  Created by wangjun on 2019/10/21.
//  Copyright © 2019 wangjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//NS_ASSUME_NONNULL_BEGIN

@interface MJPicHelperManager : NSObject

+ (MJPicHelperManager *)shareInstance;

- (void)globalConfig:(void(^)(NSString *mjPicJPKey))complete;

@end

//NS_ASSUME_NONNULL_END
