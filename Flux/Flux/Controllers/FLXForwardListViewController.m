//
//  FLXForwardListViewController.m
//  Flux
//
//  转发列表视图控制器实现
//

#import "FLXForwardListViewController.h"
#import "FLXAPIClient.h"
#import "FLXForwardEditViewController.h"
#import "FLXModels.h"

@interface FLXForwardListViewController () <UITableViewDelegate,
                                            UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIRefreshControl *refreshControl;
@property(nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property(nonatomic, strong) UILabel *emptyLabel;

@property(nonatomic, strong) NSArray<FLXForward *> *forwards;
@property(nonatomic, strong) NSArray<FLXTunnel *> *tunnels;
@property(nonatomic, assign) BOOL isLoading;

@end

@implementation FLXForwardListViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
  [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self loadData];
}

- (void)setupUI {
  self.title = @"转发管理";
  self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

  // 添加按钮
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                           target:self
                           action:@selector(addButtonTapped)];

  // 表格视图
  self.tableView =
      [[UITableView alloc] initWithFrame:CGRectZero
                                   style:UITableViewStyleInsetGrouped];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.rowHeight = UITableViewAutomaticDimension;
  self.tableView.estimatedRowHeight = 80;
  [self.tableView registerClass:[UITableViewCell class]
         forCellReuseIdentifier:@"ForwardCell"];
  [self.view addSubview:self.tableView];

  // 下拉刷新
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self
                          action:@selector(refreshData)
                forControlEvents:UIControlEventValueChanged];
  self.tableView.refreshControl = self.refreshControl;

  // 空状态标签
  self.emptyLabel = [[UILabel alloc] init];
  self.emptyLabel.text = @"暂无转发规则\n点击右上角添加";
  self.emptyLabel.numberOfLines = 0;
  self.emptyLabel.textAlignment = NSTextAlignmentCenter;
  self.emptyLabel.textColor = [UIColor secondaryLabelColor];
  self.emptyLabel.font = [UIFont systemFontOfSize:16];
  self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.emptyLabel.hidden = YES;
  [self.view addSubview:self.emptyLabel];

  // 加载指示器
  self.loadingIndicator = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
  self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
  self.loadingIndicator.hidesWhenStopped = YES;
  [self.view addSubview:self.loadingIndicator];

  // 约束
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.tableView.leadingAnchor
        constraintEqualToAnchor:self.view.leadingAnchor],
    [self.tableView.trailingAnchor
        constraintEqualToAnchor:self.view.trailingAnchor],
    [self.tableView.bottomAnchor
        constraintEqualToAnchor:self.view.bottomAnchor],

    [self.emptyLabel.centerXAnchor
        constraintEqualToAnchor:self.view.centerXAnchor],
    [self.emptyLabel.centerYAnchor
        constraintEqualToAnchor:self.view.centerYAnchor],

    [self.loadingIndicator.centerXAnchor
        constraintEqualToAnchor:self.view.centerXAnchor],
    [self.loadingIndicator.centerYAnchor
        constraintEqualToAnchor:self.view.centerYAnchor],
  ]];
}

- (void)refreshData {
  [self loadData];
}

- (void)loadData {
  if (self.isLoading)
    return;
  self.isLoading = YES;

  if (!self.refreshControl.isRefreshing) {
    [self.loadingIndicator startAnimating];
  }

  dispatch_group_t group = dispatch_group_create();

  __block NSArray *forwardsData = nil;
  __block NSArray *tunnelsData = nil;
  __block NSString *errorMessage = nil;

  // 获取转发列表
  dispatch_group_enter(group);
  [[FLXAPIClient sharedClient]
      getForwardListWithCompletion:^(NSDictionary *response, NSError *error) {
        if (!error && [response[@"code"] integerValue] == 0) {
          forwardsData = response[@"data"];
        } else {
          errorMessage = response[@"msg"] ?: @"获取转发列表失败";
        }
        dispatch_group_leave(group);
      }];

  // 获取隧道列表
  dispatch_group_enter(group);
  [[FLXAPIClient sharedClient]
      getUserTunnelsWithCompletion:^(NSDictionary *response, NSError *error) {
        if (!error && [response[@"code"] integerValue] == 0) {
          tunnelsData = response[@"data"];
        }
        dispatch_group_leave(group);
      }];

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    [self.loadingIndicator stopAnimating];
    [self.refreshControl endRefreshing];
    self.isLoading = NO;

    // 解析转发列表
    if (forwardsData) {
      NSMutableArray *forwards = [NSMutableArray array];
      for (NSDictionary *dict in forwardsData) {
        FLXForward *forward = [[FLXForward alloc] initWithDictionary:dict];
        [forwards addObject:forward];
      }
      self.forwards = [forwards copy];
    }

    // 解析隧道列表
    if (tunnelsData) {
      NSMutableArray *tunnels = [NSMutableArray array];
      for (NSDictionary *dict in tunnelsData) {
        FLXTunnel *tunnel = [[FLXTunnel alloc] initWithDictionary:dict];
        [tunnels addObject:tunnel];
      }
      self.tunnels = [tunnels copy];
    }

    // 更新UI
    self.emptyLabel.hidden = self.forwards.count > 0;
    [self.tableView reloadData];
  });
}

