//
//  FLXWidgetHelper.h
//  Flux
//
//  Widget 数据共享助手
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Widget 数据共享的 App Group ID
extern NSString *const FLXAppGroupID;

@interface FLXWidgetHelper : NSObject

/// 获取共享的 UserDefaults
+ (NSUserDefaults *_Nullable)sharedUserDefaults;

/// 保存服务器 URL 到 App Groups
+ (void)saveServerURL:(NSString *)serverURL;

/// 保存认证 Token 到 App Groups
+ (void)saveAuthToken:(NSString *_Nullable)authToken;

/// 保存流量数据到 App Groups
+ (void)saveFluxDataWithTotalFlow:(NSInteger)totalFlow
                         usedFlow:(NSInteger)usedFlow
                          expTime:(NSString *_Nullable)expTime;

/// 刷新 Widget
+ (void)reloadWidgets;

/// 清除 Widget 数据
+ (void)clearWidgetData;

@end

NS_ASSUME_NONNULL_END
