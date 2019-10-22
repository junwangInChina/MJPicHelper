//
//  MJPicWKController.m
//  MJPicHelper
//
//  Created by wangjun on 2019/10/21.
//  Copyright © 2019 wangjun. All rights reserved.
//

#import "MJPicWKController.h"

#import <SVProgressHUD/SVProgressHUD.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

#define MJ_SCREEN_IS_IPHONE_X \
([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) && DEVICE_IS_IPHONE : NO)

#define MJ_SCREEN_IS_IPHONE_XR \
([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size) && DEVICE_IS_IPHONE : NO)

#define MJ_SCREEN_IS_IPHONE_XS \
([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) && DEVICE_IS_IPHONE : NO)

#define MJ_SCREEN_IS_IPHONE_XS_MAX \
([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) && DEVICE_IS_IPHONE : NO)

#define MJ_SCREEN_IS_IPHONE_X_PRODUCTS \
([UIScreen mainScreen].bounds.size.height == 812 || [UIScreen mainScreen].bounds.size.height == 896)

#define MJ_SCREEN_IS_IPHONE_P_PRODUCTS \
([UIScreen mainScreen].bounds.size.height == 736)

#define MJ_SCREEN_BOTTOM_SAFE_AREA     (MJ_SCREEN_IS_IPHONE_X_PRODUCTS ? 34 : 0)
#define MJ_SCREEN_STATUS_NAV_HEIGHT    (MJ_SCREEN_IS_IPHONE_X_PRODUCTS ? 88 : 64)
#define MJ_SCREEN_STATUS_HEIGHT        (MJ_SCREEN_IS_IPHONE_X_PRODUCTS ? 44 : 20)

@interface MJPicWKController ()<WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, copy) NSString *mjPicHomePageUrl;
@property (nonatomic, strong) WKWebView *mjPicWkweb;
@property (nonatomic, strong) UIView *mjPicErrorView;
@property (nonatomic, strong) UIView *mjPicToolbarView;

@end

@implementation MJPicWKController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.mjPicWkweb stopLoading];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    @try {
        // 移除观察者
        [self.mjPicWkweb removeObserver:self forKeyPath:@"estimatedProgress"];
    }
    @catch (NSException *ex){
        
    }
}

- (instancetype)initWithURL:(NSString *)url;
{
    self = [super init];
    if (self)
    {
        self.mjPicHomePageUrl = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self configMJPicAFNetworkActivity];
    
    [self configMJPicNotification];
    
    [self configMJPicWkwebObserver];
    
    [self loadMJPicWkwebUI];
}

#pragma mark - Lazy loading
- (WKWebView *)mjPicWkweb
{
    if (!_mjPicWkweb)
    {
        WKWebViewConfiguration *tempWebConfig = [[WKWebViewConfiguration alloc]init];
        
        WKPreferences *tempPreference = [WKPreferences new];
        tempPreference.javaScriptCanOpenWindowsAutomatically = YES;
        tempPreference.javaScriptEnabled = YES;
        tempWebConfig.preferences = tempPreference;
        
        tempWebConfig.allowsInlineMediaPlayback = YES;
        
        self.mjPicWkweb = [[WKWebView alloc]initWithFrame:self.view.bounds configuration:tempWebConfig];
        _mjPicWkweb.navigationDelegate = self;
        _mjPicWkweb.UIDelegate = self;
        _mjPicWkweb.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_mjPicWkweb];
        
        __weak __typeof(self)this = self;
        [self.mjPicWkweb mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.equalTo(this.view).with.insets(UIEdgeInsetsMake(MJ_SCREEN_STATUS_HEIGHT, 0, 0, 0));
            make.bottom.equalTo(this.mjPicToolbarView.mas_top);
        }];
    }
    return _mjPicWkweb;
}

