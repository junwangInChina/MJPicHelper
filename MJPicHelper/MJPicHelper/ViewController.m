//
//  ViewController.m
//  MJPicHelper
//
//  Created by wangjun on 2019/10/21.
//  Copyright © 2019 wangjun. All rights reserved.
//

#import "ViewController.h"

//#import <MJPicHelper/MJPicHelperManager.h>
#import "MJPicHelper/MJPicHelperManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[MJPicHelperManager shareInstance] globalConfig];
}


@end
