//
//  FLXLoginViewController.m
//  Flux
//
//  登录视图控制器实现
//

#import "FLXLoginViewController.h"
#import "FLXAPIClient.h"
#import "FLXMainTabBarController.h"
#import "FLXWebLoginViewController.h"

@interface FLXLoginViewController () <UITextFieldDelegate, FLXWebLoginDelegate>

@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *subtitleLabel;
@property(nonatomic, strong) UITextField *serverTextField;
@property(nonatomic, strong) UITextField *usernameTextField;
@property(nonatomic, strong) UITextField *passwordTextField;
@property(nonatomic, strong) UIButton *loginButton;
@property(nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property(nonatomic, strong) UILabel *versionLabel;

@end

@implementation FLXLoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
  [self setupConstraints];
  [self loadSavedServer];
}

- (void)setupUI {
  self.view.backgroundColor = [UIColor systemBackgroundColor];

  // 滚动视图
  self.scrollView = [[UIScrollView alloc] init];
  self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.scrollView.keyboardDismissMode =
      UIScrollViewKeyboardDismissModeInteractive;
  [self.view addSubview:self.scrollView];

  // 内容视图
  self.contentView = [[UIView alloc] init];
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.scrollView addSubview:self.contentView];

  // 标题
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.text = @"Flux Panel";
  self.titleLabel.font = [UIFont systemFontOfSize:32 weight:UIFontWeightBold];
  self.titleLabel.textAlignment = NSTextAlignmentCenter;
  self.titleLabel.textColor = [UIColor labelColor];
  self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView addSubview:self.titleLabel];

  // 副标题
  self.subtitleLabel = [[UILabel alloc] init];
  self.subtitleLabel.text = @"请登录您的账号";
  self.subtitleLabel.font = [UIFont systemFontOfSize:16
                                              weight:UIFontWeightRegular];
  self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
  self.subtitleLabel.textColor = [UIColor secondaryLabelColor];
  self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView addSubview:self.subtitleLabel];

  // 服务器地址输入框
  self.serverTextField = [self createTextFieldWithPlaceholder:
                                   @"服务器地址 (如: https://panel.example.com)"
                                                     isSecure:NO];
  self.serverTextField.keyboardType = UIKeyboardTypeURL;
  self.serverTextField.autocapitalizationType =
      UITextAutocapitalizationTypeNone;
  [self.contentView addSubview:self.serverTextField];

  // 用户名输入框
  self.usernameTextField = [self createTextFieldWithPlaceholder:@"用户名"
                                                       isSecure:NO];
  self.usernameTextField.autocapitalizationType =
      UITextAutocapitalizationTypeNone;
  [self.contentView addSubview:self.usernameTextField];

  // 密码输入框
  self.passwordTextField = [self createTextFieldWithPlaceholder:@"密码"
                                                       isSecure:YES];
  [self.contentView addSubview:self.passwordTextField];

  // 登录按钮
  self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.loginButton setTitle:@"登录" forState:UIControlStateNormal];
  self.loginButton.titleLabel.font =
      [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
  self.loginButton.backgroundColor = [UIColor systemBlueColor];
  [self.loginButton setTitleColor:[UIColor whiteColor]
                         forState:UIControlStateNormal];
  self.loginButton.layer.cornerRadius = 12;
  self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.loginButton addTarget:self
                       action:@selector(loginButtonTapped)
             forControlEvents:UIControlEventTouchUpInside];
  [self.contentView addSubview:self.loginButton];

  // 加载指示器
  self.activityIndicator = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
  self.activityIndicator.color = [UIColor whiteColor];
  self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
  self.activityIndicator.hidesWhenStopped = YES;
  [self.loginButton addSubview:self.activityIndicator];

  // 版本标签
  self.versionLabel = [[UILabel alloc] init];
  self.versionLabel.text = @"Flux Panel iOS v1.5.1";
  self.versionLabel.font = [UIFont systemFontOfSize:12
                                             weight:UIFontWeightRegular];
  self.versionLabel.textAlignment = NSTextAlignmentCenter;
  self.versionLabel.textColor = [UIColor tertiaryLabelColor];
  self.versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.versionLabel];

  // 添加点击手势隐藏键盘
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(dismissKeyboard)];
  [self.view addGestureRecognizer:tapGesture];
}

