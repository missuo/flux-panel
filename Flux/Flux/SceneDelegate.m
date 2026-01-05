//
//  SceneDelegate.m
//  Flux
//
//  Created by Vincent Yang on 1/4/26.
//

#import "SceneDelegate.h"
#import "FLXAPIClient.h"
#import "FLXLoginViewController.h"
#import "FLXMainTabBarController.h"
#import "FLXWidgetHelper.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
  // 创建主窗口
  UIWindowScene *windowScene = (UIWindowScene *)scene;
  self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

  // 检查是否已登录
  NSString *token =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"authToken"];
  NSString *serverURL =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"serverURL"];

  if (token && token.length > 0 && serverURL && serverURL.length > 0) {
    // 已登录，恢复 API 客户端配置
    [[FLXAPIClient sharedClient] setBaseURL:serverURL];
    [[FLXAPIClient sharedClient] setAuthToken:token];

    // 同步登录信息到 Widget App Groups
    [FLXWidgetHelper saveServerURL:serverURL];
    [FLXWidgetHelper saveAuthToken:token];

    // 显示主界面
    FLXMainTabBarController *tabBarController =
        [[FLXMainTabBarController alloc] init];
    self.window.rootViewController = tabBarController;
  } else {
    // 未登录，显示登录界面
    FLXLoginViewController *loginVC = [[FLXLoginViewController alloc] init];
    self.window.rootViewController = loginVC;
  }

  [self.window makeKeyAndVisible];
}

- (void)sceneDidDisconnect:(UIScene *)scene {
  // Called as the scene is being released by the system.
  // This occurs shortly after the scene enters the background, or when its
  // session is discarded. Release any resources associated with this scene that
  // can be re-created the next time the scene connects. The scene may
  // re-connect later, as its session was not necessarily discarded (see
  // `application:didDiscardSceneSessions` instead).
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
  // Called when the scene has moved from an inactive state to an active state.
  // Use this method to restart any tasks that were paused (or not yet started)
  // when the scene was inactive.
}

- (void)sceneWillResignActive:(UIScene *)scene {
  // Called when the scene will move from an active state to an inactive state.
  // This may occur due to temporary interruptions (ex. an incoming phone call).
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
  // Called as the scene transitions from the background to the foreground.
  // Use this method to undo the changes made on entering the background.
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
  // Called as the scene transitions from the foreground to the background.
  // Use this method to save data, release shared resources, and store enough
  // scene-specific state information to restore the scene back to its current
  // state.
}

@end
