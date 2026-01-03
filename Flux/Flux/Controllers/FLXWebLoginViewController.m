//
//  FLXWebLoginViewController.m
//  Flux
//
//  WebView 登录控制器实现 - 用于 Turnstile 验证码场景
//

#import "FLXWebLoginViewController.h"
#import <WebKit/WebKit.h>

@interface FLXWebLoginViewController () <WKNavigationDelegate,
                                         WKScriptMessageHandler>

@property(nonatomic, strong) WKWebView *webView;
@property(nonatomic, strong) UIProgressView *progressView;
@property(nonatomic, strong) UIButton *closeButton;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, assign) BOOL hasHandledLogin; // 防止重复处理

@end

@implementation FLXWebLoginViewController

- (instancetype)initWithServerURL:(NSString *)serverURL {
  self = [super init];
  if (self) {
    _serverURL = serverURL;
    _hasHandledLogin = NO;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
  [self loadLoginPage];
}

- (void)setupUI {
  self.view.backgroundColor = [UIColor systemBackgroundColor];

  // 顶部安全区域视图
  UIView *headerView = [[UIView alloc] init];
  headerView.backgroundColor = [UIColor systemBackgroundColor];
  headerView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:headerView];

  // 关闭按钮
  self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.closeButton setTitle:@"取消" forState:UIControlStateNormal];
  self.closeButton.titleLabel.font = [UIFont systemFontOfSize:17];
  self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.closeButton addTarget:self
                       action:@selector(closeButtonTapped)
             forControlEvents:UIControlEventTouchUpInside];
  [headerView addSubview:self.closeButton];

  // 标题
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.text = @"网页登录";
  self.titleLabel.font = [UIFont systemFontOfSize:17
                                           weight:UIFontWeightSemibold];
  self.titleLabel.textAlignment = NSTextAlignmentCenter;
  self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [headerView addSubview:self.titleLabel];

  // 进度条
  self.progressView = [[UIProgressView alloc]
      initWithProgressViewStyle:UIProgressViewStyleDefault];
  self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
  self.progressView.tintColor = [UIColor systemBlueColor];
  [self.view addSubview:self.progressView];

  // 配置 WKWebView
  WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
  WKUserContentController *userContentController =
      [[WKUserContentController alloc] init];

  // 添加 JavaScript 消息处理器
  [userContentController addScriptMessageHandler:self name:@"fluxLogin"];

  config.userContentController = userContentController;

  self.webView = [[WKWebView alloc] initWithFrame:CGRectZero
                                    configuration:config];
  self.webView.navigationDelegate = self;
  self.webView.translatesAutoresizingMaskIntoConstraints = NO;
  self.webView.allowsBackForwardNavigationGestures = YES;
  [self.view addSubview:self.webView];

  // 监听加载进度
  [self.webView addObserver:self
                 forKeyPath:@"estimatedProgress"
                    options:NSKeyValueObservingOptionNew
                    context:nil];

  // 监听 URL 变化
  [self.webView addObserver:self
                 forKeyPath:@"URL"
                    options:NSKeyValueObservingOptionNew
                    context:nil];

  // 布局约束
  [NSLayoutConstraint activateConstraints:@[
    // Header
    [headerView.topAnchor
        constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
    [headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [headerView.trailingAnchor
        constraintEqualToAnchor:self.view.trailingAnchor],
    [headerView.heightAnchor constraintEqualToConstant:44],

    // Close button
    [self.closeButton.leadingAnchor
        constraintEqualToAnchor:headerView.leadingAnchor
                       constant:16],
    [self.closeButton.centerYAnchor
        constraintEqualToAnchor:headerView.centerYAnchor],

    // Title
    [self.titleLabel.centerXAnchor
        constraintEqualToAnchor:headerView.centerXAnchor],
    [self.titleLabel.centerYAnchor
        constraintEqualToAnchor:headerView.centerYAnchor],

    // Progress view
    [self.progressView.topAnchor
        constraintEqualToAnchor:headerView.bottomAnchor],
    [self.progressView.leadingAnchor
        constraintEqualToAnchor:self.view.leadingAnchor],
    [self.progressView.trailingAnchor
        constraintEqualToAnchor:self.view.trailingAnchor],

    // WebView
    [self.webView.topAnchor
        constraintEqualToAnchor:self.progressView.bottomAnchor],
    [self.webView.leadingAnchor
        constraintEqualToAnchor:self.view.leadingAnchor],
    [self.webView.trailingAnchor
        constraintEqualToAnchor:self.view.trailingAnchor],
    [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

- (void)loadLoginPage {
  // 构建登录页面 URL
  NSString *urlString = self.serverURL;
  if (![urlString hasSuffix:@"/"]) {
    urlString = [urlString stringByAppendingString:@"/"];
  }

  NSURL *url = [NSURL URLWithString:urlString];
  if (url) {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
  }
}

- (void)closeButtonTapped {
  if ([self.delegate respondsToSelector:@selector(webLoginDidCancel)]) {
    [self.delegate webLoginDidCancel];
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"estimatedProgress"]) {
    float progress = self.webView.estimatedProgress;
    [self.progressView setProgress:progress animated:YES];

    if (progress >= 1.0) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC),
                     dispatch_get_main_queue(), ^{
                       self.progressView.hidden = YES;
                     });
    } else {
      self.progressView.hidden = NO;
    }
  } else if ([keyPath isEqualToString:@"URL"]) {
    // URL 变化时检查是否跳转到了 dashboard
    NSURL *currentURL = self.webView.URL;
    if (currentURL) {
      NSString *path = currentURL.path;
      // 如果跳转到 dashboard、forwards 等页面，说明登录成功
      if ([path containsString:@"dashboard"] ||
          [path containsString:@"forwards"] ||
          [path containsString:@"tunnels"] || [path containsString:@"nodes"] ||
          [path containsString:@"users"] || [path containsString:@"profile"]) {
        [self checkAndExtractToken];
      }
    }
  }
}

- (void)dealloc {
  [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
  [self.webView removeObserver:self forKeyPath:@"URL"];
  [self.webView.configuration.userContentController
      removeScriptMessageHandlerForName:@"fluxLogin"];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView
    didFinishNavigation:(WKNavigation *)navigation {
  // 页面加载完成后检查 token
  [self checkAndExtractToken];
}

#pragma mark - Token 检测

- (void)checkAndExtractToken {
  // 防止重复处理
  if (self.hasHandledLogin) {
    return;
  }

  // 从 localStorage 读取登录信息
  NSString *checkScript =
      @"(function() {"
      @"  var token = localStorage.getItem('token');"
      @"  if (token && token.length > 0) {"
      @"    var roleId = localStorage.getItem('role_id') || '1';"
      @"    var name = localStorage.getItem('name') || '';"
      @"    return { hasToken: true, token: token, roleId: parseInt(roleId), "
      @"name: name };"
      @"  }"
      @"  return { hasToken: false };"
      @"})();";

  [self.webView evaluateJavaScript:checkScript
                 completionHandler:^(id result, NSError *error) {
                   if (self.hasHandledLogin) {
                     return;
                   }

                   if (!error && [result isKindOfClass:[NSDictionary class]]) {
                     NSDictionary *data = (NSDictionary *)result;
                     if ([data[@"hasToken"] boolValue]) {
                       NSString *token = data[@"token"];
                       // 确保 token 不为空
                       if (token && token.length > 0) {
                         NSInteger roleId = [data[@"roleId"] integerValue];
                         NSString *name = data[@"name"] ?: @"";

                         self.hasHandledLogin = YES;
                         [self handleLoginSuccessWithToken:token
                                                    roleId:roleId
                                                  userName:name
                                     requirePasswordChange:NO];
                       }
                     }
                   }
                 }];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
  if ([message.name isEqualToString:@"fluxLogin"]) {
    if (self.hasHandledLogin) {
      return;
    }

    NSDictionary *body = message.body;
    if ([body isKindOfClass:[NSDictionary class]]) {
      NSString *token = body[@"token"];
      if (token && token.length > 0) {
        NSInteger roleId = [body[@"roleId"] integerValue];
        NSString *name = body[@"name"] ?: @"";
        BOOL requirePasswordChange = [body[@"requirePasswordChange"] boolValue];

        self.hasHandledLogin = YES;
        [self handleLoginSuccessWithToken:token
                                   roleId:roleId
                                 userName:name
                    requirePasswordChange:requirePasswordChange];
      }
    }
  }
}

- (void)handleLoginSuccessWithToken:(NSString *)token
                             roleId:(NSInteger)roleId
                           userName:(NSString *)name
              requirePasswordChange:(BOOL)requirePasswordChange {
  // 在主线程执行
  dispatch_async(dispatch_get_main_queue(), ^{
    // 通知代理登录成功
    if ([self.delegate
            respondsToSelector:@selector
            (webLoginDidSucceedWithToken:
                                  roleId:userName:requirePasswordChange:)]) {
      [self.delegate webLoginDidSucceedWithToken:token
                                          roleId:roleId
                                        userName:name
                           requirePasswordChange:requirePasswordChange];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
  });
}

@end
