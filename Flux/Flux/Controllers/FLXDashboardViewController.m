//
//  FLXDashboardViewController.m
//  Flux
//
//  仪表板视图控制器实现
//

#import "FLXDashboardViewController.h"
#import "FLXAPIClient.h"
#import "FLXModels.h"

@interface FLXDashboardViewController () <UITableViewDelegate,
                                          UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIRefreshControl *refreshControl;
@property(nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@property(nonatomic, strong) FLXUserInfo *userInfo;
@property(nonatomic, strong) NSArray<FLXUserTunnel *> *userTunnels;
@property(nonatomic, strong) NSArray<FLXForward *> *forwards;
@property(nonatomic, assign) BOOL isAdmin;
@property(nonatomic, assign) BOOL isLoading;

@end

@implementation FLXDashboardViewController

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
  self.title = @"仪表板";
  self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

  // 检查是否为管理员
  self.isAdmin = [[NSUserDefaults standardUserDefaults] boolForKey:@"isAdmin"];

  // 表格视图
  self.tableView =
      [[UITableView alloc] initWithFrame:CGRectZero
                                   style:UITableViewStyleInsetGrouped];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.rowHeight = UITableViewAutomaticDimension;
  self.tableView.estimatedRowHeight = 60;
  [self.tableView registerClass:[UITableViewCell class]
         forCellReuseIdentifier:@"StatCard"];
  [self.tableView registerClass:[UITableViewCell class]
         forCellReuseIdentifier:@"TunnelCell"];
  [self.tableView registerClass:[UITableViewCell class]
         forCellReuseIdentifier:@"ForwardCell"];
  [self.view addSubview:self.tableView];

  // 下拉刷新
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self
                          action:@selector(refreshData)
                forControlEvents:UIControlEventValueChanged];
  self.tableView.refreshControl = self.refreshControl;

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

  [[FLXAPIClient sharedClient]
      getUserPackageWithCompletion:^(NSDictionary *response, NSError *error) {
        [self.loadingIndicator stopAnimating];
        [self.refreshControl endRefreshing];
        self.isLoading = NO;

        if (error) {
          [self showAlertWithTitle:@"错误" message:@"获取数据失败"];
          return;
        }

        NSInteger code = [response[@"code"] integerValue];
        if (code != 0) {
          [self showAlertWithTitle:@"错误"
                           message:response[@"msg"] ?: @"获取数据失败"];
          return;
        }

        NSDictionary *data = response[@"data"];

        // 解析用户信息
        NSDictionary *userInfoDict = data[@"userInfo"];
        if (userInfoDict) {
          self.userInfo = [[FLXUserInfo alloc] initWithDictionary:userInfoDict];
        }

        // 解析隧道权限
        NSArray *tunnelPermissions = data[@"tunnelPermissions"];
        if (tunnelPermissions) {
          NSMutableArray *tunnels = [NSMutableArray array];
          for (NSDictionary *tunnelDict in tunnelPermissions) {
            FLXUserTunnel *tunnel =
                [[FLXUserTunnel alloc] initWithDictionary:tunnelDict];
            [tunnels addObject:tunnel];
          }
          self.userTunnels = [tunnels copy];
        }

        // 解析转发列表
        NSArray *forwardsData = data[@"forwards"];
        if (forwardsData) {
          NSMutableArray *forwards = [NSMutableArray array];
          for (NSDictionary *forwardDict in forwardsData) {
            FLXForward *forward =
                [[FLXForward alloc] initWithDictionary:forwardDict];
            [forwards addObject:forward];
          }
          self.forwards = [forwards copy];
        }

        [self.tableView reloadData];
      }];
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
  NSInteger sections = 1; // 统计卡片
  if (!self.isAdmin && self.userTunnels.count > 0) {
    sections++; // 隧道权限
  }
  if (self.forwards.count > 0) {
    sections++; // 转发列表
  }
  return sections;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return 4; // 统计卡片: 总流量、已用流量、转发配额、已用转发
  }

  NSInteger currentSection = 1;
  if (!self.isAdmin && self.userTunnels.count > 0) {
    if (section == currentSection) {
      return self.userTunnels.count;
    }
    currentSection++;
  }

  if (self.forwards.count > 0 && section == currentSection) {
    return self.forwards.count;
  }

  return 0;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return @"套餐信息";
  }

  NSInteger currentSection = 1;
  if (!self.isAdmin && self.userTunnels.count > 0) {
    if (section == currentSection) {
      return [NSString stringWithFormat:@"隧道权限 (%lu)",
                                        (unsigned long)self.userTunnels.count];
    }
    currentSection++;
  }

  if (self.forwards.count > 0 && section == currentSection) {
    return [NSString
        stringWithFormat:@"我的转发 (%lu)", (unsigned long)self.forwards.count];
  }

  return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 0) {
    return [self statCardCellForRow:indexPath.row];
  }

  NSInteger currentSection = 1;
  if (!self.isAdmin && self.userTunnels.count > 0) {
    if (indexPath.section == currentSection) {
      return [self tunnelCellForRow:indexPath.row];
    }
    currentSection++;
  }

  if (self.forwards.count > 0 && indexPath.section == currentSection) {
    return [self forwardCellForRow:indexPath.row];
  }

  return [[UITableViewCell alloc] init];
}

