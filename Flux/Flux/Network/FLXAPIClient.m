//
//  FLXAPIClient.m
//  Flux
//
//  API 网络请求客户端实现
//

#import "FLXAPIClient.h"

@interface FLXAPIClient ()

@property(nonatomic, strong) NSURLSession *session;

@end

@implementation FLXAPIClient

+ (instancetype)sharedClient {
  static FLXAPIClient *sharedClient = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedClient = [[FLXAPIClient alloc] init];
  });
  return sharedClient;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSURLSessionConfiguration *config =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 30;
    config.timeoutIntervalForResource = 60;
    _session = [NSURLSession sessionWithConfiguration:config];

    // 从 UserDefaults 读取保存的配置
    NSString *savedURL =
        [[NSUserDefaults standardUserDefaults] stringForKey:@"serverURL"];
    NSString *savedToken =
        [[NSUserDefaults standardUserDefaults] stringForKey:@"authToken"];

    if (savedURL) {
      _baseURL = savedURL;
    }
    if (savedToken) {
      _authToken = savedToken;
    }
  }
  return self;
}

- (void)setBaseURL:(NSString *)baseURL {
  // 确保 URL 不以斜杠结尾
  if ([baseURL hasSuffix:@"/"]) {
    baseURL = [baseURL substringToIndex:baseURL.length - 1];
  }
  _baseURL = baseURL;
  [[NSUserDefaults standardUserDefaults] setObject:baseURL forKey:@"serverURL"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAuthToken:(NSString *)token {
  _authToken = token;
  if (token) {
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"authToken"];
  } else {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"authToken"];
  }
  [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - 通用请求方法

- (void)POST:(NSString *)endpoint
    parameters:(NSDictionary *)parameters
    completion:(FLXAPICompletionBlock)completion {

  NSString *urlString =
      [NSString stringWithFormat:@"%@/api/v1%@", self.baseURL, endpoint];
  NSURL *url = [NSURL URLWithString:urlString];

  if (!url) {
    NSError *error =
        [NSError errorWithDomain:@"FLXAPIErrorDomain"
                            code:-1
                        userInfo:@{NSLocalizedDescriptionKey : @"无效的 URL"}];
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(nil, error);
    });
    return;
  }

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  request.HTTPMethod = @"POST";
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

  // 添加认证Token
  if (self.authToken) {
    [request setValue:self.authToken forHTTPHeaderField:@"Authorization"];
  }

  // 序列化请求体
  if (parameters) {
    NSError *jsonError;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:parameters
                                                       options:0
                                                         error:&jsonError];
    if (jsonError) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, jsonError);
      });
      return;
    }
    request.HTTPBody = bodyData;
  } else {
    // 空请求体时发送空对象
    request.HTTPBody = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
  }

  NSURLSessionDataTask *task = [self.session
      dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response,
                            NSError *error) {
          if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
              completion(nil, error);
            });
            return;
          }

          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

          if (data) {
            NSError *jsonError;
            NSDictionary *json =
                [NSJSONSerialization JSONObjectWithData:data
                                                options:0
                                                  error:&jsonError];

            if (jsonError) {
              dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, jsonError);
              });
              return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
              completion(json, nil);
            });
          } else {
            NSError *noDataError = [NSError
                errorWithDomain:@"FLXAPIErrorDomain"
                           code:httpResponse.statusCode
                       userInfo:@{
                         NSLocalizedDescriptionKey : @"服务器无响应数据"
                       }];
            dispatch_async(dispatch_get_main_queue(), ^{
              completion(nil, noDataError);
            });
          }
        }];

  [task resume];
}

