//
//  FLXMainTabBarController.m
//  Flux
//
//  主Tab栏控制器实现
//

#import "FLXMainTabBarController.h"
#import "FLXDashboardViewController.h"
#import "FLXForwardListViewController.h"
#import "FLXSettingsViewController.h"

@implementation FLXMainTabBarController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupViewControllers];
  [self setupAppearance];
}

- (void)setupViewControllers {
  // 仪表板
  FLXDashboardViewController *dashboardVC =
      [[FLXDashboardViewController alloc] init];
  UINavigationController *dashboardNav =
      [[UINavigationController alloc] initWithRootViewController:dashboardVC];
  dashboardNav.tabBarItem = [[UITabBarItem alloc]
      initWithTitle:@"仪表板"
              image:[UIImage systemImageNamed:@"chart.bar.fill"]
                tag:0];

  // 转发管理
  FLXForwardListViewController *forwardVC =
      [[FLXForwardListViewController alloc] init];
  UINavigationController *forwardNav =
      [[UINavigationController alloc] initWithRootViewController:forwardVC];
  forwardNav.tabBarItem = [[UITabBarItem alloc]
      initWithTitle:@"转发"
              image:[UIImage systemImageNamed:@"arrow.left.arrow.right"]
                tag:1];

  // 设置
  FLXSettingsViewController *settingsVC =
      [[FLXSettingsViewController alloc] init];
  UINavigationController *settingsNav =
      [[UINavigationController alloc] initWithRootViewController:settingsVC];
  settingsNav.tabBarItem = [[UITabBarItem alloc]
      initWithTitle:@"设置"
              image:[UIImage systemImageNamed:@"gearshape.fill"]
                tag:2];

  self.viewControllers = @[ dashboardNav, forwardNav, settingsNav ];
}

- (void)setupAppearance {
  // 设置Tab栏外观
  if (@available(iOS 15.0, *)) {
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithDefaultBackground];
    self.tabBar.scrollEdgeAppearance = appearance;
    self.tabBar.standardAppearance = appearance;
  }

  self.tabBar.tintColor = [UIColor systemBlueColor];
}

@end
