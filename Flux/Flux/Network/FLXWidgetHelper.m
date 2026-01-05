//
//  FLXWidgetHelper.m
//  Flux
//
//  Widget 数据共享助手实现
//

#import "FLXWidgetHelper.h"
#import <objc/runtime.h>

NSString *const FLXAppGroupID = @"group.nz.owo.Flux";

@implementation FLXWidgetHelper

+ (NSUserDefaults *)sharedUserDefaults {
  return [[NSUserDefaults alloc] initWithSuiteName:FLXAppGroupID];
}

+ (void)saveServerURL:(NSString *)serverURL {
  NSUserDefaults *defaults = [self sharedUserDefaults];
  if (defaults) {
    [defaults setObject:serverURL forKey:@"serverURL"];
    [defaults synchronize];
  }
}

+ (void)saveAuthToken:(NSString *)authToken {
  NSUserDefaults *defaults = [self sharedUserDefaults];
  if (defaults) {
    if (authToken) {
      [defaults setObject:authToken forKey:@"authToken"];
    } else {
      [defaults removeObjectForKey:@"authToken"];
    }
    [defaults synchronize];
  }
}

+ (void)saveFluxDataWithTotalFlow:(NSInteger)totalFlow
                         usedFlow:(NSInteger)usedFlow
                          expTime:(NSString *)expTime {
  NSUserDefaults *defaults = [self sharedUserDefaults];
  if (!defaults)
    return;

  NSMutableDictionary *fluxData = [NSMutableDictionary dictionary];
  fluxData[@"totalFlow"] = @(totalFlow);
  fluxData[@"usedFlow"] = @(usedFlow);
  fluxData[@"lastUpdate"] = @([[NSDate date] timeIntervalSince1970]);

  if (expTime) {
    fluxData[@"expTime"] = expTime;
  }

  NSString *serverURL = [defaults stringForKey:@"serverURL"];
  if (serverURL) {
    fluxData[@"serverURL"] = serverURL;
  }

  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:fluxData
                                                     options:0
                                                       error:&error];
  if (!error && jsonData) {
    [defaults setObject:jsonData forKey:@"fluxData"];
    [defaults synchronize];
  }

  // 刷新 Widget
  [self reloadWidgets];
}

+ (void)reloadWidgets {
  // 使用运行时动态调用 WidgetCenter 以避免编译时依赖
  if (@available(iOS 14.0, *)) {
    Class widgetCenterClass = NSClassFromString(@"WGWidgetCenter");
    if (!widgetCenterClass) {
      widgetCenterClass = NSClassFromString(@"WidgetCenter");
    }

    if (widgetCenterClass) {
      SEL sharedSelector = NSSelectorFromString(@"sharedCenter");
      if ([widgetCenterClass respondsToSelector:sharedSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id sharedCenter = [widgetCenterClass performSelector:sharedSelector];
        if (sharedCenter) {
          SEL reloadSelector = NSSelectorFromString(@"reloadAllTimelines");
          if ([sharedCenter respondsToSelector:reloadSelector]) {
            [sharedCenter performSelector:reloadSelector];
          }
        }
#pragma clang diagnostic pop
      }
    }
  }
}

+ (void)clearWidgetData {
  NSUserDefaults *defaults = [self sharedUserDefaults];
  if (defaults) {
    [defaults removeObjectForKey:@"fluxData"];
    [defaults removeObjectForKey:@"authToken"];
    [defaults synchronize];
  }
  [self reloadWidgets];
}

@end