- (void)GET:(NSString *)endpoint
    parameters:(NSDictionary *)parameters
    completion:(FLXAPICompletionBlock)completion {

  NSString *urlString =
      [NSString stringWithFormat:@"%@/api/v1%@", self.baseURL, endpoint];

  // 添加查询参数
  if (parameters && parameters.count > 0) {
    NSMutableArray *queryItems = [NSMutableArray array];
    for (NSString *key in parameters) {
      NSString *value = [NSString stringWithFormat:@"%@", parameters[key]];
      NSString *encodedValue =
          [value stringByAddingPercentEncodingWithAllowedCharacters:
                     [NSCharacterSet URLQueryAllowedCharacterSet]];
      [queryItems
          addObject:[NSString stringWithFormat:@"%@=%@", key, encodedValue]];
    }
    urlString = [urlString
        stringByAppendingFormat:@"?%@",
                                [queryItems componentsJoinedByString:@"&"]];
  }

  NSURL *url = [NSURL URLWithString:urlString];

  if (!url) {
    NSError *error =
        [NSError errorWithDomain:@"FLXAPIErrorDomain"
                            code:-1
                        userInfo:@{NSLocalizedDescriptionKey : @"无效的 URL"}];
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(nil, error);
    });
    return;
  }

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  request.HTTPMethod = @"GET";
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

  // 添加认证Token
  if (self.authToken) {
    [request setValue:self.authToken forHTTPHeaderField:@"Authorization"];
  }

  NSURLSessionDataTask *task =
      [self.session dataTaskWithRequest:request
                      completionHandler:^(NSData *data, NSURLResponse *response,
                                          NSError *error) {
                        if (error) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                            completion(nil, error);
                          });
                          return;
                        }

                        if (data) {
                          NSError *jsonError;
                          NSDictionary *json = [NSJSONSerialization
                              JSONObjectWithData:data
                                         options:0
                                           error:&jsonError];

                          if (jsonError) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                              completion(nil, jsonError);
                            });
                            return;
                          }

                          dispatch_async(dispatch_get_main_queue(), ^{
                            completion(json, nil);
                          });
                        } else {
                          dispatch_async(dispatch_get_main_queue(), ^{
                            completion(nil, nil);
                          });
                        }
                      }];

  [task resume];
}

#pragma mark - 用户相关 API

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                captchaId:(NSString *)captchaId
               completion:(FLXAPICompletionBlock)completion {

  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
    @"username" : username,
    @"password" : password
  }];

  if (captchaId && captchaId.length > 0) {
    params[@"captchaId"] = captchaId;
  }

  [self POST:@"/user/login" parameters:params completion:completion];
}

- (void)checkCaptchaWithCompletion:(FLXAPICompletionBlock)completion {
  [self POST:@"/captcha/check" parameters:nil completion:completion];
}

- (void)getUserPackageWithCompletion:(FLXAPICompletionBlock)completion {
  [self POST:@"/user/package" parameters:nil completion:completion];
}

- (void)updatePasswordWithCurrent:(NSString *)currentPassword
                      newPassword:(NSString *)newPassword
                  confirmPassword:(NSString *)confirmPassword
                      newUsername:(NSString *)newUsername
                       completion:(FLXAPICompletionBlock)completion {

  NSDictionary *params = @{
    @"currentPassword" : currentPassword,
    @"newPassword" : newPassword,
    @"confirmPassword" : confirmPassword,
    @"newUsername" : newUsername
  };

  [self POST:@"/user/updatePassword" parameters:params completion:completion];
}

#pragma mark - 转发相关 API

- (void)getForwardListWithCompletion:(FLXAPICompletionBlock)completion {
  [self POST:@"/forward/list" parameters:nil completion:completion];
}

- (void)createForwardWithName:(NSString *)name
                     tunnelId:(NSInteger)tunnelId
                   remoteAddr:(NSString *)remoteAddr
                       inPort:(NSInteger)inPort
                interfaceName:(NSString *)interfaceName
                     strategy:(NSString *)strategy
                   completion:(FLXAPICompletionBlock)completion {

  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
    @"name" : name,
    @"tunnelId" : @(tunnelId),
    @"remoteAddr" : remoteAddr
  }];

  if (inPort > 0) {
    params[@"inPort"] = @(inPort);
  }

  if (interfaceName && interfaceName.length > 0) {
    params[@"interfaceName"] = interfaceName;
  }

  if (strategy && strategy.length > 0) {
    params[@"strategy"] = strategy;
  } else {
    params[@"strategy"] = @"fifo";
  }

  [self POST:@"/forward/create" parameters:params completion:completion];
}

