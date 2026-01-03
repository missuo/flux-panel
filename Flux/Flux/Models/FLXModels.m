//
//  FLXModels.m
//  Flux
//
//  数据模型实现
//

#import "FLXModels.h"

#pragma mark - 常量定义

static const NSInteger kUnlimitedValue = 99999;

#pragma mark - 辅助函数

static NSString *formatBytes(NSInteger bytes) {
  if (bytes == 0)
    return @"0 B";
  if (bytes < 1024)
    return [NSString stringWithFormat:@"%ld B", (long)bytes];
  if (bytes < 1024 * 1024)
    return [NSString stringWithFormat:@"%.2f KB", bytes / 1024.0];
  if (bytes < 1024 * 1024 * 1024)
    return [NSString stringWithFormat:@"%.2f MB", bytes / (1024.0 * 1024.0)];
  return [NSString
      stringWithFormat:@"%.2f GB", bytes / (1024.0 * 1024.0 * 1024.0)];
}

#pragma mark - FLXUserInfo

@implementation FLXUserInfo

- (instancetype)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _flow = [dict[@"flow"] integerValue];
    _inFlow = [dict[@"inFlow"] integerValue];
    _outFlow = [dict[@"outFlow"] integerValue];
    _num = [dict[@"num"] integerValue];
    _usedNum = [dict[@"usedNum"] integerValue];
    _expTime = dict[@"expTime"];
    _flowResetTime = [dict[@"flowResetTime"] integerValue];
  }
  return self;
}

- (NSString *)formattedTotalFlow {
  if (self.flow == kUnlimitedValue) {
    return @"无限制";
  }
  return [NSString stringWithFormat:@"%ld GB", (long)self.flow];
}

- (NSString *)formattedUsedFlow {
  NSInteger totalUsed = self.inFlow + self.outFlow;
  return formatBytes(totalUsed);
}

- (CGFloat)usagePercentage {
  if (self.flow == kUnlimitedValue || self.flow == 0) {
    return 0;
  }
  NSInteger totalUsed = self.inFlow + self.outFlow;
  NSInteger totalLimit = self.flow * 1024 * 1024 * 1024;
  return MIN((CGFloat)totalUsed / totalLimit * 100.0, 100.0);
}

- (NSString *)expirationStatus {
  if (!self.expTime || self.expTime.length == 0) {
    return @"永久";
  }

  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
  formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

  NSDate *expDate = [formatter dateFromString:self.expTime];
  if (!expDate) {
    // 尝试其他格式
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    expDate = [formatter dateFromString:self.expTime];
  }

  if (!expDate) {
    return @"无效";
  }

  NSDate *now = [NSDate date];
  if ([expDate compare:now] == NSOrderedAscending) {
    return @"已过期";
  }

  NSTimeInterval diff = [expDate timeIntervalSinceDate:now];
  NSInteger days = (NSInteger)(diff / (24 * 60 * 60));

  if (days <= 0) {
    return @"今日过期";
  } else if (days == 1) {
    return @"明天过期";
  } else {
    return [NSString stringWithFormat:@"%ld天后过期", (long)days];
  }
}

- (BOOL)isUnlimitedFlow {
  return self.flow == kUnlimitedValue;
}

- (BOOL)isUnlimitedNum {
  return self.num == kUnlimitedValue;
}

@end

#pragma mark - FLXUserTunnel

@implementation FLXUserTunnel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _tunnelId = [dict[@"tunnelId"] integerValue];
    _tunnelName = dict[@"tunnelName"] ?: @"";
    _flow = [dict[@"flow"] integerValue];
    _inFlow = [dict[@"inFlow"] integerValue];
    _outFlow = [dict[@"outFlow"] integerValue];
    _num = [dict[@"num"] integerValue];
    _expTime = dict[@"expTime"];
    _flowResetTime = [dict[@"flowResetTime"] integerValue];
    _tunnelFlow = [dict[@"tunnelFlow"] integerValue];
  }
  return self;
}

- (NSString *)formattedTotalFlow {
  if (self.flow == kUnlimitedValue) {
    return @"无限制";
  }
  return [NSString stringWithFormat:@"%ld GB", (long)self.flow];
}

- (NSString *)formattedUsedFlow {
  NSInteger totalUsed = self.inFlow + self.outFlow;
  return formatBytes(totalUsed);
}

- (CGFloat)usagePercentage {
  if (self.flow == kUnlimitedValue || self.flow == 0) {
    return 0;
  }
  NSInteger totalUsed = self.inFlow + self.outFlow;
  NSInteger totalLimit = self.flow * 1024 * 1024 * 1024;
  return MIN((CGFloat)totalUsed / totalLimit * 100.0, 100.0);
}

- (NSString *)billingTypeString {
  return self.tunnelFlow == 1 ? @"单向计费" : @"双向计费";
}

- (BOOL)isUnlimitedFlow {
  return self.flow == kUnlimitedValue;
}

- (BOOL)isUnlimitedNum {
  return self.num == kUnlimitedValue;
}

@end

#pragma mark - FLXForward

@implementation FLXForward

