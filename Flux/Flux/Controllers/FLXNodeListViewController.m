//
//  FLXNodeListViewController.m
//  Flux
//
//  节点管理视图控制器实现 (管理员)
//

#import "FLXNodeListViewController.h"
#import "FLXAPIClient.h"
#import "FLXModels.h"

@interface FLXNodeListViewController () <UITableViewDelegate,
                                         UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIRefreshControl *refreshControl;
@property(nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property(nonatomic, strong) UILabel *emptyLabel;

@property(nonatomic, strong) NSArray<FLXNode *> *nodes;
@property(nonatomic, strong) NSDictionary<NSNumber *, NSNumber *> *nodeStatus;
@property(nonatomic, assign) BOOL isLoading;

@end

@implementation FLXNodeListViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
  [self loadData];
}

- (void)setupUI {
  self.title = @"节点管理";
  self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

  // 按钮
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                           target:self
                           action:@selector(addButtonTapped)];
  UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                           target:self
                           action:@selector(checkAllStatus)];
  self.navigationItem.rightBarButtonItems = @[ addButton, refreshButton ];

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
  self.emptyLabel.text = @"暂无节点\n点击右上角添加";
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

  [[FLXAPIClient sharedClient]
      getAllNodesWithCompletion:^(NSDictionary *response, NSError *error) {
        [self.loadingIndicator stopAnimating];
        [self.refreshControl endRefreshing];
        self.isLoading = NO;

        if (error) {
          [self showAlertWithTitle:@"错误" message:@"获取节点列表失败"];
          return;
        }

        if ([response[@"code"] integerValue] != 0) {
          [self showAlertWithTitle:@"错误"
                           message:response[@"msg"] ?: @"获取失败"];
          return;
        }

        NSArray *data = response[@"data"];
        NSMutableArray *nodes = [NSMutableArray array];
        for (NSDictionary *dict in data) {
          FLXNode *node = [[FLXNode alloc] initWithDictionary:dict];
          [nodes addObject:node];
        }
        self.nodes = [nodes copy];

        self.emptyLabel.hidden = self.nodes.count > 0;
        [self.tableView reloadData];

        // 自动检查状态
        [self checkAllStatus];
      }];
}

- (void)checkAllStatus {
  [[FLXAPIClient sharedClient]
      checkNodeStatusWithNodeId:0
                     completion:^(NSDictionary *response, NSError *error) {
                       if (!error && [response[@"code"] integerValue] == 0) {
                         NSArray *statusList = response[@"data"];
                         NSMutableDictionary *statusDict =
                             [NSMutableDictionary dictionary];

                         for (NSDictionary *item in statusList) {
                           NSInteger nodeId = [item[@"nodeId"] integerValue];
                           BOOL online = [item[@"online"] boolValue];
                           statusDict[@(nodeId)] = @(online);
                         }

                         self.nodeStatus = [statusDict copy];
                         [self.tableView reloadData];
                       }
                     }];
}

- (void)addButtonTapped {
  [self showAlertWithTitle:@"提示" message:@"请使用网页版添加节点"];
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
  return self.nodes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                             reuseIdentifier:nil];

  FLXNode *node = self.nodes[indexPath.row];

  // 检查在线状态
  BOOL isOnline = NO;
  if (self.nodeStatus[@(node.nodeId)]) {
    isOnline = [self.nodeStatus[@(node.nodeId)] boolValue];
  }

  UIListContentConfiguration *content =
      [UIListContentConfiguration subtitleCellConfiguration];
  content.text = node.name;
  content.secondaryText = [NSString
      stringWithFormat:@"IP: %@\n端口: %@\n版本: %@", node.ip,
                       node.portRangeDescription, node.version ?: @"-"];
  content.secondaryTextProperties.numberOfLines = 3;
  content.secondaryTextProperties.color = [UIColor secondaryLabelColor];

  content.image = [UIImage systemImageNamed:@"server.rack"];
  content.imageProperties.tintColor =
      isOnline ? [UIColor systemGreenColor] : [UIColor systemGrayColor];

  cell.contentConfiguration = content;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  FLXNode *node = self.nodes[indexPath.row];
  [self showActionsForNode:node];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:
        (NSIndexPath *)indexPath {
  FLXNode *node = self.nodes[indexPath.row];

  UIContextualAction *deleteAction = [UIContextualAction
      contextualActionWithStyle:UIContextualActionStyleDestructive
                          title:@"删除"
                        handler:^(UIContextualAction *action,
                                  UIView *sourceView,
                                  void (^completionHandler)(BOOL)) {
                          [self confirmDeleteNode:node];
                          completionHandler(YES);
                        }];
  deleteAction.image = [UIImage systemImageNamed:@"trash"];

  return
      [UISwipeActionsConfiguration configurationWithActions:@[ deleteAction ]];
}

