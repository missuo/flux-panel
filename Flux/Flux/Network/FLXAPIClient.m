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

@end