- (void)updateForwardWithId:(NSInteger)forwardId
                       name:(NSString *)name
                   tunnelId:(NSInteger)tunnelId
                 remoteAddr:(NSString *)remoteAddr
                     inPort:(NSInteger)inPort
              interfaceName:(NSString *)interfaceName
                   strategy:(NSString *)strategy
                 completion:(FLXAPICompletionBlock)completion {

  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
    @"id" : @(forwardId),
    @"name" : name,
    @"tunnelId" : @(tunnelId),
    @"remoteAddr" : remoteAddr
  }];

  if (inPort > 0) {
    params[@"inPort"] = @(inPort);
  }

  if (interfaceName && interfaceName.length > 0) {
    params[@"interfaceName"] = interfaceName;
  }

  if (strategy && strategy.length > 0) {
    params[@"strategy"] = strategy;
  }

  [self POST:@"/forward/update" parameters:params completion:completion];
}

- (void)deleteForwardWithId:(NSInteger)forwardId
                 completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/forward/delete"
      parameters:@{@"id" : @(forwardId)}
      completion:completion];
}

- (void)forceDeleteForwardWithId:(NSInteger)forwardId
                      completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/forward/force-delete"
      parameters:@{@"id" : @(forwardId)}
      completion:completion];
}

- (void)pauseForwardWithId:(NSInteger)forwardId
                completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/forward/pause"
      parameters:@{@"id" : @(forwardId)}
      completion:completion];
}

- (void)resumeForwardWithId:(NSInteger)forwardId
                 completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/forward/resume"
      parameters:@{@"id" : @(forwardId)}
      completion:completion];
}

- (void)diagnoseForwardWithId:(NSInteger)forwardId
                   completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/forward/diagnose"
      parameters:@{@"forwardId" : @(forwardId)}
      completion:completion];
}

#pragma mark - 隧道相关 API

- (void)getUserTunnelsWithCompletion:(FLXAPICompletionBlock)completion {
  [self POST:@"/tunnel/user/tunnel" parameters:nil completion:completion];
}

- (void)getAllTunnelsWithCompletion:(FLXAPICompletionBlock)completion {
  [self POST:@"/tunnel/list" parameters:nil completion:completion];
}

- (void)createTunnelWithName:(NSString *)name
                    inNodeId:(NSInteger)inNodeId
                   outNodeId:(NSInteger)outNodeId
                        type:(NSInteger)type
                        flow:(NSInteger)flow
                    protocol:(NSString *)protocol
                trafficRatio:(CGFloat)trafficRatio
               tcpListenAddr:(NSString *)tcpListenAddr
               udpListenAddr:(NSString *)udpListenAddr
               interfaceName:(NSString *)interfaceName
                  completion:(FLXAPICompletionBlock)completion {
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
    @"name" : name,
    @"inNodeId" : @(inNodeId),
    @"outNodeId" : @(outNodeId),
    @"type" : @(type),
    @"flow" : @(flow),
    @"protocol" : protocol ?: @"tcp+udp",
    @"trafficRatio" : @(trafficRatio)
  }];

  if (tcpListenAddr && tcpListenAddr.length > 0) {
    params[@"tcpListenAddr"] = tcpListenAddr;
  }
  if (udpListenAddr && udpListenAddr.length > 0) {
    params[@"udpListenAddr"] = udpListenAddr;
  }
  if (interfaceName && interfaceName.length > 0) {
    params[@"interfaceName"] = interfaceName;
  }

  [self POST:@"/tunnel/create" parameters:params completion:completion];
}

