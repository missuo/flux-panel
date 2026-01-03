//
//  FLXSettingsViewController.m
//  Flux
//
//  设置视图控制器实现
//

#import "FLXSettingsViewController.h"
#import "FLXAPIClient.h"
#import "FLXLoginViewController.h"
#import "FLXNodeListViewController.h"
#import "FLXTunnelListViewController.h"
#import "FLXUserListViewController.h"

@interface FLXSettingsViewController () <UITableViewDelegate,
                                         UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, assign) BOOL isAdmin;

@end

@implementation FLXSettingsViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // 检查管理员权限
  NSNumber *roleId =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"roleId"];
  self.isAdmin = (roleId != nil && roleId.integerValue == 0);

  [self setupUI];
}

- (void)setupUI {
  self.title = @"设置";
  self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

  // 表格视图
  self.tableView =
      [[UITableView alloc] initWithFrame:CGRectZero
                                   style:UITableViewStyleInsetGrouped];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
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
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.isAdmin ? 4 : 3;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  if (self.isAdmin) {
    switch (section) {
    case 0:
      return 3; // 管理功能：节点、隧道、用户
    case 1:
      return 2; // 账户信息
    case 2:
      return 2; // 应用信息
    case 3:
      return 1; // 退出登录
    default:
      return 0;
    }
  } else {
    switch (section) {
    case 0:
      return 2; // 账户信息
    case 1:
      return 2; // 应用信息
    case 2:
      return 1; // 退出登录
    default:
      return 0;
    }
  }
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  if (self.isAdmin) {
    switch (section) {
    case 0:
      return @"管理功能";
    case 1:
      return @"账户信息";
    case 2:
      return @"关于";
    default:
      return nil;
    }
  } else {
    switch (section) {
    case 0:
      return @"账户信息";
    case 1:
      return @"关于";
    default:
      return nil;
    }
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                             reuseIdentifier:nil];

  if (self.isAdmin) {
    // 管理员界面
    if (indexPath.section == 0) {
      // 管理功能
      switch (indexPath.row) {
      case 0:
        cell.textLabel.text = @"节点管理";
        cell.imageView.image = [UIImage systemImageNamed:@"server.rack"];
        cell.imageView.tintColor = [UIColor systemBlueColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;
      case 1:
        cell.textLabel.text = @"隧道管理";
        cell.imageView.image =
            [UIImage systemImageNamed:@"arrow.triangle.branch"];
        cell.imageView.tintColor = [UIColor systemPurpleColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;
      case 2:
        cell.textLabel.text = @"用户管理";
        cell.imageView.image = [UIImage systemImageNamed:@"person.2.fill"];
        cell.imageView.tintColor = [UIColor systemGreenColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;
      }
    } else if (indexPath.section == 1) {
      [self configureAccountCell:cell atRow:indexPath.row];
    } else if (indexPath.section == 2) {
      [self configureAboutCell:cell atRow:indexPath.row];
    } else if (indexPath.section == 3) {
      [self configureLogoutCell:cell];
    }
  } else {
    // 普通用户界面
    if (indexPath.section == 0) {
      [self configureAccountCell:cell atRow:indexPath.row];
    } else if (indexPath.section == 1) {
      [self configureAboutCell:cell atRow:indexPath.row];
    } else if (indexPath.section == 2) {
      [self configureLogoutCell:cell];
    }
  }

  return cell;
}

- (void)configureAccountCell:(UITableViewCell *)cell atRow:(NSInteger)row {
  if (row == 0) {
    cell.textLabel.text = @"用户名";
    NSString *userName =
        [[NSUserDefaults standardUserDefaults] stringForKey:@"userName"];
    cell.detailTextLabel.text = userName ?: @"--";
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  } else if (row == 1) {
    cell.textLabel.text = @"服务器";
    NSString *serverURL =
        [[NSUserDefaults standardUserDefaults] stringForKey:@"serverURL"];
    cell.detailTextLabel.text = serverURL ?: @"--";
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.minimumScaleFactor = 0.5;
  }
}

- (void)configureAboutCell:(UITableViewCell *)cell atRow:(NSInteger)row {
  if (row == 0) {
    cell.textLabel.text = @"版本";
    cell.detailTextLabel.text = @"1.5.3";
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  } else if (row == 1) {
    cell.textLabel.text = @"开源项目";
    cell.detailTextLabel.text = @"GitHub";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
}

- (void)configureLogoutCell:(UITableViewCell *)cell {
  cell.textLabel.text = @"退出登录";
  cell.textLabel.textColor = [UIColor systemRedColor];
  cell.textLabel.textAlignment = NSTextAlignmentCenter;
  cell.accessoryType = UITableViewCellAccessoryNone;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  if (self.isAdmin) {
    if (indexPath.section == 0) {
      // 管理功能
      switch (indexPath.row) {
      case 0:
        [self openNodeManagement];
        break;
      case 1:
        [self openTunnelManagement];
        break;
      case 2:
        [self openUserManagement];
        break;
      }
    } else if (indexPath.section == 2 && indexPath.row == 1) {
      [self openGitHub];
    } else if (indexPath.section == 3) {
      [self confirmLogout];
    }
  } else {
    if (indexPath.section == 1 && indexPath.row == 1) {
      [self openGitHub];
    } else if (indexPath.section == 2) {
      [self confirmLogout];
    }
  }
}

- (void)openNodeManagement {
  FLXNodeListViewController *vc = [[FLXNodeListViewController alloc] init];
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)openTunnelManagement {
  FLXTunnelListViewController *vc = [[FLXTunnelListViewController alloc] init];
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)openUserManagement {
  FLXUserListViewController *vc = [[FLXUserListViewController alloc] init];
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)openGitHub {
  NSURL *url = [NSURL URLWithString:@"https://github.com/missuo/flux-panel"];
  [[UIApplication sharedApplication] openURL:url
                                     options:@{}
                           completionHandler:nil];
}

- (void)confirmLogout {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"确认退出"
                                          message:@"确定要退出登录吗？"
                                   preferredStyle:UIAlertControllerStyleAlert];

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"退出"
                                            style:UIAlertActionStyleDestructive
                                          handler:^(UIAlertAction *action) {
                                            [self logout];
                                          }]];

  [self presentViewController:alert animated:YES completion:nil];
}

- (void)logout {
  // 清除登录信息
  [[FLXAPIClient sharedClient] setAuthToken:nil];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"userName"];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"roleId"];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"isAdmin"];
  [[NSUserDefaults standardUserDefaults] synchronize];

  // 跳转到登录界面
  FLXLoginViewController *loginVC = [[FLXLoginViewController alloc] init];
  UIWindow *window = self.view.window;

  [UIView transitionWithView:window
                    duration:0.3
                     options:UIViewAnimationOptionTransitionCrossDissolve
                  animations:^{
                    window.rootViewController = loginVC;
                  }
                  completion:nil];
}

@end