- (UITextField *)createTextFieldWithPlaceholder:(NSString *)placeholder
                                       isSecure:(BOOL)isSecure {
  UITextField *textField = [[UITextField alloc] init];
  textField.placeholder = placeholder;
  textField.borderStyle = UITextBorderStyleNone;
  textField.backgroundColor = [UIColor secondarySystemBackgroundColor];
  textField.layer.cornerRadius = 12;
  textField.font = [UIFont systemFontOfSize:16];
  textField.secureTextEntry = isSecure;
  textField.autocorrectionType = UITextAutocorrectionTypeNo;
  textField.translatesAutoresizingMaskIntoConstraints = NO;
  textField.delegate = self;
  textField.returnKeyType = UIReturnKeyNext;

  // 添加左边距
  UIView *leftPaddingView =
      [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 50)];
  textField.leftView = leftPaddingView;
  textField.leftViewMode = UITextFieldViewModeAlways;

  // 添加右边距
  UIView *rightPaddingView =
      [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 50)];
  textField.rightView = rightPaddingView;
  textField.rightViewMode = UITextFieldViewModeAlways;

  return textField;
}

- (void)setupConstraints {
  [NSLayoutConstraint activateConstraints:@[
    // 滚动视图
    [self.scrollView.topAnchor
        constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
    [self.scrollView.leadingAnchor
        constraintEqualToAnchor:self.view.leadingAnchor],
    [self.scrollView.trailingAnchor
        constraintEqualToAnchor:self.view.trailingAnchor],
    [self.scrollView.bottomAnchor
        constraintEqualToAnchor:self.view.bottomAnchor],

    // 内容视图
    [self.contentView.topAnchor
        constraintEqualToAnchor:self.scrollView.topAnchor],
    [self.contentView.leadingAnchor
        constraintEqualToAnchor:self.scrollView.leadingAnchor],
    [self.contentView.trailingAnchor
        constraintEqualToAnchor:self.scrollView.trailingAnchor],
    [self.contentView.bottomAnchor
        constraintEqualToAnchor:self.scrollView.bottomAnchor],
    [self.contentView.widthAnchor
        constraintEqualToAnchor:self.scrollView.widthAnchor],

    // 标题
    [self.titleLabel.topAnchor
        constraintEqualToAnchor:self.contentView.topAnchor
                       constant:60],
    [self.titleLabel.leadingAnchor
        constraintEqualToAnchor:self.contentView.leadingAnchor
                       constant:24],
    [self.titleLabel.trailingAnchor
        constraintEqualToAnchor:self.contentView.trailingAnchor
                       constant:-24],

    // 副标题
    [self.subtitleLabel.topAnchor
        constraintEqualToAnchor:self.titleLabel.bottomAnchor
                       constant:8],
    [self.subtitleLabel.leadingAnchor
        constraintEqualToAnchor:self.contentView.leadingAnchor
                       constant:24],
    [self.subtitleLabel.trailingAnchor
        constraintEqualToAnchor:self.contentView.trailingAnchor
                       constant:-24],

    // 服务器地址
    [self.serverTextField.topAnchor
        constraintEqualToAnchor:self.subtitleLabel.bottomAnchor
                       constant:40],
    [self.serverTextField.leadingAnchor
        constraintEqualToAnchor:self.contentView.leadingAnchor
                       constant:24],
    [self.serverTextField.trailingAnchor
        constraintEqualToAnchor:self.contentView.trailingAnchor
                       constant:-24],
    [self.serverTextField.heightAnchor constraintEqualToConstant:50],

    // 用户名
    [self.usernameTextField.topAnchor
        constraintEqualToAnchor:self.serverTextField.bottomAnchor
                       constant:16],
    [self.usernameTextField.leadingAnchor
        constraintEqualToAnchor:self.contentView.leadingAnchor
                       constant:24],
    [self.usernameTextField.trailingAnchor
        constraintEqualToAnchor:self.contentView.trailingAnchor
                       constant:-24],
    [self.usernameTextField.heightAnchor constraintEqualToConstant:50],

    // 密码
    [self.passwordTextField.topAnchor
        constraintEqualToAnchor:self.usernameTextField.bottomAnchor
                       constant:16],
    [self.passwordTextField.leadingAnchor
        constraintEqualToAnchor:self.contentView.leadingAnchor
                       constant:24],
    [self.passwordTextField.trailingAnchor
        constraintEqualToAnchor:self.contentView.trailingAnchor
                       constant:-24],
    [self.passwordTextField.heightAnchor constraintEqualToConstant:50],

    // 登录按钮
    [self.loginButton.topAnchor
        constraintEqualToAnchor:self.passwordTextField.bottomAnchor
                       constant:32],
    [self.loginButton.leadingAnchor
        constraintEqualToAnchor:self.contentView.leadingAnchor
                       constant:24],
    [self.loginButton.trailingAnchor
        constraintEqualToAnchor:self.contentView.trailingAnchor
                       constant:-24],
    [self.loginButton.heightAnchor constraintEqualToConstant:50],
    [self.loginButton.bottomAnchor
        constraintEqualToAnchor:self.contentView.bottomAnchor
                       constant:-40],

    // 加载指示器
    [self.activityIndicator.centerYAnchor
        constraintEqualToAnchor:self.loginButton.centerYAnchor],
    [self.activityIndicator.trailingAnchor
        constraintEqualToAnchor:self.loginButton.trailingAnchor
                       constant:-20],

    // 版本标签
    [self.versionLabel.bottomAnchor
        constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor
                       constant:-16],
    [self.versionLabel.centerXAnchor
        constraintEqualToAnchor:self.view.centerXAnchor],
  ]];
}

- (void)loadSavedServer {
  NSString *savedURL =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"serverURL"];
  if (savedURL) {
    self.serverTextField.text = savedURL;
  }
}

