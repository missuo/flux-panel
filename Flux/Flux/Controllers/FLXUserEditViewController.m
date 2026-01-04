//
//  FLXUserEditViewController.m
//  Flux
//
//  用户编辑视图控制器实现 (管理员)
//

#import "FLXUserEditViewController.h"
#import "FLXAPIClient.h"
#import "FLXModels.h"

@interface FLXUserEditViewController () <
    UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong, nullable) FLXUser *user;
@property(nonatomic, assign) BOOL isEditing;

// 表单字段
@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, assign) NSInteger flow;          // GB
@property(nonatomic, assign) NSInteger num;           // 转发配额
@property(nonatomic, assign) NSInteger expDays;       // 过期天数
@property(nonatomic, assign) NSInteger flowResetTime; // 流量重置日期 (每月几号)
@property(nonatomic, assign) NSInteger status;        // 状态 (0: 禁用, 1: 启用)

// UI 控件
@property(nonatomic, strong) UITextField *usernameTextField;
@property(nonatomic, strong) UITextField *passwordTextField;
@property(nonatomic, strong) UITextField *flowTextField;
@property(nonatomic, strong) UITextField *numTextField;
@property(nonatomic, strong) UITextField *expDaysTextField;
@property(nonatomic, strong) UITextField *flowResetTextField;
@property(nonatomic, strong) UISwitch *unlimitedFlowSwitch;
@property(nonatomic, strong) UISwitch *unlimitedNumSwitch;
@property(nonatomic, strong) UISwitch *permanentSwitch;
@property(nonatomic, strong) UISwitch *statusSwitch;

@property(nonatomic, assign) BOOL isSaving;

@end

@implementation FLXUserEditViewController

- (instancetype)init {
  self = [super init];
  if (self) {
    _isEditing = NO;
    _username = @"";
    _password = @"";
    _flow = 100;
    _num = 10;
    _expDays = 30;
    _flowResetTime = 1;
    _status = 1;
  }
  return self;
}

- (instancetype)initWithUser:(FLXUser *)user {
  self = [super init];
  if (self) {
    _user = user;
    _isEditing = YES;
    _username = user.username ?: @"";
    _password = @"";
    _flow = user.flow;
    _num = user.num;
    _flowResetTime = user.flowResetTime;
    _status = user.status;

    // 计算过期天数
    long long expTimeMs = 0;
    if (user.expTime) {
      if ([user.expTime isKindOfClass:[NSString class]] &&
          [(NSString *)user.expTime length] > 0) {
        expTimeMs = [user.expTime longLongValue];
      } else if ([user.expTime isKindOfClass:[NSNumber class]]) {
        expTimeMs = [user.expTime longLongValue];
      }
    }

    if (expTimeMs > 0) {
      NSTimeInterval expSec = expTimeMs / 1000.0;
      NSDate *expDate = [NSDate dateWithTimeIntervalSince1970:expSec];
      NSTimeInterval diff = [expDate timeIntervalSinceDate:[NSDate date]];
      if (diff > 0) {
        _expDays = (NSInteger)(diff / 86400.0);
        if (_expDays == 0)
          _expDays = 1;
      } else {
        _expDays = 0; // 已过期或马上过期，默认为0? 或者设置为1防止变成了无限?
        // 如果已过期，用户可能想延期。
        // 如果设为0，界面上会显示"永久"。这可能产生误导。
        // 最好设为 30 (默认值) 让用户去改?
        _expDays = 30;
      }
    } else {
      _expDays = 0; // 永久
    }
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
}

- (void)setupUI {
  self.title = self.isEditing ? @"编辑用户" : @"添加用户";
  self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

  // 取消按钮
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                           target:self
                           action:@selector(cancelButtonTapped)];

  // 保存按钮
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                           target:self
                           action:@selector(saveButtonTapped)];

  // 表格视图
  self.tableView =
      [[UITableView alloc] initWithFrame:CGRectZero
                                   style:UITableViewStyleInsetGrouped];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.keyboardDismissMode =
      UIScrollViewKeyboardDismissModeInteractive;
  [self.view addSubview:self.tableView];

  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.tableView.leadingAnchor
        constraintEqualToAnchor:self.view.leadingAnchor],
    [self.tableView.trailingAnchor
        constraintEqualToAnchor:self.view.trailingAnchor],
    [self.tableView.bottomAnchor
        constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  // 点击空白处隐藏键盘
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(dismissKeyboard)];
  tap.cancelsTouchesInView = NO;
  [self.tableView addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
  [self.view endEditing:YES];
}