- (void)updateTunnelWithId:(NSInteger)tunnelId
                      name:(NSString *)name
                  inNodeId:(NSInteger)inNodeId
                 outNodeId:(NSInteger)outNodeId
                      type:(NSInteger)type
                      flow:(NSInteger)flow
                  protocol:(NSString *)protocol
              trafficRatio:(CGFloat)trafficRatio
             tcpListenAddr:(NSString *)tcpListenAddr
             udpListenAddr:(NSString *)udpListenAddr
             interfaceName:(NSString *)interfaceName
                completion:(FLXAPICompletionBlock)completion {
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
    @"id" : @(tunnelId),
    @"name" : name,
    @"inNodeId" : @(inNodeId),
    @"outNodeId" : @(outNodeId),
    @"type" : @(type),
    @"flow" : @(flow),
    @"protocol" : protocol ?: @"tcp+udp",
    @"trafficRatio" : @(trafficRatio)
  }];

  if (tcpListenAddr) {
    params[@"tcpListenAddr"] = tcpListenAddr;
  }
  if (udpListenAddr) {
    params[@"udpListenAddr"] = udpListenAddr;
  }
  if (interfaceName) {
    params[@"interfaceName"] = interfaceName;
  }

  [self POST:@"/tunnel/update" parameters:params completion:completion];
}

- (void)deleteTunnelWithId:(NSInteger)tunnelId
                completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/tunnel/delete"
      parameters:@{@"id" : @(tunnelId)}
      completion:completion];
}

- (void)diagnoseTunnelWithId:(NSInteger)tunnelId
                  completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/tunnel/diagnose"
      parameters:@{@"tunnelId" : @(tunnelId)}
      completion:completion];
}

- (void)assignUserTunnelWithUserId:(NSInteger)userId
                          tunnelId:(NSInteger)tunnelId
                              flow:(NSInteger)flow
                               num:(NSInteger)num
                           expTime:(NSString *)expTime
                     flowResetTime:(NSInteger)flowResetTime
                        completion:(FLXAPICompletionBlock)completion {
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
    @"userId" : @(userId),
    @"tunnelId" : @(tunnelId),
    @"flow" : @(flow),
    @"num" : @(num),
    @"flowResetTime" : @(flowResetTime)
  }];

  if (expTime && expTime.length > 0) {
    params[@"expTime"] = expTime;
  }

  [self POST:@"/tunnel/user/assign" parameters:params completion:completion];
}

- (void)getUserTunnelListWithUserId:(NSInteger)userId
                         completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/tunnel/user/list"
      parameters:@{@"userId" : @(userId)}
      completion:completion];
}

- (void)removeUserTunnelWithId:(NSInteger)userTunnelId
                    completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/tunnel/user/remove"
      parameters:@{@"id" : @(userTunnelId)}
      completion:completion];
}

- (void)updateUserTunnelWithId:(NSInteger)userTunnelId
                          flow:(NSInteger)flow
                           num:(NSInteger)num
                       expTime:(NSString *)expTime
                 flowResetTime:(NSInteger)flowResetTime
                    completion:(FLXAPICompletionBlock)completion {
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
    @"id" : @(userTunnelId),
    @"flow" : @(flow),
    @"num" : @(num),
    @"flowResetTime" : @(flowResetTime)
  }];

  if (expTime && expTime.length > 0) {
    params[@"expTime"] = expTime;
  }

  [self POST:@"/tunnel/user/update" parameters:params completion:completion];
}

#pragma mark - 节点相关 API

- (void)getAllNodesWithCompletion:(FLXAPICompletionBlock)completion {
  [self POST:@"/node/list" parameters:nil completion:completion];
}

- (void)createNodeWithName:(NSString *)name
                    secret:(NSString *)secret
                        ip:(NSString *)ip
                  serverIp:(NSString *)serverIp
                   portSta:(NSInteger)portSta
                   portEnd:(NSInteger)portEnd
                      http:(NSInteger)http
                       tls:(NSInteger)tls
                     socks:(NSInteger)socks
                completion:(FLXAPICompletionBlock)completion {
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
    @"name" : name,
    @"secret" : secret,
    @"ip" : ip,
    @"portSta" : @(portSta),
    @"portEnd" : @(portEnd),
    @"http" : @(http),
    @"tls" : @(tls),
    @"socks" : @(socks)
  }];

  if (serverIp && serverIp.length > 0) {
    params[@"serverIp"] = serverIp;
  }

  [self POST:@"/node/create" parameters:params completion:completion];
}