- (UIView *)mjPicErrorView
{
    if (!_mjPicErrorView)
    {
        self.mjPicErrorView = [UIView new];
        _mjPicErrorView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_mjPicErrorView];
        
        __weak __typeof(self)this = self;
        [self.mjPicErrorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(this.view);
            make.bottom.equalTo(this.mjPicToolbarView.mas_top);
        }];
        
        UIImageView *tempImgView = [UIImageView new];
        tempImgView.backgroundColor = _mjPicErrorView.backgroundColor;
        [tempImgView sd_setImageWithURL:[NSURL URLWithString:@"https://medias.cloudm.com/static/mj/pic/empty_net@3x.png"]];
        [_mjPicErrorView addSubview:tempImgView];
        [tempImgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(this.mjPicErrorView);
            make.centerY.equalTo(this.mjPicErrorView).with.offset(-100);
            make.width.height.mas_equalTo(200);
        }];
        
        UIButton *tempBtn = [UIButton new];
        tempBtn.backgroundColor = [UIColor whiteColor];
        [tempBtn setTitleColor:[UIColor colorWithRed:235.0/255.0 green:32.0/255.0 blue:32.0/255.0 alpha:1] forState:UIControlStateNormal];
        [tempBtn setTitle:@"点击重试" forState:UIControlStateNormal];
        tempBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_mjPicErrorView addSubview:tempBtn];
        [tempBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(this.mjPicErrorView);
            make.top.equalTo(tempImgView.mas_bottom).with.offset(10);
            make.size.mas_equalTo(CGSizeMake(150, 50));
        }];
        [tempBtn addTarget:self action:@selector(wkwebReloadAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.view bringSubviewToFront:_mjPicErrorView];
    
    return _mjPicErrorView;
}

- (UIView *)mjPicToolbarView
{
    if (!_mjPicToolbarView)
    {
        self.mjPicToolbarView = [UIView new];
        _mjPicToolbarView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_mjPicToolbarView];
        
        __weak __typeof(self)this = self;
        [self.mjPicToolbarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(this.view);
            make.height.mas_equalTo(MJ_SCREEN_BOTTOM_SAFE_AREA + 49);
        }];
        
        NSArray *tempIconsArray = @[@"https://medias.cloudm.com/static/mj/pic/toolbar_home@3x.png",@"https://medias.cloudm.com/static/mj/pic/toolbar_back@3x.png",@"https://medias.cloudm.com/static/mj/pic/toolbar_next@3x.png",@"https://medias.cloudm.com/static/mj/pic/toolbar_reload@3x.png",@"https://medias.cloudm.com/static/mj/pic/toolbar_exit@3x.png"];
        NSArray *tempTitlesArray = @[@"首页",@"后退",@"前进",@"刷新",@"退出"];
        CGFloat tempWidth = [UIScreen mainScreen].bounds.size.width / tempTitlesArray.count;
        MAS_VIEW *preView;
        for (NSInteger i = 0; i < tempIconsArray.count; i++)
        {
            //CGFloat tempMultipli = (2.0*i+1)/tempIconsArray.count;
            
            UIButton *tempBtn = [UIButton new];
            tempBtn.backgroundColor = [UIColor whiteColor];
            [tempBtn setTitle:tempTitlesArray[i] forState:UIControlStateNormal];
            [tempBtn sd_setImageWithURL:[NSURL URLWithString:tempIconsArray[i]] forState:UIControlStateNormal];
            [tempBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            tempBtn.titleLabel.font = [UIFont systemFontOfSize:12];
//            [tempBtn setImagePositionWithType:JWImagePositionTypeTop spacing:0];
            tempBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -38, -25, 0);
            tempBtn.imageEdgeInsets = UIEdgeInsetsMake(-20, 0, 0, -20);
            tempBtn.tag = i + 2000;
            tempBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            tempBtn.adjustsImageWhenHighlighted = NO;
            [_mjPicToolbarView addSubview:tempBtn];
            [tempBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.bottom.equalTo(this.mjPicToolbarView);
                make.width.mas_equalTo(tempWidth);
                if (preView)
                {
                    make.left.equalTo(preView.mas_right);
                }
                else
                {
                    make.left.equalTo(this.mjPicToolbarView);
                }
            }];
            preView = tempBtn;
            
            [tempBtn addTarget:self action:@selector(toolbarItemDidSelected:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    return _mjPicToolbarView;
}

#pragma mark - Helper
- (void)configMJPicAFNetworkActivity
{
    // 开启网络监听
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    // 监听网了变更
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                //JW_OUTPUT_LOG(OutputLevelDebug, @"网络未知");
                break;
            case AFNetworkReachabilityStatusNotReachable:
            {
//                JWPopItem *tempOKItem = JWItemMake(@"我知道了", JWItemTypeHighlight, nil);
//                CHARGINGAlertView *tempAlert = [[CHARGINGAlertView alloc] initWithMessage:@"您的网络无法连接，请稍后重试" items:@[tempOKItem]];
//                [tempAlert show];
                
                UIAlertController *tempAlert = [UIAlertController alertControllerWithTitle:@"提示" message:@"您的网络无法连接，请稍后重试" preferredStyle:UIAlertControllerStyleAlert];
                [tempAlert addAction:[UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:tempAlert animated:YES completion:nil];
                self.mjPicErrorView.hidden = NO;
            }
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
            case AFNetworkReachabilityStatusReachableViaWWAN:
            {
                [self.mjPicWkweb reload];
                self.mjPicErrorView.hidden = YES;
            }
                break;
            default:
                break;
        }
    }];
}

