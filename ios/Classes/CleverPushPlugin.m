#import "CleverPushPlugin.h"
#import <objc/runtime.h>

@interface CleverPushPlugin ()

@property (strong, nonatomic) FlutterMethodChannel *channel;
@property (strong, nonatomic) CPNotificationOpenedResult *coldStartOpenResult;
@property (strong, nonatomic) NSDictionary *launchOptions;
@property (nonatomic) BOOL hasNotificationOpenedHandler;

@end

@implementation CleverPushPlugin

+ (instancetype)sharedInstance {
    static CleverPushPlugin *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [CleverPushPlugin new];
    });
    return sharedInstance;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    CleverPushPlugin.sharedInstance.hasNotificationOpenedHandler = NO;

    CleverPushPlugin.sharedInstance.channel = [FlutterMethodChannel
                                               methodChannelWithName:@"CleverPush"
                                               binaryMessenger:[registrar messenger]];

    [registrar addMethodCallDelegate:CleverPushPlugin.sharedInstance channel:CleverPushPlugin.sharedInstance.channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSLog(@"CleverPush Flutter: handleMethodCall %@", call.method);
    if ([@"CleverPush#init" isEqualToString:call.method])
        [self initCleverPush:call withResult:result];
    else if ([@"CleverPush#subscribe" isEqualToString:call.method])
        [self subscribe:call withResult:result];
    else if ([@"CleverPush#unsubscribe" isEqualToString:call.method])
        [self unsubscribe:call withResult:result];
    else if ([@"CleverPush#isSubscribed" isEqualToString:call.method])
        result([NSNumber numberWithBool:CleverPush.isSubscribed]);
    else if ([@"CleverPush#showTopicsDialog" isEqualToString:call.method])
        [self showTopicsDialog:call withResult:result];
    else if ([@"CleverPush#getNotifications" isEqualToString:call.method])
        [self getNotifications:call withResult:result];
    else if ([@"CleverPush#getNotificationsWithApi" isEqualToString:call.method])
        [self getNotificationsWithApi:call withResult:result];
    else if ([@"CleverPush#getSubscriptionTopics" isEqualToString:call.method])
        [self getSubscriptionTopics:call withResult:result];
    else if ([@"CleverPush#setSubscriptionTopics" isEqualToString:call.method])
        [self setSubscriptionTopics:call withResult:result];
    else if ([@"CleverPush#getAvailableTopics" isEqualToString:call.method])
        [self getAvailableTopics:call withResult:result];
    else if ([@"CleverPush#getSubscriptionTags" isEqualToString:call.method])
        [self getSubscriptionTags:call withResult:result];
    else if ([@"CleverPush#addSubscriptionTag" isEqualToString:call.method])
        [self addSubscriptionTag:call withResult:result];
    else if ([@"CleverPush#removeSubscriptionTag" isEqualToString:call.method])
        [self removeSubscriptionTag:call withResult:result];
    else if ([@"CleverPush#getAvailableTags" isEqualToString:call.method])
        [self getAvailableTags:call withResult:result];
    else if ([@"CleverPush#getSubscriptionAttributes" isEqualToString:call.method])
        [self getSubscriptionAttributes:call withResult:result];
    else if ([@"CleverPush#getSubscriptionAttribute" isEqualToString:call.method])
        [self getSubscriptionAttribute:call withResult:result];
    else if ([@"CleverPush#setSubscriptionAttribute" isEqualToString:call.method])
        [self setSubscriptionAttribute:call withResult:result];
    else if ([@"CleverPush#initNotificationOpenedHandlerParams" isEqualToString:call.method])
        [self initNotificationOpenedHandlerParams];
    else
        result(FlutterMethodNotImplemented);
}

- (void)initCleverPush:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [CleverPush initWithLaunchOptions:self.launchOptions channelId:call.arguments[@"channelId"]
           handleNotificationReceived:^(CPNotificationReceivedResult *result) {
        [self handleNotificationReceived:result];
    } handleNotificationOpened:^(CPNotificationOpenedResult *result) {
        if (!self.hasNotificationOpenedHandler) {
          self.coldStartOpenResult = result;
        } else {
          [self handleNotificationOpened:result];
        }
    } handleSubscribed:^(NSString *subscriptionId) {
        [self handleSubscribed:subscriptionId];
    } autoRegister:call.arguments[@"autoRegister"]];

    result(nil);
}

- (void)subscribe:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [CleverPush subscribe];
    result(nil);
}

- (void)unsubscribe:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [CleverPush unsubscribe];
    result(nil);
}

- (void)isSubscribed:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    bool subscribed = [CleverPush isSubscribed];
    result([NSNumber numberWithBool:subscribed]);
}

- (void)showTopicsDialog:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [CleverPush showTopicsDialog];
    result(nil);
}

- (void)getNotifications:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSMutableArray *storedNotifications = [NSMutableArray arrayWithArray:[CleverPush getNotifications]];
    result(storedNotifications);
}