- (void)updateNodeWithId:(NSInteger)nodeId
                    name:(NSString *)name
                  secret:(NSString *)secret
                      ip:(NSString *)ip
                serverIp:(NSString *)serverIp
                 portSta:(NSInteger)portSta
                 portEnd:(NSInteger)portEnd
                    http:(NSInteger)http
                     tls:(NSInteger)tls
                   socks:(NSInteger)socks
              completion:(FLXAPICompletionBlock)completion {
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
    @"id" : @(nodeId),
    @"name" : name,
    @"secret" : secret,
    @"ip" : ip,
    @"portSta" : @(portSta),
    @"portEnd" : @(portEnd),
    @"http" : @(http),
    @"tls" : @(tls),
    @"socks" : @(socks)
  }];

  if (serverIp) {
    params[@"serverIp"] = serverIp;
  }

  [self POST:@"/node/update" parameters:params completion:completion];
}

- (void)deleteNodeWithId:(NSInteger)nodeId
              completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/node/delete"
      parameters:@{@"id" : @(nodeId)}
      completion:completion];
}

- (void)getInstallCommandForNodeId:(NSInteger)nodeId
                        completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/node/install"
      parameters:@{@"id" : @(nodeId)}
      completion:completion];
}

- (void)checkNodeStatusWithNodeId:(NSInteger)nodeId
                       completion:(FLXAPICompletionBlock)completion {
  NSDictionary *params = nodeId > 0 ? @{@"nodeId" : @(nodeId)} : nil;
  [self POST:@"/node/check-status" parameters:params completion:completion];
}

#pragma mark - 用户管理 API

- (void)getAllUsersWithCompletion:(FLXAPICompletionBlock)completion {
  [self POST:@"/user/list" parameters:nil completion:completion];
}

- (void)createUserWithUsername:(NSString *)username
                      password:(NSString *)password
                          flow:(NSInteger)flow
                           num:(NSInteger)num
                       expTime:(NSString *)expTime
                 flowResetTime:(NSInteger)flowResetTime
                        status:(NSInteger)status
                    completion:(FLXAPICompletionBlock)completion {
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
    @"username" : username,
    @"password" : password,
    @"flow" : @(flow),
    @"num" : @(num),
    @"flowResetTime" : @(flowResetTime),
    @"status" : @(status)
  }];

  if (expTime && expTime.length > 0) {
    params[@"expTime"] = expTime;
  }

  [self POST:@"/user/create" parameters:params completion:completion];
}

- (void)updateUserWithId:(NSInteger)userId
                username:(NSString *)username
                password:(NSString *)password
                    flow:(NSInteger)flow
                     num:(NSInteger)num
                 expTime:(NSString *)expTime
           flowResetTime:(NSInteger)flowResetTime
                  status:(NSInteger)status
              completion:(FLXAPICompletionBlock)completion {
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
    @"id" : @(userId),
    @"username" : username,
    @"flow" : @(flow),
    @"num" : @(num),
    @"flowResetTime" : @(flowResetTime),
    @"status" : @(status)
  }];

  if (password && password.length > 0) {
    params[@"password"] = password;
  }

  if (expTime && expTime.length > 0) {
    params[@"expTime"] = expTime;
  }

  [self POST:@"/user/update" parameters:params completion:completion];
}

- (void)deleteUserWithId:(NSInteger)userId
              completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/user/delete"
      parameters:@{@"id" : @(userId)}
      completion:completion];
}

- (void)resetUserFlowWithId:(NSInteger)userId
                 completion:(FLXAPICompletionBlock)completion {
  [self POST:@"/user/reset"
      parameters:@{@"id" : @(userId)}
      completion:completion];
}

@end