- (void)dismissKeyboard {
  [self.view endEditing:YES];
}

#pragma mark - Actions

- (void)loginButtonTapped {
  [self dismissKeyboard];

  NSString *server = [self.serverTextField.text
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *username = [self.usernameTextField.text
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *password = self.passwordTextField.text;

  // 验证输入
  if (server.length == 0) {
    [self showAlertWithTitle:@"错误" message:@"请输入服务器地址"];
    return;
  }

  if (username.length == 0) {
    [self showAlertWithTitle:@"错误" message:@"请输入用户名"];
    return;
  }

  if (password.length < 6) {
    [self showAlertWithTitle:@"错误" message:@"密码长度至少6位"];
    return;
  }

  // 设置服务器地址
  [[FLXAPIClient sharedClient] setBaseURL:server];

  // 开始加载
  [self setLoading:YES];

  // 先检查验证码
  [[FLXAPIClient sharedClient]
      checkCaptchaWithCompletion:^(NSDictionary *response, NSError *error) {
        if (error) {
          [self setLoading:NO];
          [self showAlertWithTitle:@"错误"
                           message:@"网络错误，请检查服务器地址"];
          return;
        }

        NSInteger code = [response[@"code"] integerValue];
        if (code != 0) {
          [self setLoading:NO];
          [self showAlertWithTitle:@"错误"
                           message:response[@"msg"] ?: @"检查验证码状态失败"];
          return;
        }

        // 检查是否需要验证码
        // 新的返回格式可能是对象 { enabled: 1, type: "TURNSTILE", ... }
        // 或者数字 0/1
        BOOL captchaRequired = NO;
        if ([response[@"data"] isKindOfClass:[NSDictionary class]]) {
          NSDictionary *data = response[@"data"];
          captchaRequired = [data[@"enabled"] integerValue] != 0;
        } else {
          captchaRequired = [response[@"data"] integerValue] != 0;
        }

        if (captchaRequired) {
          [self setLoading:NO];
          // 需要验证码，打开 WebView 登录页面
          [self showWebLogin];
          return;
        }

        // 执行登录
        [self performLoginWithUsername:username password:password];
      }];
}

- (void)performLoginWithUsername:(NSString *)username
                        password:(NSString *)password {
  [[FLXAPIClient sharedClient]
      loginWithUsername:username
               password:password
              captchaId:nil
             completion:^(NSDictionary *response, NSError *error) {
               [self setLoading:NO];

               if (error) {
                 [self showAlertWithTitle:@"错误"
                                  message:@"网络错误，请稍后重试"];
                 return;
               }

               NSInteger code = [response[@"code"] integerValue];
               if (code != 0) {
                 [self showAlertWithTitle:@"登录失败"
                                  message:response[@"msg"]
                                              ?: @"用户名或密码错误"];
                 return;
               }

               NSDictionary *data = response[@"data"];
               NSString *token = data[@"token"];
               NSInteger roleId = [data[@"role_id"] integerValue];
               NSString *name = data[@"name"];
               BOOL requirePasswordChange =
                   [data[@"requirePasswordChange"] boolValue];

               // 保存登录信息
               [[FLXAPIClient sharedClient] setAuthToken:token];
               [[NSUserDefaults standardUserDefaults] setInteger:roleId
                                                          forKey:@"roleId"];
               [[NSUserDefaults standardUserDefaults] setObject:name
                                                         forKey:@"userName"];
               [[NSUserDefaults standardUserDefaults] setBool:(roleId == 0)
                                                       forKey:@"isAdmin"];
               [[NSUserDefaults standardUserDefaults] synchronize];

               // 检查是否需要修改密码
               if (requirePasswordChange) {
                 [self showAlertWithTitle:@"提示"
                                  message:@"检测到默认密码，请在网页版修改密码"
                                          @"后重新登录"];
                 return;
               }

               // 跳转到主界面
               [self navigateToMainScreen];
             }];
}

- (void)navigateToMainScreen {
  FLXMainTabBarController *tabBarController =
      [[FLXMainTabBarController alloc] init];
  tabBarController.modalPresentationStyle = UIModalPresentationFullScreen;

  // 添加动画效果
  UIWindow *window = self.view.window;
  [UIView transitionWithView:window
                    duration:0.3
                     options:UIViewAnimationOptionTransitionCrossDissolve
                  animations:^{
                    window.rootViewController = tabBarController;
                  }
                  completion:nil];
}

- (void)setLoading:(BOOL)loading {
  self.loginButton.enabled = !loading;
  self.serverTextField.enabled = !loading;
  self.usernameTextField.enabled = !loading;
  self.passwordTextField.enabled = !loading;

  if (loading) {
    [self.activityIndicator startAnimating];
    [self.loginButton setTitle:@"登录中..." forState:UIControlStateNormal];
  } else {
    [self.activityIndicator stopAnimating];
    [self.loginButton setTitle:@"登录" forState:UIControlStateNormal];
  }
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                            style:UIAlertActionStyleDefault
                                          handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - WebView 登录

- (void)showWebLogin {
  NSString *server = [self.serverTextField.text
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

  FLXWebLoginViewController *webLoginVC =
      [[FLXWebLoginViewController alloc] initWithServerURL:server];
  webLoginVC.delegate = self;
  webLoginVC.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:webLoginVC animated:YES completion:nil];
}

#pragma mark - FLXWebLoginDelegate

- (void)webLoginDidSucceedWithToken:(NSString *)token
                             roleId:(NSInteger)roleId
                           userName:(NSString *)userName
              requirePasswordChange:(BOOL)requirePasswordChange {
  // 保存登录信息
  [[FLXAPIClient sharedClient] setAuthToken:token];
  [[NSUserDefaults standardUserDefaults] setInteger:roleId forKey:@"roleId"];
  [[NSUserDefaults standardUserDefaults] setObject:userName forKey:@"userName"];
  [[NSUserDefaults standardUserDefaults] setBool:(roleId == 0)
                                          forKey:@"isAdmin"];
  [[NSUserDefaults standardUserDefaults] synchronize];

  // 检查是否需要修改密码
  if (requirePasswordChange) {
    [self showAlertWithTitle:@"提示"
                     message:@"检测到默认密码，请在网页版修改密码后重新登录"];
    return;
  }

  // 跳转到主界面
  [self navigateToMainScreen];
}

- (void)webLoginDidCancel {
  // 用户取消了 WebView 登录，无需额外处理
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == self.serverTextField) {
    [self.usernameTextField becomeFirstResponder];
  } else if (textField == self.usernameTextField) {
    [self.passwordTextField becomeFirstResponder];
  } else if (textField == self.passwordTextField) {
    [self loginButtonTapped];
  }
  return YES;
}

@end
