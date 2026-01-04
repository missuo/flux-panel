//
//  FLXUserListViewController.m
//  Flux
//
//  用户管理视图控制器实现 (管理员)
//

#import "FLXUserListViewController.h"
#import "FLXAPIClient.h"
#import "FLXModels.h"
#import "FLXUserEditViewController.h"

@interface FLXUserListViewController () <UITableViewDelegate,
                                         UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIRefreshControl *refreshControl;
@property(nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property(nonatomic, strong) UILabel *emptyLabel;

@property(nonatomic, strong) NSArray<FLXUser *> *users;
@property(nonatomic, assign) BOOL isLoading;

@end

@implementation FLXUserListViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
  [self loadData];
}

- (void)setupUI {
  self.title = @"用户管理";
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
  self.emptyLabel.text = @"暂无用户\n点击右上角添加";
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
      getAllUsersWithCompletion:^(NSDictionary *response, NSError *error) {
        [self.loadingIndicator stopAnimating];
        [self.refreshControl endRefreshing];
        self.isLoading = NO;

        if (error) {
          [self showAlertWithTitle:@"错误" message:@"获取用户列表失败"];
          return;
        }

        if ([response[@"code"] integerValue] != 0) {
          [self showAlertWithTitle:@"错误"
                           message:response[@"msg"] ?: @"获取失败"];
          return;
        }

        NSArray *data = response[@"data"];
        NSMutableArray *users = [NSMutableArray array];
        for (NSDictionary *dict in data) {
          FLXUser *user = [[FLXUser alloc] initWithDictionary:dict];
          [users addObject:user];
        }
        self.users = [users copy];

        self.emptyLabel.hidden = self.users.count > 0;
        [self.tableView reloadData];
      }];
}

- (void)addButtonTapped {
  FLXUserEditViewController *editVC = [[FLXUserEditViewController alloc] init];
  editVC.completionHandler = ^{
    [self loadData];
  };
  UINavigationController *navVC =
      [[UINavigationController alloc] initWithRootViewController:editVC];
  [self presentViewController:navVC animated:YES completion:nil];
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
  return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                             reuseIdentifier:nil];

  FLXUser *user = self.users[indexPath.row];

  UIListContentConfiguration *content =
      [UIListContentConfiguration subtitleCellConfiguration];
  content.text = user.username;
  content.secondaryText = [NSString
      stringWithFormat:@"%@\n流量: %@ / %@\n转发: %@", user.roleString,
                       user.formattedUsedFlow, user.formattedFlow,
                       user.isUnlimitedNum
                           ? @"无限制"
                           : [NSString
                                 stringWithFormat:@"%ld", (long)user.num]];
  content.secondaryTextProperties.numberOfLines = 3;
  content.secondaryTextProperties.color = [UIColor secondaryLabelColor];

  if (user.isAdmin) {
    content.image = [UIImage systemImageNamed:@"person.badge.shield.checkmark"];
    content.imageProperties.tintColor = [UIColor systemOrangeColor];
  } else {
    // Check if user is disabled
    if (user.status == 0) {
      content.image = [UIImage systemImageNamed:@"person.fill.xmark"];
      content.imageProperties.tintColor = [UIColor systemGrayColor];
      content.textProperties.color = [UIColor secondaryLabelColor];
      content.text = [NSString stringWithFormat:@"%@ (已禁用)", user.username];
    } else {
      content.image = [UIImage systemImageNamed:@"person.fill"];
      content.imageProperties.tintColor = [UIColor systemBlueColor];
    }
  }

  cell.contentConfiguration = content;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  FLXUser *user = self.users[indexPath.row];
  [self showActionsForUser:user];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:
        (NSIndexPath *)indexPath {
  FLXUser *user = self.users[indexPath.row];

  // 不允许删除管理员
  if (user.isAdmin) {
    return nil;
  }

  UIContextualAction *deleteAction = [UIContextualAction
      contextualActionWithStyle:UIContextualActionStyleDestructive
                          title:@"删除"
                        handler:^(UIContextualAction *action,
                                  UIView *sourceView,
                                  void (^completionHandler)(BOOL)) {
                          [self confirmDeleteUser:user];
                          completionHandler(YES);
                        }];
  deleteAction.image = [UIImage systemImageNamed:@"trash"];

  UIContextualAction *resetAction = [UIContextualAction
      contextualActionWithStyle:UIContextualActionStyleNormal
                          title:@"重置流量"
                        handler:^(UIContextualAction *action,
                                  UIView *sourceView,
                                  void (^completionHandler)(BOOL)) {
                          [self resetFlowForUser:user];
                          completionHandler(YES);
                        }];
  resetAction.backgroundColor = [UIColor systemOrangeColor];
  resetAction.image = [UIImage systemImageNamed:@"arrow.counterclockwise"];

  return [UISwipeActionsConfiguration
      configurationWithActions:@[ deleteAction, resetAction ]];
}