- (void)showActionsForNode:(FLXNode *)node {
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:node.name
                       message:nil
                preferredStyle:UIAlertControllerStyleActionSheet];

  [alert addAction:[UIAlertAction actionWithTitle:@"获取安装命令"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            [self
                                                getInstallCommandForNode:node];
                                          }]];

  [alert
      addAction:[UIAlertAction actionWithTitle:@"复制IP地址"
                                         style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                                         UIPasteboard.generalPasteboard.string =
                                             node.ip;
                                         [self showToastWithMessage:@"已复制"];
                                       }]];

  [alert
      addAction:[UIAlertAction actionWithTitle:@"复制密钥"
                                         style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                                         UIPasteboard.generalPasteboard.string =
                                             node.secret;
                                         [self showToastWithMessage:@"已复制"];
                                       }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"删除"
                                            style:UIAlertActionStyleDestructive
                                          handler:^(UIAlertAction *action) {
                                            [self confirmDeleteNode:node];
                                          }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];

  if ([[UIDevice currentDevice] userInterfaceIdiom] ==
      UIUserInterfaceIdiomPad) {
    alert.popoverPresentationController.sourceView = self.tableView;
  }

  [self presentViewController:alert animated:YES completion:nil];
}

- (void)getInstallCommandForNode:(FLXNode *)node {
  [[FLXAPIClient sharedClient]
      getInstallCommandForNodeId:node.nodeId
                      completion:^(NSDictionary *response, NSError *error) {
                        if (!error && [response[@"code"] integerValue] == 0) {
                          NSString *command = response[@"data"];

                          UIAlertController *alert = [UIAlertController
                              alertControllerWithTitle:@"安装命令"
                                               message:command
                                        preferredStyle:
                                            UIAlertControllerStyleAlert];

                          [alert
                              addAction:
                                  [UIAlertAction
                                      actionWithTitle:@"复制"
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action) {
                                                UIPasteboard.generalPasteboard
                                                    .string = command;
                                                [self showToastWithMessage:
                                                          @"已复制"];
                                              }]];

                          [alert
                              addAction:
                                  [UIAlertAction
                                      actionWithTitle:@"关闭"
                                                style:UIAlertActionStyleCancel
                                              handler:nil]];

                          [self presentViewController:alert
                                             animated:YES
                                           completion:nil];
                        } else {
                          [self showAlertWithTitle:@"错误"
                                           message:response[@"msg"]
                                                       ?: @"获取安装命令失败"];
                        }
                      }];
}

- (void)confirmDeleteNode:(FLXNode *)node {
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"确认删除"
                       message:[NSString
                                   stringWithFormat:
                                       @"确定要删除节点 \"%@\" 吗？", node.name]
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
                            deleteNodeWithId:node.nodeId
                                  completion:^(NSDictionary *response,
                                               NSError *error) {
                                    if (!error &&
                                        [response[@"code"] integerValue] == 0) {
                                      [self showToastWithMessage:@"删除成功"];
                                      [self loadData];
                                    } else {
                                      [self showAlertWithTitle:@"错误"
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