- (instancetype)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _forwardId = [dict[@"id"] integerValue];
    _name = dict[@"name"] ?: @"";
    _tunnelId = [dict[@"tunnelId"] integerValue];
    _tunnelName = dict[@"tunnelName"] ?: @"";
    _inIP = dict[@"inIp"] ?: @"";
    _inPort = [dict[@"inPort"] integerValue];
    _remoteAddr = dict[@"remoteAddr"] ?: @"";
    _interfaceName = dict[@"interfaceName"];
    _strategy = dict[@"strategy"] ?: @"fifo";
    _status = [dict[@"status"] integerValue];
    _inFlow = [dict[@"inFlow"] integerValue];
    _outFlow = [dict[@"outFlow"] integerValue];
    _createdTime = dict[@"createdTime"];
    _userName = dict[@"userName"];
    _userId = [dict[@"userId"] integerValue];
  }
  return self;
}

- (BOOL)isRunning {
  return self.status == 1;
}

- (NSString *)formattedInAddress {
  if (!self.inIP || self.inIP.length == 0 || self.inPort == 0) {
    return @"";
  }

  NSArray *ips = [self inIPList];
  if (ips.count == 0)
    return @"";

  if (ips.count == 1) {
    NSString *ip = ips[0];
    // 检查是否是 IPv6 地址
    if ([ip containsString:@":"] && ![ip hasPrefix:@"["]) {
      return [NSString stringWithFormat:@"[%@]:%ld", ip, (long)self.inPort];
    } else {
      return [NSString stringWithFormat:@"%@:%ld", ip, (long)self.inPort];
    }
  }

  NSString *firstIP = ips[0];
  NSString *formattedFirstIP;
  if ([firstIP containsString:@":"] && ![firstIP hasPrefix:@"["]) {
    formattedFirstIP = [NSString stringWithFormat:@"[%@]", firstIP];
  } else {
    formattedFirstIP = firstIP;
  }

  return [NSString stringWithFormat:@"%@:%ld (+%lu)", formattedFirstIP,
                                    (long)self.inPort,
                                    (unsigned long)(ips.count - 1)];
}

- (NSString *)formattedRemoteAddress {
  if (!self.remoteAddr || self.remoteAddr.length == 0) {
    return @"";
  }

  NSArray *addresses = [self remoteAddressList];
  if (addresses.count == 0)
    return @"";

  if (addresses.count == 1) {
    return addresses[0];
  }

  return [NSString stringWithFormat:@"%@ (+%lu)", addresses[0],
                                    (unsigned long)(addresses.count - 1)];
}

- (NSString *)formattedTotalFlow {
  NSInteger totalFlow = self.inFlow + self.outFlow;
  return formatBytes(totalFlow);
}

- (NSArray<NSString *> *)inIPList {
  if (!self.inIP || self.inIP.length == 0)
    return @[];

  NSMutableArray *result = [NSMutableArray array];
  NSArray *ips = [self.inIP componentsSeparatedByString:@","];
  for (NSString *ip in ips) {
    NSString *trimmed =
        [ip stringByTrimmingCharactersInSet:[NSCharacterSet
                                                whitespaceCharacterSet]];
    if (trimmed.length > 0) {
      [result addObject:trimmed];
    }
  }
  return [result copy];
}

- (NSArray<NSString *> *)remoteAddressList {
  if (!self.remoteAddr || self.remoteAddr.length == 0)
    return @[];

  NSMutableArray *result = [NSMutableArray array];
  NSArray *addresses = [self.remoteAddr componentsSeparatedByString:@","];
  for (NSString *addr in addresses) {
    NSString *trimmed =
        [addr stringByTrimmingCharactersInSet:[NSCharacterSet
                                                  whitespaceCharacterSet]];
    if (trimmed.length > 0) {
      [result addObject:trimmed];
    }
  }
  return [result copy];
}

@end

#pragma mark - FLXTunnel

@implementation FLXTunnel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _tunnelId = [dict[@"id"] integerValue];
    _name = dict[@"name"] ?: @"";
    _inNodePortSta = [dict[@"inNodePortSta"] integerValue];
    _inNodePortEnd = [dict[@"inNodePortEnd"] integerValue];
  }
  return self;
}

- (BOOL)isPortValid:(NSInteger)port {
  if (self.inNodePortSta == 0 && self.inNodePortEnd == 0) {
    return YES; // 无端口限制
  }
  return port >= self.inNodePortSta && port <= self.inNodePortEnd;
}

- (NSString *)portRangeDescription {
  if (self.inNodePortSta == 0 && self.inNodePortEnd == 0) {
    return @"不限";
  }
  return [NSString stringWithFormat:@"%ld-%ld", (long)self.inNodePortSta,
                                    (long)self.inNodePortEnd];
}

@end

#pragma mark - FLXStatisticsFlow

@implementation FLXStatisticsFlow

- (instancetype)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _flowId = [dict[@"id"] integerValue];
    _userId = [dict[@"userId"] integerValue];
    _flow = [dict[@"flow"] integerValue];
    _totalFlow = [dict[@"totalFlow"] integerValue];
    _time = dict[@"time"] ?: @"";
  }
  return self;
}

@end