- (void)showActionsForUser:(FLXUser *)user {
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:user.username
                       message:nil
                preferredStyle:UIAlertControllerStyleActionSheet];

  [alert addAction:[UIAlertAction actionWithTitle:@"查看详情"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                            [self showUserDetails:user];
                                          }]];

  if (!user.isAdmin) {
    [alert addAction:[UIAlertAction actionWithTitle:@"编辑用户"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                              [self editUser:user];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"重置流量"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                              [self resetFlowForUser:user];
                                            }]];

    [alert
        addAction:[UIAlertAction actionWithTitle:@"删除"
                                           style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *action) {
                                           [self confirmDeleteUser:user];
                                         }]];
  }

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];

  if ([[UIDevice currentDevice] userInterfaceIdiom] ==
      UIUserInterfaceIdiomPad) {
    alert.popoverPresentationController.sourceView = self.tableView;
  }

  [self presentViewController:alert animated:YES completion:nil];
}

- (void)showUserDetails:(FLXUser *)user {
  NSMutableString *details = [NSMutableString string];
  [details appendFormat:@"用户名: %@\n", user.username];
  [details appendFormat:@"角色: %@\n", user.roleString];
  [details appendFormat:@"总流量: %@\n", user.formattedFlow];
  [details appendFormat:@"已用流量: %@\n", user.formattedUsedFlow];
  [details
      appendFormat:@"转发配额: %@\n",
                   user.isUnlimitedNum
                       ? @"无限制"
                       : [NSString stringWithFormat:@"%ld", (long)user.num]];

  NSString *expTimeStr = @"永久";
  long long expTimeMs = 0;

  if (user.expTime) {
    if ([user.expTime isKindOfClass:[NSString class]]) {
      if ([(NSString *)user.expTime length] > 0) {
        expTimeMs = [user.expTime longLongValue];
      }
    } else if ([user.expTime isKindOfClass:[NSNumber class]]) {
      expTimeMs = [user.expTime longLongValue];
    }
  }

  if (expTimeMs > 0) {
    NSDate *expDate = [NSDate dateWithTimeIntervalSince1970:expTimeMs / 1000.0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    expTimeStr = [formatter stringFromDate:expDate];
  }
  [details appendFormat:@"到期时间: %@\n", expTimeStr];

  NSString *resetDayStr =
      user.flowResetTime == 0
          ? @"不重置"
          : [NSString stringWithFormat:@"每月%ld日", (long)user.flowResetTime];
  [details appendFormat:@"流量重置日: %@", resetDayStr];

  [self showAlertWithTitle:@"用户详情" message:details];
}

- (void)editUser:(FLXUser *)user {
  FLXUserEditViewController *editVC =
      [[FLXUserEditViewController alloc] initWithUser:user];
  editVC.completionHandler = ^{
    [self loadData];
  };
  UINavigationController *navVC =
      [[UINavigationController alloc] initWithRootViewController:editVC];
  [self presentViewController:navVC animated:YES completion:nil];
}

- (void)resetFlowForUser:(FLXUser *)user {
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"确认重置"
                       message:[NSString stringWithFormat:
                                             @"确定要重置 \"%@\" 的流量吗？",
                                             user.username]
                preferredStyle:UIAlertControllerStyleAlert];

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [alert
      addAction:
          [UIAlertAction
              actionWithTitle:@"重置"
                        style:UIAlertActionStyleDestructive
                      handler:^(UIAlertAction *action) {
                        [[FLXAPIClient sharedClient]
                            resetUserFlowWithId:user.userId
                                     completion:^(NSDictionary *response,
                                                  NSError *error) {
                                       if (!error && [response[@"code"]
                                                         integerValue] == 0) {
                                         [self
                                             showToastWithMessage:@"重置成功"];
                                         [self loadData];
                                       } else {
                                         [self
                                             showAlertWithTitle:@"错误"
                                                        message:
                                                            response[@"msg"]
                                                                ?: @"重置失败"];
                                       }
                                     }];
                      }]];

  [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmDeleteUser:(FLXUser *)user {
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"确认删除"
                       message:[NSString
                                   stringWithFormat:@"确定要删除用户 \"%@\" "
                                                    @"吗？\n此操作会同时删除该"
                                                    @"用户的所有转发规则。",
                                                    user.username]
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
                            deleteUserWithId:user.userId
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
