//
//  BHNetReqManager.m
//  BlogDemo
//
//  Created by HanBin on 15/10/26.
//  Copyright © 2016年 BinHan. All rights reserved.
//
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "BHURLProtocol.h"
#import "BHCustomURLCache.h"

#ifdef DEBUG
    #define SERVERS_PREFIX   @"test_prefix"
#else
    #define SERVERS_PREFIX   @"product_prefix"
#endif

#define consumerKey @"iOS"

static AFHTTPSessionManager *manager;

@interface BHNetReqManager()

/**
 请求的api
 */
@property (nonatomic, copy) NSString *requestUrl;

/**
 请求类型
 */
@property (nonatomic, assign)  RequestType requestType;

/**
 请求数据类型
 */
@property (nonatomic, assign)  RequestSerializer requestSerializer;

/**
 响应数据数据类型
 */
@property (nonatomic, assign)  ResponseSerializer responseSerializer;

/**
 请求参数
 */
@property (nonatomic, copy)  id parameters;

- (instancetype)init __attribute__((unavailable("Disabled. Use +sharedInstance instead")));

@end

@implementation BHNetReqManager

- (BHNetReqManager* (^)(NSString *url))bh_requestUrl
{
    return ^BHNetReqManager* (NSString *url) {
        self.requestUrl = url;
        return self;
    };
}

- (BHNetReqManager* (^)(RequestType requestType))bh_requestType
{
    return ^BHNetReqManager* (RequestType requestType) {
        self.requestType = requestType;
        return self;
    };
}

- (BHNetReqManager* (^)(RequestSerializer serializer))bh_requestSerializer
{
    return ^BHNetReqManager* (RequestSerializer serializer) {
        self.requestSerializer = serializer;
        return self;
    };
}

- (BHNetReqManager* (^)(ResponseSerializer serializer))bh_responseSerializer
{
    return ^BHNetReqManager* (ResponseSerializer serializer) {
        self.responseSerializer = serializer;
        return self;
    };
}

- (BHNetReqManager* (^)(id parameters))bh_parameters
{
    return ^BHNetReqManager *(id parameters) {
        self.parameters = parameters;
        return self;
    };
}

/**
 *  获取BHNetReqManager单例并进行初始化设置
 *
 *  @return 返回BHNetReqManager
 */
+(instancetype)sharedManager
{
    static BHNetReqManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        [sharedManager resetConfigWithManager];
        //manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:SERVERS_PREFIX]];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        //        configuration.protocolClasses = @[[BHURLProtocol class]];
        manager = [[AFHTTPSessionManager manager] initWithSessionConfiguration:configuration];
        manager.requestSerializer.timeoutInterval = 10.f;
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"text/plain", nil];
        NSOperationQueue *operationQueue = manager.operationQueue;
        [manager.reachabilityManager setReachabilityStatusChangeBlock: ^(AFNetworkReachabilityStatus status) {
            switch (status)
            {
                case AFNetworkReachabilityStatusReachableViaWWAN:
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    [operationQueue setSuspended:NO];
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    [operationQueue setSuspended:YES];
                    break;
                default:
                    break;
            }
        }];
        [manager.reachabilityManager startMonitoring];
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
//        BHCustomURLCache *sharedCache = [BHCustomURLCache standardURLCache];
//        [NSURLCache setSharedURLCache:sharedCache];
    });
    return sharedManager;
}

/**
 *  请求方法/consumerKey/请求参数一起参数的加密运算，用于获取mac值
 *
 *  @param query  请求地址
 *  @param params 请求参数
 *
 *  @return 返回加密后的值，可与服务器端协商加密算法
 */
- (NSString *)sign
{
    NSString *sign = @"signTest";
    return sign;
}

-(void)setupRequestSerializerWithManager
{
    switch (self.requestSerializer)
    {
        case HTTPRequestSerializer:
            manager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        case JSONRequestSerializer:
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        case PropertyListRequestSerializer:
            manager.requestSerializer = [AFPropertyListRequestSerializer serializer];
            break;
        default:
            break;
    }
}

-(void)setupResponseSerializerWithManager
{
    switch (self.responseSerializer) {
        case HTTPResponseSerializer:
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        case JSONResponseSerializer:
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        case XMLParserResponseSerializer:
            manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        default:
            break;
    }
}

/**
 *  对请求头、设置
 *
 *  @return 返回AFHTTPSessionManager对象
 */
-(void)setupAFHTTPSessionManager
{
    [self setupRequestSerializerWithManager];
    [self setupResponseSerializerWithManager];
    [manager.requestSerializer setValue:consumerKey forHTTPHeaderField:@"consumerKey"];
    [manager.requestSerializer setValue:[self sign] forHTTPHeaderField:@"sign"];
    [manager.requestSerializer setValue:@"iOS" forHTTPHeaderField:@"channel"];
}

-(NSUInteger)startRequestWithCompleteHandler:(void (^)(id response, NSError *error))handler
{
    [self setupAFHTTPSessionManager];
    NSURLSessionDataTask *dataTask;
    switch (self.requestType)
    {
        case GET:
        {
            dataTask = [manager GET:self.requestUrl parameters:self.parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                handler(responseObject, nil);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                handler(nil, error);
            }];
            break;
        }
        case POST:
        {
            dataTask = [manager POST:self.requestUrl parameters:self.parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                 handler(responseObject, nil);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                handler(nil, error);
            }];
            break;
        }
        case PUT:
        {
            dataTask = [manager PUT:self.requestUrl parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                handler(responseObject, nil);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                handler(nil, error);
            }];
            break;
        }
        case DELETE:
        {
            dataTask = [manager DELETE:self.requestUrl parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                handler(responseObject, nil);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                handler(nil, error);
            }];
            break;
        }
        case PATCH:
        {
            dataTask = [manager PATCH:self.requestUrl parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                handler(responseObject, nil);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                handler(nil, error);
            }];
            break;
        }
        default:
            break;
    }
    [self resetConfigWithManager];
    if (dataTask)
    {
        return dataTask.taskIdentifier;
    }
    else
    {
        return -1;
    }
    //            注释掉的是缓存代码 当然缓存逻辑大部分时候跟业务关联性会强一些 不建议在这里处理
    //            NSURLSessionDataTask *task =  [manager GET:self.requestUrl parameters:self.parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    //                handler(responseObject, nil);
    //                NSData *data = [NSJSONSerialization dataWithJSONObject:responseObject options:0 error:nil];
    //                NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:task.response data:data];
    //                [[BHCustomURLCache standardURLCache] storeCachedResponse:cachedResponse forRequest:task.originalRequest];
    //            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    //                handler(nil, error);
    //            }];
    //            NSCachedURLResponse *reaponse = [[BHCustomURLCache standardURLCache] cachedResponseForRequest:task.originalRequest];
    //            if (reaponse)
    //            {
    //                handler(reaponse.data, nil);
    //                [task cancel];
    //            }
}

- (void)cancelDataTask:(NSUInteger)taskIdentifier
{
    [manager.dataTasks enumerateObjectsUsingBlock:^(NSURLSessionTask * task, NSUInteger idx, BOOL *stop) {
        if (task.taskIdentifier == taskIdentifier)
        {
            NSLog(@"取消loa数据 = %lu", (unsigned long)taskIdentifier);
            [task cancel];
            *stop = YES;
        }
    }];
}

/**
 *  恢复默认设置
 */
-(void)resetConfigWithManager
{
    self.requestUrl = nil;
    self.requestType = GET;
    self.requestSerializer = HTTPRequestSerializer;
    self.responseSerializer = JSONResponseSerializer;
    self.parameters = nil;
}

@end
