//
//  FLXTunnelListViewController.m
//  Flux
//
//  隧道管理视图控制器实现 (管理员)
//

#import "FLXTunnelListViewController.h"
#import "FLXAPIClient.h"
#import "FLXModels.h"

@interface FLXTunnelListViewController () <UITableViewDelegate,
                                           UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIRefreshControl *refreshControl;
@property(nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property(nonatomic, strong) UILabel *emptyLabel;

@property(nonatomic, strong) NSArray<FLXTunnel *> *tunnels;
@property(nonatomic, strong) NSArray<FLXNode *> *nodes;
@property(nonatomic, assign) BOOL isLoading;

@end

@implementation FLXTunnelListViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
  [self loadData];
}

- (void)setupUI {
  self.title = @"隧道管理";
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
  [self.view addSubview:self.tableView];

  // 下拉刷新
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self
                          action:@selector(loadData)
                forControlEvents:UIControlEventValueChanged];
  self.tableView.refreshControl = self.refreshControl;

  // 空状态标签
  self.emptyLabel = [[UILabel alloc] init];
  self.emptyLabel.text = @"暂无隧道\n点击右上角添加";
  self.emptyLabel.numberOfLines = 0;
  self.emptyLabel.textAlignment = NSTextAlignmentCenter;
  self.emptyLabel.textColor = [UIColor secondaryLabelColor];
  self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.emptyLabel.hidden = YES;
  [self.view addSubview:self.emptyLabel];

  // 加载指示器
  self.loadingIndicator = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
  self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
  self.loadingIndicator.hidesWhenStopped = YES;
  [self.view addSubview:self.loadingIndicator];

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

- (void)loadData {
  if (self.isLoading)
    return;
  self.isLoading = YES;

  if (!self.refreshControl.isRefreshing) {
    [self.loadingIndicator startAnimating];
  }

  dispatch_group_t group = dispatch_group_create();

  __block NSArray *tunnelsData = nil;
  __block NSArray *nodesData = nil;

  // 获取隧道列表
  dispatch_group_enter(group);
  [[FLXAPIClient sharedClient]
      getAllTunnelsWithCompletion:^(NSDictionary *response, NSError *error) {
        if (!error && [response[@"code"] integerValue] == 0) {
          tunnelsData = response[@"data"];
        }
        dispatch_group_leave(group);
      }];

  // 获取节点列表
  dispatch_group_enter(group);
  [[FLXAPIClient sharedClient]
      getAllNodesWithCompletion:^(NSDictionary *response, NSError *error) {
        if (!error && [response[@"code"] integerValue] == 0) {
          nodesData = response[@"data"];
        }
        dispatch_group_leave(group);
      }];

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    [self.loadingIndicator stopAnimating];
    [self.refreshControl endRefreshing];
    self.isLoading = NO;

    if (tunnelsData) {
      NSMutableArray *tunnels = [NSMutableArray array];
      for (NSDictionary *dict in tunnelsData) {
        FLXTunnel *tunnel = [[FLXTunnel alloc] initWithDictionary:dict];
        [tunnels addObject:tunnel];
      }
      self.tunnels = [tunnels copy];
    }

    if (nodesData) {
      NSMutableArray *nodes = [NSMutableArray array];
      for (NSDictionary *dict in nodesData) {
        FLXNode *node = [[FLXNode alloc] initWithDictionary:dict];
        [nodes addObject:node];
      }
      self.nodes = [nodes copy];
    }

    self.emptyLabel.hidden = self.tunnels.count > 0;
    [self.tableView reloadData];
  });
}

- (void)addButtonTapped {
  if (self.nodes.count < 2) {
    [self showAlertWithTitle:@"提示" message:@"需要至少2个节点才能创建隧道"];
    return;
  }
  [self showAlertWithTitle:@"提示" message:@"请使用网页版创建隧道"];
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

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return self.tunnels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                             reuseIdentifier:nil];

  FLXTunnel *tunnel = self.tunnels[indexPath.row];

  UIListContentConfiguration *content =
      [UIListContentConfiguration subtitleCellConfiguration];
  content.text = tunnel.name;
  content.secondaryText = [NSString
      stringWithFormat:@"%@ → %@\n%@ | %@ | %@", tunnel.inNodeName ?: @"-",
                       tunnel.outNodeName ?: @"-", tunnel.typeString,
                       tunnel.flowString, tunnel.protocol];
  content.secondaryTextProperties.numberOfLines = 2;
  content.secondaryTextProperties.color = [UIColor secondaryLabelColor];
  content.image = [UIImage systemImageNamed:@"arrow.triangle.branch"];
  content.imageProperties.tintColor = [UIColor systemBlueColor];

  cell.contentConfiguration = content;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  FLXTunnel *tunnel = self.tunnels[indexPath.row];
  [self showActionsForTunnel:tunnel];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:
        (NSIndexPath *)indexPath {
  FLXTunnel *tunnel = self.tunnels[indexPath.row];

  UIContextualAction *deleteAction = [UIContextualAction
      contextualActionWithStyle:UIContextualActionStyleDestructive
                          title:@"删除"
                        handler:^(UIContextualAction *action,
                                  UIView *sourceView,
                                  void (^completionHandler)(BOOL)) {
                          [self confirmDeleteTunnel:tunnel];
                          completionHandler(YES);
                        }];
  deleteAction.image = [UIImage systemImageNamed:@"trash"];

  return
      [UISwipeActionsConfiguration configurationWithActions:@[ deleteAction ]];
}