- (void)cancelButtonTapped {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveButtonTapped {
  [self dismissKeyboard];

  // 收集表单数据
  self.username = [self.usernameTextField.text
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  self.password = self.passwordTextField.text ?: @"";

  // 验证
  if (self.username.length < 2) {
    [self showAlertWithTitle:@"错误" message:@"用户名长度至少2个字符"];
    return;
  }

  if (!self.isEditing && self.password.length < 6) {
    [self showAlertWithTitle:@"错误" message:@"密码长度至少6个字符"];
    return;
  }

  // 处理无限流量
  NSInteger finalFlow = self.unlimitedFlowSwitch.isOn
                            ? 99999
                            : [self.flowTextField.text integerValue];
  if (finalFlow <= 0 && !self.unlimitedFlowSwitch.isOn) {
    [self showAlertWithTitle:@"错误" message:@"请输入有效的流量配额"];
    return;
  }

  // 处理无限转发
  NSInteger finalNum = self.unlimitedNumSwitch.isOn
                           ? 99999
                           : [self.numTextField.text integerValue];
  if (finalNum <= 0 && !self.unlimitedNumSwitch.isOn) {
    [self showAlertWithTitle:@"错误" message:@"请输入有效的转发配额"];
    return;
  }

  // 处理过期时间 (转换为时间戳)
  NSInteger expTime = 0;
  if (!self.permanentSwitch.isOn) {
    NSInteger expDays = [self.expDaysTextField.text integerValue];
    if (expDays <= 0) {
      [self showAlertWithTitle:@"错误" message:@"请输入有效的有效期天数"];
      return;
    }
    // 计算过期时间戳 (毫秒)
    NSDate *expDate =
        [[NSDate date] dateByAddingTimeInterval:expDays * 24 * 60 * 60];
    expTime = (NSInteger)([expDate timeIntervalSince1970] * 1000);
  }

  // 流量重置日期
  NSInteger flowResetTime = [self.flowResetTextField.text integerValue];
  if (flowResetTime < 0 || flowResetTime > 28) {
    flowResetTime = 1;
  }

  if (self.isSaving)
    return;
  self.isSaving = YES;
  self.navigationItem.rightBarButtonItem.enabled = NO;

  if (self.isEditing) {
    // 更新用户
    [[FLXAPIClient sharedClient]
        updateUserWithId:self.user.userId
                username:self.username
                password:self.password.length > 0 ? self.password : nil
                    flow:finalFlow
                     num:finalNum
                 expTime:expTime > 0
                             ? [NSString stringWithFormat:@"%ld", (long)expTime]
                             : nil
           flowResetTime:flowResetTime
                  status:self.status
              completion:^(NSDictionary *response, NSError *error) {
                self.isSaving = NO;
                self.navigationItem.rightBarButtonItem.enabled = YES;

                if (!error && [response[@"code"] integerValue] == 0) {
                  [self dismissViewControllerAnimated:YES
                                           completion:^{
                                             if (self.completionHandler) {
                                               self.completionHandler();
                                             }
                                           }];
                } else {
                  [self showAlertWithTitle:@"错误"
                                   message:response[@"msg"] ?: @"更新失败"];
                }
              }];
  } else {
    // 创建用户
    [[FLXAPIClient sharedClient]
        createUserWithUsername:self.username
                      password:self.password
                          flow:finalFlow
                           num:finalNum
                       expTime:expTime > 0
                                   ? [NSString
                                         stringWithFormat:@"%ld", (long)expTime]
                                   : nil
                 flowResetTime:flowResetTime
                        status:self.status
                    completion:^(NSDictionary *response, NSError *error) {
                      self.isSaving = NO;
                      self.navigationItem.rightBarButtonItem.enabled = YES;

                      if (!error && [response[@"code"] integerValue] == 0) {
                        [self dismissViewControllerAnimated:YES
                                                 completion:^{
                                                   if (self.completionHandler) {
                                                     self.completionHandler();
                                                   }
                                                 }];
                      } else {
                        [self
                            showAlertWithTitle:@"错误"
                                       message:response[@"msg"] ?: @"创建失败"];
                      }
                    }];
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 3;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  switch (section) {
  case 0:
    return 3; // 用户名、密码、状态
  case 1:
    return 4; // 流量配额、无限流量、转发配额、无限转发
  case 2:
    return 3; // 有效期、永久有效、流量重置日期
  default:
    return 0;
  }
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  switch (section) {
  case 0:
    return @"账户信息";
  case 1:
    return @"配额设置";
  case 2:
    return @"有效期设置";
  default:
    return nil;
  }
}

- (NSString *)tableView:(UITableView *)tableView
    titleForFooterInSection:(NSInteger)section {
  switch (section) {
  case 1:
    return @"99999 表示无限制";
  case 2:
    return @"流量重置日为每月固定日期重置用户流量，0 表示不重置";
  default:
    return nil;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                             reuseIdentifier:nil];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  if (indexPath.section == 0) {
    if (indexPath.row == 0) {
      // 用户名
      cell.textLabel.text = @"用户名";

      if (!self.usernameTextField) {
        self.usernameTextField =
            [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        self.usernameTextField.placeholder = @"请输入用户名";
        self.usernameTextField.textAlignment = NSTextAlignmentRight;
        self.usernameTextField.delegate = self;
        self.usernameTextField.autocapitalizationType =
            UITextAutocapitalizationTypeNone;
        self.usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.usernameTextField.returnKeyType = UIReturnKeyNext;
        self.usernameTextField.text = self.username;
      }
      cell.accessoryView = self.usernameTextField;

    } else if (indexPath.row == 1) {
      // 密码
      cell.textLabel.text = self.isEditing ? @"新密码" : @"密码";

      if (!self.passwordTextField) {
        self.passwordTextField =
            [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        self.passwordTextField.placeholder =
            self.isEditing ? @"留空不修改" : @"请输入密码";
        self.passwordTextField.textAlignment = NSTextAlignmentRight;
        self.passwordTextField.delegate = self;
        self.passwordTextField.secureTextEntry = YES;
        self.passwordTextField.autocapitalizationType =
            UITextAutocapitalizationTypeNone;
        self.passwordTextField.returnKeyType = UIReturnKeyNext;
      }
      cell.accessoryView = self.passwordTextField;
    } else {
      // 状态
      cell.textLabel.text = @"启用账户";

      if (!self.statusSwitch) {
        self.statusSwitch = [[UISwitch alloc] init];
        self.statusSwitch.on = (self.status == 1);
        [self.statusSwitch addTarget:self
                              action:@selector(statusSwitchChanged:)
                    forControlEvents:UIControlEventValueChanged];
      }
      cell.accessoryView = self.statusSwitch;
    }
  } else if (indexPath.section == 1) {
    if (indexPath.row == 0) {
      // 流量配额
      cell.textLabel.text = @"流量 (GB)";

      if (!self.flowTextField) {
        self.flowTextField =
            [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
        self.flowTextField.placeholder = @"100";
        self.flowTextField.textAlignment = NSTextAlignmentRight;
        self.flowTextField.delegate = self;
        self.flowTextField.keyboardType = UIKeyboardTypeNumberPad;
        self.flowTextField.text =
            self.flow == 99999
                ? @""
                : [NSString stringWithFormat:@"%ld", (long)self.flow];
      }
      cell.accessoryView = self.flowTextField;

    } else if (indexPath.row == 1) {
      // 无限流量开关
      cell.textLabel.text = @"无限流量";

      if (!self.unlimitedFlowSwitch) {
        self.unlimitedFlowSwitch = [[UISwitch alloc] init];
        self.unlimitedFlowSwitch.on = (self.flow == 99999);
        [self.unlimitedFlowSwitch
                   addTarget:self
                      action:@selector(unlimitedFlowSwitchChanged:)
            forControlEvents:UIControlEventValueChanged];
      }
      cell.accessoryView = self.unlimitedFlowSwitch;

    } else if (indexPath.row == 2) {
      // 转发配额
      cell.textLabel.text = @"转发配额";

      if (!self.numTextField) {
        self.numTextField =
            [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
        self.numTextField.placeholder = @"10";
        self.numTextField.textAlignment = NSTextAlignmentRight;
        self.numTextField.delegate = self;
        self.numTextField.keyboardType = UIKeyboardTypeNumberPad;
        self.numTextField.text =
            self.num == 99999
                ? @""
                : [NSString stringWithFormat:@"%ld", (long)self.num];
      }
      cell.accessoryView = self.numTextField;

    } else {
      // 无限转发开关
      cell.textLabel.text = @"无限转发";

      if (!self.unlimitedNumSwitch) {
        self.unlimitedNumSwitch = [[UISwitch alloc] init];
        self.unlimitedNumSwitch.on = (self.num == 99999);
        [self.unlimitedNumSwitch addTarget:self
                                    action:@selector(unlimitedNumSwitchChanged:)
                          forControlEvents:UIControlEventValueChanged];
      }
      cell.accessoryView = self.unlimitedNumSwitch;
    }
  } else if (indexPath.section == 2) {
    if (indexPath.row == 0) {
      // 有效期天数
      cell.textLabel.text = @"有效期 (天)";

      if (!self.expDaysTextField) {
        self.expDaysTextField =
            [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
        self.expDaysTextField.placeholder = @"30";
        self.expDaysTextField.textAlignment = NSTextAlignmentRight;
        self.expDaysTextField.delegate = self;
        self.expDaysTextField.keyboardType = UIKeyboardTypeNumberPad;
        self.expDaysTextField.text =
            self.expDays > 0
                ? [NSString stringWithFormat:@"%ld", (long)self.expDays]
                : @"30";
      }
      cell.accessoryView = self.expDaysTextField;

    } else if (indexPath.row == 1) {
      // 永久有效开关
      cell.textLabel.text = @"永久有效";

      if (!self.permanentSwitch) {
        self.permanentSwitch = [[UISwitch alloc] init];
        self.permanentSwitch.on = (self.expDays == 0);
        [self.permanentSwitch addTarget:self
                                 action:@selector(permanentSwitchChanged:)
                       forControlEvents:UIControlEventValueChanged];
      }
      cell.accessoryView = self.permanentSwitch;

    } else {
      // 流量重置日期
      cell.textLabel.text = @"流量重置日";

      if (!self.flowResetTextField) {
        self.flowResetTextField =
            [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
        self.flowResetTextField.placeholder = @"1";
        self.flowResetTextField.textAlignment = NSTextAlignmentRight;
        self.flowResetTextField.delegate = self;
        self.flowResetTextField.keyboardType = UIKeyboardTypeNumberPad;
        self.flowResetTextField.text =
            [NSString stringWithFormat:@"%ld", (long)self.flowResetTime];
      }
      cell.accessoryView = self.flowResetTextField;
    }
  }

  return cell;
}

#pragma mark - Switch Actions

- (void)unlimitedFlowSwitchChanged:(UISwitch *)sender {
  self.flowTextField.enabled = !sender.isOn;
  self.flowTextField.alpha = sender.isOn ? 0.5 : 1.0;
  if (sender.isOn) {
    self.flowTextField.text = @"";
  }
}

- (void)unlimitedNumSwitchChanged:(UISwitch *)sender {
  self.numTextField.enabled = !sender.isOn;
  self.numTextField.alpha = sender.isOn ? 0.5 : 1.0;
  if (sender.isOn) {
    self.numTextField.text = @"";
  }
}

- (void)permanentSwitchChanged:(UISwitch *)sender {
  self.expDaysTextField.enabled = !sender.isOn;
  self.expDaysTextField.alpha = sender.isOn ? 0.5 : 1.0;
  if (sender.isOn) {
    self.expDaysTextField.text = @"";
  }
}

- (void)statusSwitchChanged:(UISwitch *)sender {
  self.status = sender.isOn ? 1 : 0;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == self.usernameTextField) {
    [self.passwordTextField becomeFirstResponder];
  } else {
    [textField resignFirstResponder];
  }
  return YES;
}

@end
