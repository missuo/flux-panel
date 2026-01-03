//
//  FLXUserEditViewController.h
//  Flux
//
//  用户编辑视图控制器 (管理员)
//

#import <UIKit/UIKit.h>

@class FLXUser;

NS_ASSUME_NONNULL_BEGIN

typedef void (^FLXUserEditCompletionHandler)(void);

@interface FLXUserEditViewController : UIViewController

@property(nonatomic, copy, nullable)
    FLXUserEditCompletionHandler completionHandler;

// 用于创建新用户
- (instancetype)init;

// 用于编辑现有用户
- (instancetype)initWithUser:(FLXUser *)user;

@end

NS_ASSUME_NONNULL_END