- (void)configMJPicWkwebObserver
{
    [self.mjPicWkweb addObserver:self
                      forKeyPath:@"estimatedProgress"
                         options:NSKeyValueObservingOptionNew
                         context:nil];
}

- (void)configMJPicNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mjPicInterfaceRotate:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)loadMJPicWkwebUI
{
    self.mjPicErrorView.hidden = YES;
    
    NSURL *tempURL = [NSURL URLWithString:self.mjPicHomePageUrl];
    NSURLRequest *tempRequest = [[NSURLRequest alloc] initWithURL:tempURL];
    [self.mjPicWkweb loadRequest:tempRequest];
}

- (BOOL)mjPicConnectionAvaiable
{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    AFNetworkReachabilityStatus status =  [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
    BOOL isAvaiable = !(status == AFNetworkReachabilityStatusNotReachable);
    if (!isAvaiable)
    {
//        JWPopItem *tempOKItem = JWItemMake(@"我知道了", JWItemTypeHighlight, nil);
//        CHARGINGAlertView *tempAlert = [[CHARGINGAlertView alloc] initWithMessage:@"您的网络无法连接，请稍后重试" items:@[tempOKItem]];
//        [tempAlert show];
        UIAlertController *tempAlert = [UIAlertController alertControllerWithTitle:@"提示" message:@"您的网络无法连接，请稍后重试" preferredStyle:UIAlertControllerStyleAlert];
        [tempAlert addAction:[UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:tempAlert animated:YES completion:nil];
        
        self.mjPicErrorView.hidden = NO;
    }
    
    return isAvaiable;
}

- (void)mjPicCleanCacheAndCookies
{
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies])
    {
        [storage deleteCookie:cookie];
    }
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURLCache * cache = [NSURLCache sharedURLCache];
    [cache removeAllCachedResponses];
    [cache setDiskCapacity:0];
    [cache setMemoryCapacity:0];
    
    if ([[[UIDevice currentDevice]systemVersion]intValue ] > 8)
    {
        if (@available(iOS 9.0, *))
        {
            NSArray * types =@[WKWebsiteDataTypeMemoryCache,WKWebsiteDataTypeDiskCache]; // 9.0之后才有的
            NSSet *websiteDataTypes = [NSSet setWithArray:types];
            NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
            
            [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
                
            }];
        }
    }
    else
    {
        NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES) objectAtIndex:0];
        NSString *cookiesFolderPath = [libraryPath stringByAppendingString:@"/Cookies"];
        
        NSError *errors;
        [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&errors];
    }
    
    exit(0);
}