- (void)addButtonTapped {
  if (self.tunnels.count == 0) {
    [self showAlertWithTitle:@"提示" message:@"暂无可用隧道，请联系管理员分配"];
    return;
  }

  FLXForwardEditViewController *editVC =
      [[FLXForwardEditViewController alloc] initWithTunnels:self.tunnels
                                                    forward:nil];
  editVC.completionHandler = ^{
    [self loadData];
  };
  UINavigationController *nav =
      [[UINavigationController alloc] initWithRootViewController:editVC];
  [self presentViewController:nav animated:YES completion:nil];
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
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return self.forwards.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:@"ForwardCell"
                                      forIndexPath:indexPath];

  FLXForward *forward = self.forwards[indexPath.row];

  UIListContentConfiguration *content =
      [UIListContentConfiguration subtitleCellConfiguration];
  content.text = forward.name;

  NSString *inAddrDisplay = forward.formattedInAddress;
  NSString *remoteAddrDisplay = forward.formattedRemoteAddress;
  content.secondaryText =
      [NSString stringWithFormat:@"入口: %@\n目标: %@\n流量: %@", inAddrDisplay,
                                 remoteAddrDisplay, forward.formattedTotalFlow];
  content.secondaryTextProperties.numberOfLines = 3;
  content.secondaryTextProperties.color = [UIColor secondaryLabelColor];
  content.secondaryTextProperties.font =
      [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];

  // 状态图标
  if (forward.isRunning) {
    content.image = [UIImage systemImageNamed:@"circle.fill"];
    content.imageProperties.tintColor = [UIColor systemGreenColor];
  } else {
    content.image = [UIImage systemImageNamed:@"circle.fill"];
    content.imageProperties.tintColor = [UIColor systemGrayColor];
  }

  cell.contentConfiguration = content;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  FLXForward *forward = self.forwards[indexPath.row];
  [self showActionsForForward:forward];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:
        (NSIndexPath *)indexPath {
  FLXForward *forward = self.forwards[indexPath.row];

  // 删除操作
  UIContextualAction *deleteAction = [UIContextualAction
      contextualActionWithStyle:UIContextualActionStyleDestructive
                          title:@"删除"
                        handler:^(UIContextualAction *action,
                                  UIView *sourceView,
                                  void (^completionHandler)(BOOL)) {
                          [self confirmDeleteForward:forward];
                          completionHandler(YES);
                        }];
  deleteAction.image = [UIImage systemImageNamed:@"trash"];

  // 开关操作
  NSString *toggleTitle = forward.isRunning ? @"暂停" : @"启动";
  UIContextualAction *toggleAction = [UIContextualAction
      contextualActionWithStyle:UIContextualActionStyleNormal
                          title:toggleTitle
                        handler:^(UIContextualAction *action,
                                  UIView *sourceView,
                                  void (^completionHandler)(BOOL)) {
                          [self toggleForward:forward];
                          completionHandler(YES);
                        }];
  toggleAction.backgroundColor = forward.isRunning ? [UIColor systemOrangeColor]
                                                   : [UIColor systemGreenColor];
  toggleAction.image = forward.isRunning
                           ? [UIImage systemImageNamed:@"pause.fill"]
                           : [UIImage systemImageNamed:@"play.fill"];

  return [UISwipeActionsConfiguration
      configurationWithActions:@[ deleteAction, toggleAction ]];
}

- (void)showActionsForForward:(FLXForward *)forward {
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:forward.name
                       message:nil
                preferredStyle:UIAlertControllerStyleActionSheet];

  // 复制入口地址
  [alert
      addAction:[UIAlertAction actionWithTitle:@"复制入口地址"
                                         style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                                         [self copyInAddressForForward:forward];
                                       }]];

  // 复制目标地址
  [alert addAction:[UIAlertAction
                       actionWithTitle:@"复制目标地址"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
                                 UIPasteboard.generalPasteboard.string =
                                     forward.remoteAddr;
                                 [self showToastWithMessage:@"已复制目标地址"];
                               }]];

  // 编辑
  [alert addAction:[UIAlertAction actionWithTitle:@"编辑"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            [self editForward:forward];
                                          }]];

  // 开关
  NSString *toggleTitle = forward.isRunning ? @"暂停服务" : @"启动服务";
  [alert addAction:[UIAlertAction actionWithTitle:toggleTitle
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            [self toggleForward:forward];
                                          }]];

  // 诊断
  [alert addAction:[UIAlertAction actionWithTitle:@"诊断连接"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            [self diagnoseForward:forward];
                                          }]];

  // 删除
  [alert addAction:[UIAlertAction actionWithTitle:@"删除"
                                            style:UIAlertActionStyleDestructive
                                          handler:^(UIAlertAction *action) {
                                            [self confirmDeleteForward:forward];
                                          }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];

  // iPad 适配
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    alert.popoverPresentationController.sourceView = self.tableView;
    alert.popoverPresentationController.permittedArrowDirections =
        UIPopoverArrowDirectionAny;
  }

  [self presentViewController:alert animated:YES completion:nil];
}

