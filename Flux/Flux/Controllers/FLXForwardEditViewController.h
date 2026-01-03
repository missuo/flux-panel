//
//  FLXForwardEditViewController.h
//  Flux
//
//  转发编辑视图控制器
//

#import <UIKit/UIKit.h>

@class FLXTunnel;
@class FLXForward;

NS_ASSUME_NONNULL_BEGIN

typedef void (^FLXForwardEditCompletionHandler)(void);

@interface FLXForwardEditViewController : UIViewController

@property(nonatomic, copy, nullable)
    FLXForwardEditCompletionHandler completionHandler;

- (instancetype)initWithTunnels:(NSArray<FLXTunnel *> *)tunnels
                        forward:(FLXForward *_Nullable)forward;

@end

NS_ASSUME_NONNULL_END
