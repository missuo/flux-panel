//
//  FLXWebLoginViewController.h
//  Flux
//
//  WebView 登录控制器 - 用于 Turnstile 验证码场景
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FLXWebLoginDelegate <NSObject>

// 登录成功回调
- (void)webLoginDidSucceedWithToken:(NSString *)token
                             roleId:(NSInteger)roleId
                           userName:(NSString *)userName
              requirePasswordChange:(BOOL)requirePasswordChange;

// 登录取消回调
- (void)webLoginDidCancel;

@end

@interface FLXWebLoginViewController : UIViewController

@property(nonatomic, weak) id<FLXWebLoginDelegate> delegate;
@property(nonatomic, copy) NSString *serverURL;

- (instancetype)initWithServerURL:(NSString *)serverURL;

@end

NS_ASSUME_NONNULL_END