- (void)mjPicOpenOtherAppWithUIWebView:(WKWebView *)webView
{
    if ([webView.URL.absoluteString hasPrefix:@"https://itunes.apple"] ||
        [webView.URL.absoluteString hasPrefix:@"https://apps.apple"])
    {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:webView.URL options:@{} completionHandler:nil];
        } else {
            // Fallback on earlier versions
            [[UIApplication sharedApplication] openURL:webView.URL];
        }
    }
    else
    {
        if (![webView.URL.absoluteString hasPrefix:@"http"])
        {
            NSArray *whitelist = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"LSApplicationQueriesSchemes"];
            for (NSString * whiteName in whitelist)
            {
                NSString *rulesString = [NSString stringWithFormat:@"%@://",whiteName];
                if ([webView.URL.absoluteString hasPrefix:rulesString])
                {
                    if (@available(iOS 10.0, *)) {
                        [[UIApplication sharedApplication] openURL:webView.URL options:@{} completionHandler:nil];
                    } else {
                        // Fallback on earlier versions
                        [[UIApplication sharedApplication] openURL:webView.URL];
                    }
                }
            }
        }
    }
}

- (void)wkwebReloadAction:(id)sender
{
    if ([self mjPicConnectionAvaiable])
    {
        [self loadMJPicWkwebUI];
    }
}

- (void)toolbarItemDidSelected:(id)sender
{
    UIButton *tempBtn = (UIButton *)sender;
    switch (tempBtn.tag) {
        case 2000:
        {
            [self loadMJPicWkwebUI];
        }
            break;
        case 2001:
        {
            if ([self.mjPicWkweb canGoBack])
            {
                [self.mjPicWkweb goBack];
            }
        }
            break;
        case 2002:
        {
            if ([self.mjPicWkweb canGoForward])
            {
                [self.mjPicWkweb goForward];
            }
        }
            break;
        case 2003:
        {
            [self.mjPicWkweb reload];
        }
            break;
        case 2004:
        {
            __weak __typeof(self)this = self;
            UIAlertController *tempAlert = [UIAlertController alertControllerWithTitle:@"提示" message:@"您的网络无法连接，请稍后重试" preferredStyle:UIAlertControllerStyleAlert];
            [tempAlert addAction:[UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [this mjPicCleanCacheAndCookies];
            }]];
            [self presentViewController:tempAlert animated:YES completion:nil];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"])
    {
        if (self.mjPicWkweb.estimatedProgress == 1.0)
        {
            [SVProgressHUD dismiss];
        }
    }
}


#pragma mark - 屏幕旋转
-(BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)mjPicInterfaceRotate:(NSNotification *)notification
{
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait ||
        [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown)
    {
        self.mjPicToolbarView.hidden = NO;
        
        __weak __typeof(self)this = self;
        [self.mjPicWkweb mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(this.view).offset(MJ_SCREEN_STATUS_HEIGHT);
            make.left.right.equalTo(this.view);
            make.bottom.equalTo(this.mjPicToolbarView.mas_top);
        }];
        
    }
    else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ||
             [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight)
    {
        self.mjPicToolbarView.hidden = YES;
        
        __weak __typeof(self)this = self;
        [self.mjPicWkweb mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(this.view);
        }];
    }
}

#pragma mark -
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
   forNavigationAction:(WKNavigationAction *)navigationAction
        windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame || !navigationAction.targetFrame.isMainFrame)
    {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    
#if(0)
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView evaluateJavaScript:@"var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}" completionHandler:nil];
    }
#endif
    
    decisionHandler(WKNavigationActionPolicyAllow);
}


- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [SVProgressHUD showWithStatus:@"正在加载..."];
    [self mjPicOpenOtherAppWithUIWebView:webView];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
    if (!self.mjPicErrorView.hidden || error.code == -1002)
    {
        [SVProgressHUD dismiss];
    }
}

#pragma mark -
-(void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler
{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
    [self presentViewController:alertController animated:YES completion:nil];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
