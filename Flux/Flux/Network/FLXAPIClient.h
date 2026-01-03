//
//  FLXAPIClient.h
//  Flux
//
//  API 网络请求客户端
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^FLXAPICompletionBlock)(NSDictionary *_Nullable response,
                                      NSError *_Nullable error);

@interface FLXAPIClient : NSObject

@property(nonatomic, copy) NSString *baseURL;
@property(nonatomic, copy, nullable) NSString *authToken;

+ (instancetype)sharedClient;

// 设置服务器地址
- (void)setBaseURL:(NSString *)baseURL;

// 设置认证Token
- (void)setAuthToken:(NSString *_Nullable)token;

// 通用 POST 请求
- (void)POST:(NSString *)endpoint
    parameters:(NSDictionary *_Nullable)parameters
    completion:(FLXAPICompletionBlock)completion;

// 通用 GET 请求
- (void)GET:(NSString *)endpoint
    parameters:(NSDictionary *_Nullable)parameters
    completion:(FLXAPICompletionBlock)completion;

#pragma mark - 用户相关 API

// 登录
- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                captchaId:(NSString *_Nullable)captchaId
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
                interfaceName:(NSString *_Nullable)interfaceName
                     strategy:(NSString *_Nullable)strategy
                   completion:(FLXAPICompletionBlock)completion;

// 更新转发
- (void)updateForwardWithId:(NSInteger)forwardId
                       name:(NSString *)name
                   tunnelId:(NSInteger)tunnelId
                 remoteAddr:(NSString *)remoteAddr
                     inPort:(NSInteger)inPort
              interfaceName:(NSString *_Nullable)interfaceName
                   strategy:(NSString *_Nullable)strategy
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

// 获取所有隧道 (管理员)
- (void)getAllTunnelsWithCompletion:(FLXAPICompletionBlock)completion;

// 创建隧道 (管理员)
- (void)createTunnelWithName:(NSString *)name
                    inNodeId:(NSInteger)inNodeId
                   outNodeId:(NSInteger)outNodeId
                        type:(NSInteger)type
                        flow:(NSInteger)flow
                    protocol:(NSString *)protocol
                trafficRatio:(CGFloat)trafficRatio
               tcpListenAddr:(NSString *_Nullable)tcpListenAddr
               udpListenAddr:(NSString *_Nullable)udpListenAddr
               interfaceName:(NSString *_Nullable)interfaceName
                  completion:(FLXAPICompletionBlock)completion;

// 更新隧道 (管理员)
- (void)updateTunnelWithId:(NSInteger)tunnelId
                      name:(NSString *)name
                  inNodeId:(NSInteger)inNodeId
                 outNodeId:(NSInteger)outNodeId
                      type:(NSInteger)type
                      flow:(NSInteger)flow
                  protocol:(NSString *)protocol
              trafficRatio:(CGFloat)trafficRatio
             tcpListenAddr:(NSString *_Nullable)tcpListenAddr
             udpListenAddr:(NSString *_Nullable)udpListenAddr
             interfaceName:(NSString *_Nullable)interfaceName
                completion:(FLXAPICompletionBlock)completion;

// 删除隧道 (管理员)
- (void)deleteTunnelWithId:(NSInteger)tunnelId
                completion:(FLXAPICompletionBlock)completion;

// 诊断隧道
- (void)diagnoseTunnelWithId:(NSInteger)tunnelId
                  completion:(FLXAPICompletionBlock)completion;

// 分配用户隧道权限 (管理员)
- (void)assignUserTunnelWithUserId:(NSInteger)userId
                          tunnelId:(NSInteger)tunnelId
                              flow:(NSInteger)flow
                               num:(NSInteger)num
                           expTime:(NSString *_Nullable)expTime
                     flowResetTime:(NSInteger)flowResetTime
                        completion:(FLXAPICompletionBlock)completion;

// 获取用户隧道权限列表 (管理员)
- (void)getUserTunnelListWithUserId:(NSInteger)userId
                         completion:(FLXAPICompletionBlock)completion;

// 移除用户隧道权限 (管理员)
- (void)removeUserTunnelWithId:(NSInteger)userTunnelId
                    completion:(FLXAPICompletionBlock)completion;

// 更新用户隧道权限 (管理员)
- (void)updateUserTunnelWithId:(NSInteger)userTunnelId
                          flow:(NSInteger)flow
                           num:(NSInteger)num
                       expTime:(NSString *_Nullable)expTime
                 flowResetTime:(NSInteger)flowResetTime
                    completion:(FLXAPICompletionBlock)completion;

#pragma mark - 节点相关 API (管理员)

// 获取所有节点
- (void)getAllNodesWithCompletion:(FLXAPICompletionBlock)completion;

// 创建节点
- (void)createNodeWithName:(NSString *)name
                    secret:(NSString *)secret
                        ip:(NSString *)ip
                  serverIp:(NSString *_Nullable)serverIp
                   portSta:(NSInteger)portSta
                   portEnd:(NSInteger)portEnd
                      http:(NSInteger)http
                       tls:(NSInteger)tls
                     socks:(NSInteger)socks
                completion:(FLXAPICompletionBlock)completion;

// 更新节点
- (void)updateNodeWithId:(NSInteger)nodeId
                    name:(NSString *)name
                  secret:(NSString *)secret
                      ip:(NSString *)ip
                serverIp:(NSString *_Nullable)serverIp
                 portSta:(NSInteger)portSta
                 portEnd:(NSInteger)portEnd
                    http:(NSInteger)http
                     tls:(NSInteger)tls
                   socks:(NSInteger)socks
              completion:(FLXAPICompletionBlock)completion;

// 删除节点
- (void)deleteNodeWithId:(NSInteger)nodeId
              completion:(FLXAPICompletionBlock)completion;

// 获取安装命令
- (void)getInstallCommandForNodeId:(NSInteger)nodeId
                        completion:(FLXAPICompletionBlock)completion;

// 检查节点状态
- (void)checkNodeStatusWithNodeId:(NSInteger)nodeId
                       completion:(FLXAPICompletionBlock)completion;

#pragma mark - 用户管理 API (管理员)

// 获取所有用户
- (void)getAllUsersWithCompletion:(FLXAPICompletionBlock)completion;

// 创建用户
- (void)createUserWithUsername:(NSString *)username
                      password:(NSString *)password
                          flow:(NSInteger)flow
                           num:(NSInteger)num
                       expTime:(NSString *_Nullable)expTime
                 flowResetTime:(NSInteger)flowResetTime
                    completion:(FLXAPICompletionBlock)completion;

// 更新用户
- (void)updateUserWithId:(NSInteger)userId
                username:(NSString *)username
                password:(NSString *_Nullable)password
                    flow:(NSInteger)flow
                     num:(NSInteger)num
                 expTime:(NSString *_Nullable)expTime
           flowResetTime:(NSInteger)flowResetTime
              completion:(FLXAPICompletionBlock)completion;

// 删除用户
- (void)deleteUserWithId:(NSInteger)userId
              completion:(FLXAPICompletionBlock)completion;

// 重置用户流量
- (void)resetUserFlowWithId:(NSInteger)userId
                 completion:(FLXAPICompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