- (void)copyInAddressForForward:(FLXForward *)forward {
  NSArray *ips = forward.inIPList;
  if (ips.count == 0) {
    [self showToastWithMessage:@"无入口地址"];
    return;
  }

  if (ips.count == 1) {
    UIPasteboard.generalPasteboard.string = forward.formattedInAddress;
    [self showToastWithMessage:@"已复制入口地址"];
    return;
  }

  // 多个 IP 时显示选择
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"选择入口地址"
                       message:nil
                preferredStyle:UIAlertControllerStyleActionSheet];

  for (NSString *ip in ips) {
    NSString *address =
        [ip containsString:@":"] && ![ip hasPrefix:@"["]
            ? [NSString stringWithFormat:@"[%@]:%ld", ip, (long)forward.inPort]
            : [NSString stringWithFormat:@"%@:%ld", ip, (long)forward.inPort];

    [alert addAction:[UIAlertAction
                         actionWithTitle:address
                                   style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction *action) {
                                   UIPasteboard.generalPasteboard.string =
                                       address;
                                   [self showToastWithMessage:@"已复制"];
                                 }]];
  }

  // 复制全部
  [alert
      addAction:[UIAlertAction
                    actionWithTitle:@"复制全部"
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
                              NSMutableArray *allAddresses =
                                  [NSMutableArray array];
                              for (NSString *ip in ips) {
                                NSString *address =
                                    [ip containsString:@":"] &&
                                            ![ip hasPrefix:@"["]
                                        ? [NSString
                                              stringWithFormat:@"[%@]:%ld", ip,
                                                               (long)forward
                                                                   .inPort]
                                        : [NSString
                                              stringWithFormat:@"%@:%ld", ip,
                                                               (long)forward
                                                                   .inPort];
                                [allAddresses addObject:address];
                              }
                              UIPasteboard.generalPasteboard.string =
                                  [allAddresses componentsJoinedByString:@"\n"];
                              [self showToastWithMessage:@"已复制全部地址"];
                            }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];

  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect =
        CGRectMake(self.view.bounds.size.width / 2,
                   self.view.bounds.size.height / 2, 0, 0);
  }

  [self presentViewController:alert animated:YES completion:nil];
}

- (void)editForward:(FLXForward *)forward {
  FLXForwardEditViewController *editVC =
      [[FLXForwardEditViewController alloc] initWithTunnels:self.tunnels
                                                    forward:forward];
  editVC.completionHandler = ^{
    [self loadData];
  };
  UINavigationController *nav =
      [[UINavigationController alloc] initWithRootViewController:editVC];
  [self presentViewController:nav animated:YES completion:nil];
}

- (void)toggleForward:(FLXForward *)forward {
  if (forward.isRunning) {
    [[FLXAPIClient sharedClient]
        pauseForwardWithId:forward.forwardId
                completion:^(NSDictionary *response, NSError *error) {
                  if (!error && [response[@"code"] integerValue] == 0) {
                    [self showToastWithMessage:@"服务已暂停"];
                    [self loadData];
                  } else {
                    [self showAlertWithTitle:@"错误"
                                     message:response[@"msg"] ?: @"操作失败"];
                  }
                }];
  } else {
    [[FLXAPIClient sharedClient]
        resumeForwardWithId:forward.forwardId
                 completion:^(NSDictionary *response, NSError *error) {
                   if (!error && [response[@"code"] integerValue] == 0) {
                     [self showToastWithMessage:@"服务已启动"];
                     [self loadData];
                   } else {
                     [self showAlertWithTitle:@"错误"
                                      message:response[@"msg"] ?: @"操作失败"];
                   }
                 }];
  }
}