- (UITableViewCell *)statCardCellForRow:(NSInteger)row {
  UITableViewCell *cell =
      [self.tableView dequeueReusableCellWithIdentifier:@"StatCard"];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                  reuseIdentifier:@"StatCard"];
  }

  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.accessoryType = UITableViewCellAccessoryNone;

  UIListContentConfiguration *content =
      [UIListContentConfiguration valueCellConfiguration];

  switch (row) {
  case 0:
    content.text = @"总流量";
    content.secondaryText =
        self.userInfo ? self.userInfo.formattedTotalFlow : @"--";
    content.image = [UIImage systemImageNamed:@"chart.bar.fill"];
    content.imageProperties.tintColor = [UIColor systemBlueColor];
    break;
  case 1:
    content.text = @"已用流量";
    content.secondaryText =
        self.userInfo ? self.userInfo.formattedUsedFlow : @"--";
    content.image = [UIImage systemImageNamed:@"arrow.up.arrow.down"];
    content.imageProperties.tintColor = [UIColor systemGreenColor];
    break;
  case 2:
    content.text = @"转发配额";
    content.secondaryText =
        self.userInfo
            ? (self.userInfo.isUnlimitedNum
                   ? @"无限制"
                   : [NSString
                         stringWithFormat:@"%ld", (long)self.userInfo.num])
            : @"--";
    content.image = [UIImage systemImageNamed:@"number"];
    content.imageProperties.tintColor = [UIColor systemPurpleColor];
    break;
  case 3:
    content.text = @"已用转发";
    content.secondaryText =
        [NSString stringWithFormat:@"%lu", (unsigned long)self.forwards.count];
    content.image = [UIImage systemImageNamed:@"link"];
    content.imageProperties.tintColor = [UIColor systemOrangeColor];
    break;
  }

  cell.contentConfiguration = content;
  return cell;
}

- (UITableViewCell *)tunnelCellForRow:(NSInteger)row {
  UITableViewCell *cell =
      [self.tableView dequeueReusableCellWithIdentifier:@"TunnelCell"];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                  reuseIdentifier:@"TunnelCell"];
  }

  FLXUserTunnel *tunnel = self.userTunnels[row];

  UIListContentConfiguration *content =
      [UIListContentConfiguration subtitleCellConfiguration];
  content.text = tunnel.tunnelName;
  content.secondaryText = [NSString
      stringWithFormat:@"%@ | 已用: %@ / %@", tunnel.billingTypeString,
                       tunnel.formattedUsedFlow, tunnel.formattedTotalFlow];
  content.secondaryTextProperties.color = [UIColor secondaryLabelColor];
  content.image = [UIImage systemImageNamed:@"arrow.triangle.branch"];
  content.imageProperties.tintColor = [UIColor systemBlueColor];

  cell.contentConfiguration = content;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  return cell;
}

- (UITableViewCell *)forwardCellForRow:(NSInteger)row {
  UITableViewCell *cell =
      [self.tableView dequeueReusableCellWithIdentifier:@"ForwardCell"];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                  reuseIdentifier:@"ForwardCell"];
  }

  FLXForward *forward = self.forwards[row];

  UIListContentConfiguration *content =
      [UIListContentConfiguration subtitleCellConfiguration];
  content.text = forward.name;
  content.secondaryText =
      [NSString stringWithFormat:@"%@ → %@", forward.formattedInAddress,
                                 forward.formattedRemoteAddress];
  content.secondaryTextProperties.color = [UIColor secondaryLabelColor];
  content.secondaryTextProperties.font =
      [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];

  if (forward.isRunning) {
    content.image = [UIImage systemImageNamed:@"circle.fill"];
    content.imageProperties.tintColor = [UIColor systemGreenColor];
  } else {
    content.image = [UIImage systemImageNamed:@"circle.fill"];
    content.imageProperties.tintColor = [UIColor systemGrayColor];
  }

  cell.contentConfiguration = content;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