- (void)getNotificationsWithApi:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSMutableArray *remoteNotifications = [NSMutableArray new];
    [CleverPush getNotifications:call.arguments[@"combineWithApi"] callback:^(NSArray* Notifications) {
        [Notifications enumerateObjectsWithOptions: NSEnumerationConcurrent usingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dict = [self dictionaryWithPropertiesOfObject: obj];
            [remoteNotifications addObject:dict];
        }];
        result(remoteNotifications);
    }];
}

- (void)getSubscriptionTopics:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSMutableArray *topicIds = [CleverPush getSubscriptionTopics];
    NSMutableArray *list = [NSMutableArray arrayWithArray:topicIds];
    result(list);
}

- (void)setSubscriptionTopics:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [CleverPush setSubscriptionTopics:call.arguments[@"topics"]];
    result(nil);
}

- (void)getAvailableTopics:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [CleverPush getAvailableTopics:^(NSArray* channelTopics_) {
        NSMutableArray *availableTopics = [NSMutableArray new];
        [channelTopics_ enumerateObjectsWithOptions: NSEnumerationConcurrent usingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dict = [self dictionaryWithPropertiesOfObject: obj];
            [availableTopics addObject:dict];
        }];
        result(availableTopics);
    }];
}

- (void)getSubscriptionTags:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSMutableArray *tagIds = [CleverPush getSubscriptionTags];
    NSMutableArray *list = [NSMutableArray arrayWithArray:tagIds];
    result(list);
}

- (void)addSubscriptionTag:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [CleverPush addSubscriptionTag:call.arguments[@"id"]];
    result(nil);
}

- (void)removeSubscriptionTag:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [CleverPush removeSubscriptionTag:call.arguments[@"id"]];
    result(nil);
}

- (void)getAvailableTags:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [CleverPush getAvailableTags:^(NSArray* channelTags_) {
        NSMutableArray *availableTags = [NSMutableArray new];
        [channelTags_ enumerateObjectsWithOptions: NSEnumerationConcurrent usingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dict = [self dictionaryWithPropertiesOfObject: obj];
            [availableTags addObject:dict];
        }];
        result(availableTags);
    }];
}

- (void)getSubscriptionAttributes:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *attributes = [CleverPush getSubscriptionAttributes];
    result(attributes);
}

- (void)setSubscriptionAttribute:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [CleverPush setSubscriptionAttribute:call.arguments[@"id"] value:call.arguments[@"value"]];
    result(nil);
}

- (void)getSubscriptionAttribute:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    result([CleverPush getSubscriptionAttribute:call.arguments[@"id"]]);
}

- (void)getAvailableAttributes:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [CleverPush getAvailableAttributes:^(NSDictionary* attributes_) {
        NSMutableArray *availableAttributes = [NSMutableArray new];
        [attributes_ enumerateKeysAndObjectsUsingBlock: ^(NSString* key, NSString* value, BOOL *stop) {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            [dict setObject:key forKey:@"id"];
            [dict setObject:value forKey:@"value"];
            [availableAttributes addObject:dict];
        }];
        result(availableAttributes);
    }];
}

- (void)initNotificationOpenedHandlerParams {
    self.hasNotificationOpenedHandler = YES;
    if (self.coldStartOpenResult) {
        [self handleNotificationOpened:self.coldStartOpenResult];
        self.coldStartOpenResult = nil;
    }
}

- (void)handleSubscribed:(NSString *)result {
    NSMutableDictionary *resultDict = [NSMutableDictionary new];
    resultDict[@"subscriptionId"] = result;
    [self.channel invokeMethod:@"CleverPush#handleSubscribed" arguments:resultDict];
}

- (void)handleNotificationReceived:(CPNotificationReceivedResult *)result {
    NSMutableDictionary *resultDict = [NSMutableDictionary new];
    resultDict[@"notification"] = [self dictionaryWithPropertiesOfObject:result.notification];
    [self.channel invokeMethod:@"CleverPush#handleNotificationReceived" arguments:resultDict];
}

- (void)handleNotificationOpened:(CPNotificationOpenedResult *)result {
    NSMutableDictionary *resultDict = [NSMutableDictionary new];
    resultDict[@"notification"] = [self dictionaryWithPropertiesOfObject:result.notification];
    [self.channel invokeMethod:@"CleverPush#handleNotificationOpened" arguments:resultDict];
}

- (NSDictionary *) dictionaryWithPropertiesOfObject:(id)obj {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        if ([obj valueForKey:key] != nil) {
            if ([[obj valueForKey:key] isKindOfClass:[NSDate class]]) {
                NSString *convertedDateString = [NSString stringWithFormat:@"%@", [obj valueForKey:key]];
                [dict setObject:convertedDateString forKey:key];
            } else {
                [dict setObject:[obj valueForKey:key] forKey:key];
            }
        }
    }
    free(properties);
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
