//
//  FLXAPIClient.h
//  Flux
//
//  API 网络请求客户端
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^FLXAPICompletionBlock)(NSDictionary * _Nullable response, NSError * _Nullable error);

@interface FLXAPIClient : NSObject

@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, copy, nullable) NSString *authToken;

+ (instancetype)sharedClient;

// 设置服务器地址
- (void)setBaseURL:(NSString *)baseURL;

// 设置认证Token
- (void)setAuthToken:(NSString * _Nullable)token;

// 通用 POST 请求
- (void)POST:(NSString *)endpoint
  parameters:(NSDictionary * _Nullable)parameters
  completion:(FLXAPICompletionBlock)completion;

// 通用 GET 请求
- (void)GET:(NSString *)endpoint
 parameters:(NSDictionary * _Nullable)parameters
 completion:(FLXAPICompletionBlock)completion;

#pragma mark - 用户相关 API

// 登录
- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                captchaId:(NSString * _Nullable)captchaId
               completion:(FLXAPICompletionBlock)completion;

// 检查验证码状态
- (void)checkCaptchaWithCompletion:(FLXAPICompletionBlock)completion;

// 获取用户套餐信息
- (void)getUserPackageWithCompletion:(FLXAPICompletionBlock)completion;

// 修改密码
- (void)updatePasswordWithCurrent:(NSString *)currentPassword
                      newPassword:(NSString *)newPassword
                  confirmPassword:(NSString *)confirmPassword
                      newUsername:(NSString *)newUsername
                       completion:(FLXAPICompletionBlock)completion;

#pragma mark - 转发相关 API

// 获取转发列表
- (void)getForwardListWithCompletion:(FLXAPICompletionBlock)completion;

// 创建转发
- (void)createForwardWithName:(NSString *)name
                     tunnelId:(NSInteger)tunnelId
                   remoteAddr:(NSString *)remoteAddr
                       inPort:(NSInteger)inPort
                interfaceName:(NSString * _Nullable)interfaceName
                     strategy:(NSString * _Nullable)strategy
                   completion:(FLXAPICompletionBlock)completion;

// 更新转发
- (void)updateForwardWithId:(NSInteger)forwardId
                       name:(NSString *)name
                   tunnelId:(NSInteger)tunnelId
                 remoteAddr:(NSString *)remoteAddr
                     inPort:(NSInteger)inPort
              interfaceName:(NSString * _Nullable)interfaceName
                   strategy:(NSString * _Nullable)strategy
                 completion:(FLXAPICompletionBlock)completion;

// 删除转发
- (void)deleteForwardWithId:(NSInteger)forwardId
                 completion:(FLXAPICompletionBlock)completion;

// 强制删除转发
- (void)forceDeleteForwardWithId:(NSInteger)forwardId
                      completion:(FLXAPICompletionBlock)completion;

// 暂停转发服务
- (void)pauseForwardWithId:(NSInteger)forwardId
                completion:(FLXAPICompletionBlock)completion;

// 恢复转发服务
- (void)resumeForwardWithId:(NSInteger)forwardId
                 completion:(FLXAPICompletionBlock)completion;

// 诊断转发
- (void)diagnoseForwardWithId:(NSInteger)forwardId
                   completion:(FLXAPICompletionBlock)completion;

#pragma mark - 隧道相关 API

// 获取用户可用隧道
- (void)getUserTunnelsWithCompletion:(FLXAPICompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
