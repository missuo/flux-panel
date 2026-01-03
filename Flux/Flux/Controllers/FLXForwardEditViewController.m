//
//  FLXForwardEditViewController.m
//  Flux
//
//  转发编辑视图控制器实现
//

#import "FLXForwardEditViewController.h"
#import "FLXAPIClient.h"
#import "FLXModels.h"

@interface FLXForwardEditViewController () <
    UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate,
    UIPickerViewDelegate, UIPickerViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSArray<FLXTunnel *> *tunnels;
@property(nonatomic, strong, nullable) FLXForward *forward;
@property(nonatomic, assign) BOOL isEditing;

// 表单字段
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) NSInteger selectedTunnelIndex;
@property(nonatomic, copy) NSString *remoteAddr;
@property(nonatomic, assign) NSInteger inPort;
@property(nonatomic, copy) NSString *interfaceName;
@property(nonatomic, copy) NSString *strategy;

@property(nonatomic, strong) UITextField *nameTextField;
@property(nonatomic, strong) UITextField *remoteAddrTextField;
@property(nonatomic, strong) UITextField *inPortTextField;
@property(nonatomic, strong) UITextField *interfaceTextField;
@property(nonatomic, strong) UIButton *tunnelButton;
@property(nonatomic, strong) UISegmentedControl *strategySegment;

@property(nonatomic, assign) BOOL isSaving;

@end

@implementation FLXForwardEditViewController

