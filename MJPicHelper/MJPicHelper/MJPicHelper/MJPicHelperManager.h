//
//  MJPicHelperManager.h
//  MJPicHelper
//
//  Created by wangjun on 2019/10/21.
//  Copyright © 2019 wangjun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MJPicHelperManager : NSObject

+ (MJPicHelperManager *)shareInstance;

- (void)globalConfig;

@end

NS_ASSUME_NONNULL_END