- (void)showActionsForTunnel:(FLXTunnel *)tunnel {
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:tunnel.name
                       message:nil
                preferredStyle:UIAlertControllerStyleActionSheet];

  [alert addAction:[UIAlertAction actionWithTitle:@"诊断隧道"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            [self diagnoseTunnel:tunnel];
                                          }]];

  [alert addAction:[UIAlertAction
                       actionWithTitle:@"复制入口IP"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
                                 if (tunnel.inIP.length > 0) {
                                   UIPasteboard.generalPasteboard.string =
                                       tunnel.inIP;
                                   [self showToastWithMessage:@"已复制"];
                                 }
                               }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"删除"
                                            style:UIAlertActionStyleDestructive
                                          handler:^(UIAlertAction *action) {
                                            [self confirmDeleteTunnel:tunnel];
                                          }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];

  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    alert.popoverPresentationController.sourceView = self.tableView;
  }

  [self presentViewController:alert animated:YES completion:nil];
}

- (void)diagnoseTunnel:(FLXTunnel *)tunnel {
  UIAlertController *loadingAlert =
      [UIAlertController alertControllerWithTitle:@"诊断中..."
                                          message:@"正在检测隧道连接状态"
                                   preferredStyle:UIAlertControllerStyleAlert];
  [self presentViewController:loadingAlert animated:YES completion:nil];

  [[FLXAPIClient sharedClient]
      diagnoseTunnelWithId:tunnel.tunnelId
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
                                                                response[@"msg"]
                                                                    ?: @"网络错"
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
                                             BOOL success =
                                                 [result[@"success"] boolValue];
                                             NSString *description =
                                                 result[@"description"] ?: @"";

                                             if (success) {
                                               NSNumber *avgTime =
                                                   result[@"averageTime"];
                                               [message
                                                   appendFormat:
                                                       @"✅ %@\n延迟: "
                                                       @"%.1fms\n\n",
                                                       description,
                                                       avgTime.doubleValue];
                                             } else {
                                               NSString *errorMsg =
                                                   result[@"message"]
                                                       ?: @"连接失败";
                                               [message
                                                   appendFormat:
                                                       @"❌ %@\n错误: %@\n\n",
                                                       description, errorMsg];
                                             }
                                           }

                                           [self showAlertWithTitle:@"诊断结果"
                                                            message:message];
                                         }];
                }];
}

- (void)confirmDeleteTunnel:(FLXTunnel *)tunnel {
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"确认删除"
                       message:[NSString
                                   stringWithFormat:@"确定要删除隧道 \"%@\" "
                                                    @"吗？\n此操作会同时删除该"
                                                    @"隧道下的所有转发规则。",
                                                    tunnel.name]
                preferredStyle:UIAlertControllerStyleAlert];

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [alert
      addAction:
          [UIAlertAction
              actionWithTitle:@"删除"
                        style:UIAlertActionStyleDestructive
                      handler:^(UIAlertAction *action) {
                        [[FLXAPIClient sharedClient]
                            deleteTunnelWithId:tunnel.tunnelId
                                    completion:^(NSDictionary *response,
                                                 NSError *error) {
                                      if (!error && [response[@"code"]
                                                        integerValue] == 0) {
                                        [self showToastWithMessage:@"删除成功"];
                                        [self loadData];
                                      } else {
                                        [self
                                            showAlertWithTitle:@"错误"
                                                       message:
                                                           response[@"msg"]
                                                               ?: @"删除失败"];
                                      }
                                    }];
                      }]];

  [self presentViewController:alert animated:YES completion:nil];
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