- (instancetype)initWithTunnels:(NSArray<FLXTunnel *> *)tunnels
                        forward:(FLXForward *)forward {
  self = [super init];
  if (self) {
    _tunnels = tunnels;
    _forward = forward;
    _isEditing = (forward != nil);

    // 初始化表单字段
    if (forward) {
      _name = forward.name ?: @"";
      _remoteAddr =
          [forward.remoteAddr stringByReplacingOccurrencesOfString:@","
                                                        withString:@"\n"];
      _inPort = forward.inPort;
      _interfaceName = forward.interfaceName ?: @"";
      _strategy = forward.strategy ?: @"fifo";

      // 找到对应的隧道索引
      _selectedTunnelIndex = 0;
      for (NSInteger i = 0; i < tunnels.count; i++) {
        if (tunnels[i].tunnelId == forward.tunnelId) {
          _selectedTunnelIndex = i;
          break;
        }
      }
    } else {
      _name = @"";
      _remoteAddr = @"";
      _inPort = 0;
      _interfaceName = @"";
      _strategy = @"fifo";
      _selectedTunnelIndex = 0;
    }
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
}

- (void)setupUI {
  self.title = self.isEditing ? @"编辑转发" : @"新建转发";
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

  // 验证表单
  self.name = [self.nameTextField.text
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  self.remoteAddr = self.remoteAddrTextField.text;
  self.inPort = [self.inPortTextField.text integerValue];
  self.interfaceName = [self.interfaceTextField.text
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  self.strategy =
      self.strategySegment.selectedSegmentIndex == 0 ? @"fifo" : @"random";

  if (self.name.length == 0) {
    [self showAlertWithTitle:@"错误" message:@"请输入转发名称"];
    return;
  }

  if (self.name.length < 2 || self.name.length > 50) {
    [self showAlertWithTitle:@"错误" message:@"转发名称长度应在2-50个字符之间"];
    return;
  }

  if (self.remoteAddr.length == 0) {
    [self showAlertWithTitle:@"错误" message:@"请输入目标地址"];
    return;
  }

  // 处理远程地址，将换行转为逗号
  NSString *processedRemoteAddr = [[self.remoteAddr
      componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]
      componentsJoinedByString:@","];
  // 移除空地址
  NSArray *addresses = [processedRemoteAddr componentsSeparatedByString:@","];
  NSMutableArray *validAddresses = [NSMutableArray array];
  for (NSString *addr in addresses) {
    NSString *trimmed =
        [addr stringByTrimmingCharactersInSet:[NSCharacterSet
                                                  whitespaceCharacterSet]];
    if (trimmed.length > 0) {
      [validAddresses addObject:trimmed];
    }
  }
  processedRemoteAddr = [validAddresses componentsJoinedByString:@","];

  if (validAddresses.count == 0) {
    [self showAlertWithTitle:@"错误" message:@"请输入有效的目标地址"];
    return;
  }

  // 验证端口
  FLXTunnel *selectedTunnel = self.tunnels[self.selectedTunnelIndex];
  if (self.inPort > 0) {
    if (self.inPort < 1 || self.inPort > 65535) {
      [self showAlertWithTitle:@"错误" message:@"端口号必须在1-65535之间"];
      return;
    }

    if (selectedTunnel.inNodePortSta > 0 && selectedTunnel.inNodePortEnd > 0) {
      if (![selectedTunnel isPortValid:self.inPort]) {
        [self
            showAlertWithTitle:@"错误"
                       message:[NSString
                                   stringWithFormat:@"端口号必须在%@范围内",
                                                    selectedTunnel
                                                        .portRangeDescription]];
        return;
      }
    }
  }

  // 开始保存
  if (self.isSaving)
    return;
  self.isSaving = YES;
  self.navigationItem.rightBarButtonItem.enabled = NO;

  if (self.isEditing) {
    [[FLXAPIClient sharedClient]
        updateForwardWithId:self.forward.forwardId
                       name:self.name
                   tunnelId:selectedTunnel.tunnelId
                 remoteAddr:processedRemoteAddr
                     inPort:self.inPort
              interfaceName:self.interfaceName
                   strategy:validAddresses.count > 1 ? self.strategy : @"fifo"
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
                                      message:response[@"msg"] ?: @"保存失败"];
                   }
                 }];
  } else {
    [[FLXAPIClient sharedClient]
        createForwardWithName:self.name
                     tunnelId:selectedTunnel.tunnelId
                   remoteAddr:processedRemoteAddr
                       inPort:self.inPort
                interfaceName:self.interfaceName
                     strategy:validAddresses.count > 1 ? self.strategy : @"fifo"
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
    return 2; // 名称、隧道
  case 1:
    return 2; // 目标地址、入口端口
  case 2:
    return 2; // 接口名、负载均衡
  default:
    return 0;
  }
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  switch (section) {
  case 0:
    return @"基本信息";
  case 1:
    return @"地址配置";
  case 2:
    return @"高级选项";
  default:
    return nil;
  }
}

- (NSString *)tableView:(UITableView *)tableView
    titleForFooterInSection:(NSInteger)section {
  switch (section) {
  case 1:
    return @"目标地址格式: IP:端口 或 域名:端口\n支持多个地址，每行一个";
  case 2:
    return @"接口名用于指定网卡，留空则自动选择\n负载均衡仅在多地址时生效";
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
      // 名称
      cell.textLabel.text = @"名称";

      if (!self.nameTextField) {
        self.nameTextField =
            [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        self.nameTextField.placeholder = @"请输入转发名称";
        self.nameTextField.textAlignment = NSTextAlignmentRight;
        self.nameTextField.delegate = self;
        self.nameTextField.returnKeyType = UIReturnKeyNext;
        self.nameTextField.text = self.name;
      }
      cell.accessoryView = self.nameTextField;

    } else if (indexPath.row == 1) {
      // 隧道选择
      cell.textLabel.text = @"隧道";

      if (!self.tunnelButton) {
        self.tunnelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.tunnelButton.frame = CGRectMake(0, 0, 200, 44);
        self.tunnelButton.contentHorizontalAlignment =
            UIControlContentHorizontalAlignmentRight;
        [self.tunnelButton addTarget:self
                              action:@selector(tunnelButtonTapped)
                    forControlEvents:UIControlEventTouchUpInside];
      }

      NSString *tunnelName = self.tunnels.count > self.selectedTunnelIndex
                                 ? self.tunnels[self.selectedTunnelIndex].name
                                 : @"选择隧道";
      [self.tunnelButton setTitle:tunnelName forState:UIControlStateNormal];
      cell.accessoryView = self.tunnelButton;
    }
  } else if (indexPath.section == 1) {
    if (indexPath.row == 0) {
      // 目标地址
      cell.textLabel.text = @"目标地址";

      if (!self.remoteAddrTextField) {
        self.remoteAddrTextField =
            [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        self.remoteAddrTextField.placeholder = @"IP:端口";
        self.remoteAddrTextField.textAlignment = NSTextAlignmentRight;
        self.remoteAddrTextField.delegate = self;
        self.remoteAddrTextField.autocapitalizationType =
            UITextAutocapitalizationTypeNone;
        self.remoteAddrTextField.autocorrectionType =
            UITextAutocorrectionTypeNo;
        self.remoteAddrTextField.returnKeyType = UIReturnKeyNext;
        self.remoteAddrTextField.text = self.remoteAddr;
      }
      cell.accessoryView = self.remoteAddrTextField;

    } else if (indexPath.row == 1) {
      // 入口端口
      cell.textLabel.text = @"入口端口";

      if (!self.inPortTextField) {
        self.inPortTextField =
            [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
        self.inPortTextField.placeholder = @"自动分配";
        self.inPortTextField.textAlignment = NSTextAlignmentRight;
        self.inPortTextField.delegate = self;
        self.inPortTextField.keyboardType = UIKeyboardTypeNumberPad;
        self.inPortTextField.text =
            self.inPort > 0
                ? [NSString stringWithFormat:@"%ld", (long)self.inPort]
                : @"";
      }
      cell.accessoryView = self.inPortTextField;
    }
  } else if (indexPath.section == 2) {
    if (indexPath.row == 0) {
      // 接口名
      cell.textLabel.text = @"接口名";

      if (!self.interfaceTextField) {
        self.interfaceTextField =
            [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
        self.interfaceTextField.placeholder = @"可选";
        self.interfaceTextField.textAlignment = NSTextAlignmentRight;
        self.interfaceTextField.delegate = self;
        self.interfaceTextField.autocapitalizationType =
            UITextAutocapitalizationTypeNone;
        self.interfaceTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.interfaceTextField.text = self.interfaceName;
      }
      cell.accessoryView = self.interfaceTextField;

    } else if (indexPath.row == 1) {
      // 负载均衡策略
      cell.textLabel.text = @"负载均衡";

      if (!self.strategySegment) {
        self.strategySegment =
            [[UISegmentedControl alloc] initWithItems:@[ @"顺序", @"随机" ]];
        self.strategySegment.selectedSegmentIndex =
            [self.strategy isEqualToString:@"random"] ? 1 : 0;
      }
      cell.accessoryView = self.strategySegment;
    }
  }

  return cell;
}

#pragma mark - Actions

- (void)tunnelButtonTapped {
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"选择隧道"
                       message:nil
                preferredStyle:UIAlertControllerStyleActionSheet];

  for (NSInteger i = 0; i < self.tunnels.count; i++) {
    FLXTunnel *tunnel = self.tunnels[i];
    NSString *title = tunnel.name;
    if (tunnel.inNodePortSta > 0 && tunnel.inNodePortEnd > 0) {
      title = [NSString stringWithFormat:@"%@ (端口: %@)", tunnel.name,
                                         tunnel.portRangeDescription];
    }

    UIAlertAction *action = [UIAlertAction
        actionWithTitle:title
                  style:UIAlertActionStyleDefault
                handler:^(UIAlertAction *action) {
                  self.selectedTunnelIndex = i;
                  [self.tunnelButton setTitle:tunnel.name
                                     forState:UIControlStateNormal];
                }];

    if (i == self.selectedTunnelIndex) {
      [action setValue:[UIImage systemImageNamed:@"checkmark"] forKey:@"image"];
    }

    [alert addAction:action];
  }

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];

  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    alert.popoverPresentationController.sourceView = self.tunnelButton;
    alert.popoverPresentationController.sourceRect = self.tunnelButton.bounds;
  }

  [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == self.nameTextField) {
    [self.remoteAddrTextField becomeFirstResponder];
  } else if (textField == self.remoteAddrTextField) {
    [self.inPortTextField becomeFirstResponder];
  } else {
    [textField resignFirstResponder];
  }
  return YES;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
    numberOfRowsInComponent:(NSInteger)component {
  return self.tunnels.count;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  return self.tunnels[row].name;
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
  self.selectedTunnelIndex = row;
}

@end