- (void)diagnoseForward:(FLXForward *)forward {
  UIAlertController *loadingAlert =
      [UIAlertController alertControllerWithTitle:@"诊断中..."
                                          message:@"正在检测连接状态"
                                   preferredStyle:UIAlertControllerStyleAlert];
  [self presentViewController:loadingAlert animated:YES completion:nil];

  [[FLXAPIClient sharedClient]
      diagnoseForwardWithId:forward.forwardId
                 completion:^(NSDictionary *response, NSError *error) {
                   [loadingAlert
                       dismissViewControllerAnimated:YES
                                          completion:^{
                                            if (error ||
                                                [response[@"code"]
                                                    integerValue] != 0) {
                                              [self
                                                  showAlertWithTitle:@"诊断失败"
                                                             message:
                                                                 response[@"ms"
                                                                          @"g"]
                                                                     ?: @"网络"
                                                                        @"错"
                                                                        @"误"];
                                              return;
                                            }

                                            NSDictionary *data =
                                                response[@"data"];
                                            NSArray *results = data[@"results"];

                                            NSMutableString *message =
                                                [NSMutableString string];
                                            for (NSDictionary
                                                     *result in results) {
                                              BOOL success = [result[@"success"]
                                                  boolValue];
                                              NSString *description =
                                                  result[@"description"] ?: @"";
                                              NSString *nodeName =
                                                  result[@"nodeName"] ?: @"-";

                                              if (success) {
                                                NSNumber *avgTime =
                                                    result[@"averageTime"];
                                                NSNumber *packetLoss =
                                                    result[@"packetLoss"];
                                                [message
                                                    appendFormat:
                                                        @"✅ %@\n节点: "
                                                        @"%@\n延迟: "
                                                        @"%.1fms\n丢包: "
                                                        @"%.1f%%\n\n",
                                                        description, nodeName,
                                                        avgTime.doubleValue,
                                                        packetLoss.doubleValue];
                                              } else {
                                                NSString *errorMsg =
                                                    result[@"message"]
                                                        ?: @"连接失败";
                                                [message
                                                    appendFormat:
                                                        @"❌ %@\n节点: "
                                                        @"%@\n错误: %@\n\n",
                                                        description, nodeName,
                                                        errorMsg];
                                              }
                                            }

                                            [self showAlertWithTitle:@"诊断结果"
                                                             message:message];
                                          }];
                 }];
}

- (void)confirmDeleteForward:(FLXForward *)forward {
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"确认删除"
                       message:[NSString stringWithFormat:
                                             @"确定要删除转发 \"%@\" 吗？",
                                             forward.name]
                preferredStyle:UIAlertControllerStyleAlert];

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"删除"
                                            style:UIAlertActionStyleDestructive
                                          handler:^(UIAlertAction *action) {
                                            [self deleteForward:forward];
                                          }]];

  [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteForward:(FLXForward *)forward {
  [[FLXAPIClient sharedClient]
      deleteForwardWithId:forward.forwardId
               completion:^(NSDictionary *response, NSError *error) {
                 if (!error && [response[@"code"] integerValue] == 0) {
                   [self showToastWithMessage:@"删除成功"];
                   [self loadData];
                 } else {
                   // 删除失败，询问是否强制删除
                   UIAlertController *alert = [UIAlertController
                       alertControllerWithTitle:@"删除失败"
                                        message:[NSString
                                                    stringWithFormat:
                                                        @"%@\n\n是否强制删除？",
                                                        response[@"msg"]
                                                            ?: @"删除失败"]
                                 preferredStyle:UIAlertControllerStyleAlert];

                   [alert addAction:[UIAlertAction
                                        actionWithTitle:@"取消"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
                   [alert
                       addAction:
                           [UIAlertAction
                               actionWithTitle:@"强制删除"
                                         style:UIAlertActionStyleDestructive
                                       handler:^(UIAlertAction *action) {
                                         [[FLXAPIClient sharedClient]
                                             forceDeleteForwardWithId:
                                                 forward.forwardId
                                                           completion:^(
                                                               NSDictionary
                                                                   *response,
                                                               NSError *error) {
                                                             if (!error &&
                                                                 [response
                                                                         [@"cod"
                                                                          @"e"]
                                                                     integerValue] ==
                                                                     0) {
                                                               [self
                                                                   showToastWithMessage:
                                                                       @"强制删"
                                                                       @"除成"
                                                                       @"功"];
                                                               [self loadData];
                                                             } else {
                                                               [self
                                                                   showAlertWithTitle:
                                                                       @"错误"
                                                                              message:
                                                                                  response[@"msg"]
                                                                                      ?: @"强制删除失败"];
                                                             }
                                                           }];
                                       }]];

                   [self presentViewController:alert
                                      animated:YES
                                    completion:nil];
                 }
               }];
}

- (void)showToastWithMessage:(NSString *)message {
  UIAlertController *toast =
      [UIAlertController alertControllerWithTitle:nil
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  [self presentViewController:toast animated:YES completion:nil];

  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        [toast dismissViewControllerAnimated:YES completion:nil];
      });
}

@end
