//
//  FLXModels.h
//  Flux
//
//  数据模型定义
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 用户信息模型

@interface FLXUserInfo : NSObject

@property(nonatomic, assign) NSInteger flow;            // 总流量 (GB)
@property(nonatomic, assign) NSInteger inFlow;          // 入站流量 (bytes)
@property(nonatomic, assign) NSInteger outFlow;         // 出站流量 (bytes)
@property(nonatomic, assign) NSInteger num;             // 转发配额
@property(nonatomic, assign) NSInteger usedNum;         // 已用转发数
@property(nonatomic, copy, nullable) NSString *expTime; // 到期时间
@property(nonatomic, assign)
    NSInteger flowResetTime; // 流量重置日期 (每月第几天)

- (instancetype)initWithDictionary:(NSDictionary *)dict;

// 便捷方法
- (NSString *)formattedTotalFlow;
- (NSString *)formattedUsedFlow;
- (CGFloat)usagePercentage;
- (NSString *)expirationStatus;
- (BOOL)isUnlimitedFlow;
- (BOOL)isUnlimitedNum;

@end

#pragma mark - 用户隧道权限模型

@interface FLXUserTunnel : NSObject

@property(nonatomic, assign) NSInteger tunnelId;
@property(nonatomic, copy) NSString *tunnelName;
@property(nonatomic, assign) NSInteger flow;    // 流量配额 (GB)
@property(nonatomic, assign) NSInteger inFlow;  // 已用入站流量 (bytes)
@property(nonatomic, assign) NSInteger outFlow; // 已用出站流量 (bytes)
@property(nonatomic, assign) NSInteger num;     // 转发配额
@property(nonatomic, copy, nullable) NSString *expTime;
@property(nonatomic, assign) NSInteger flowResetTime;
@property(nonatomic, assign) NSInteger tunnelFlow; // 1: 单向计费, 2: 双向计费

- (instancetype)initWithDictionary:(NSDictionary *)dict;

// 便捷方法
- (NSString *)formattedTotalFlow;
- (NSString *)formattedUsedFlow;
- (CGFloat)usagePercentage;
- (NSString *)billingTypeString;
- (BOOL)isUnlimitedFlow;
- (BOOL)isUnlimitedNum;

@end

#pragma mark - 转发模型

@interface FLXForward : NSObject

@property(nonatomic, assign) NSInteger forwardId;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) NSInteger tunnelId;
@property(nonatomic, copy) NSString *tunnelName;
@property(nonatomic, copy) NSString *inIP;
@property(nonatomic, assign) NSInteger inPort;
@property(nonatomic, copy) NSString *remoteAddr;
@property(nonatomic, copy, nullable) NSString *interfaceName;
@property(nonatomic, copy) NSString *strategy;
@property(nonatomic, assign) NSInteger status; // 0: 暂停, 1: 运行
@property(nonatomic, assign) NSInteger inFlow;
@property(nonatomic, assign) NSInteger outFlow;
@property(nonatomic, copy, nullable) NSString *createdTime;
@property(nonatomic, copy, nullable) NSString *userName;
@property(nonatomic, assign) NSInteger userId;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

// 便捷方法
- (BOOL)isRunning;
- (NSString *)formattedInAddress;
- (NSString *)formattedRemoteAddress;
- (NSString *)formattedTotalFlow;
- (NSArray<NSString *> *)inIPList;
- (NSArray<NSString *> *)remoteAddressList;

@end

#pragma mark - 隧道模型

@interface FLXTunnel : NSObject

@property(nonatomic, assign) NSInteger tunnelId;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) NSInteger inNodeId;
@property(nonatomic, assign) NSInteger outNodeId;
@property(nonatomic, copy) NSString *inIP;
@property(nonatomic, copy) NSString *outIP;
@property(nonatomic, assign) NSInteger type;   // 1: 端口转发, 2: 隧道转发
@property(nonatomic, assign) NSInteger flow;   // 1: 单向, 2: 双向
@property(nonatomic, copy) NSString *protocol; // tcp, udp, tcp+udp
@property(nonatomic, assign) CGFloat trafficRatio;
@property(nonatomic, copy, nullable) NSString *tcpListenAddr;
@property(nonatomic, copy, nullable) NSString *udpListenAddr;
@property(nonatomic, copy, nullable) NSString *interfaceName;
@property(nonatomic, assign) NSInteger inNodePortSta;
@property(nonatomic, assign) NSInteger inNodePortEnd;
@property(nonatomic, copy, nullable) NSString *inNodeName;
@property(nonatomic, copy, nullable) NSString *outNodeName;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

// 验证端口是否在允许范围内
- (BOOL)isPortValid:(NSInteger)port;
- (NSString *)portRangeDescription;
- (NSString *)typeString;
- (NSString *)flowString;

@end

#pragma mark - 节点模型

@interface FLXNode : NSObject

@property(nonatomic, assign) NSInteger nodeId;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *secret;
@property(nonatomic, copy) NSString *ip;
@property(nonatomic, copy, nullable) NSString *serverIp;
@property(nonatomic, copy, nullable) NSString *version;
@property(nonatomic, assign) NSInteger portSta;
@property(nonatomic, assign) NSInteger portEnd;
@property(nonatomic, assign) NSInteger http;
@property(nonatomic, assign) NSInteger tls;
@property(nonatomic, assign) NSInteger socks;
@property(nonatomic, assign) BOOL isOnline;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

// 便捷方法
- (NSString *)portRangeDescription;
- (NSString *)statusString;

@end

#pragma mark - 用户模型 (管理员)

@interface FLXUser : NSObject

@property(nonatomic, assign) NSInteger userId;
@property(nonatomic, copy) NSString *username;
@property(nonatomic, assign) NSInteger roleId;  // 0: 管理员, 1: 普通用户
@property(nonatomic, assign) NSInteger flow;    // 总流量 (GB)
@property(nonatomic, assign) NSInteger inFlow;  // 已用入站流量 (bytes)
@property(nonatomic, assign) NSInteger outFlow; // 已用出站流量 (bytes)
@property(nonatomic, assign) NSInteger num;     // 转发配额
@property(nonatomic, copy, nullable) NSString *expTime;
@property(nonatomic, assign) NSInteger flowResetTime;
@property(nonatomic, assign) NSInteger status; // 0: 禁用, 1: 启用

- (instancetype)initWithDictionary:(NSDictionary *)dict;

// 便捷方法
- (BOOL)isAdmin;
- (NSString *)formattedFlow;
- (NSString *)formattedUsedFlow;
- (NSString *)roleString;
- (BOOL)isUnlimitedFlow;
- (BOOL)isUnlimitedNum;

@end

#pragma mark - 流量统计模型

@interface FLXStatisticsFlow : NSObject

@property(nonatomic, assign) NSInteger flowId;
@property(nonatomic, assign) NSInteger userId;
@property(nonatomic, assign) NSInteger flow;
@property(nonatomic, assign) NSInteger totalFlow;
@property(nonatomic, copy) NSString *time;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
