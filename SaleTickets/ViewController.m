//
//  ViewController.m
//  SaleTickets
//
//  Created by 侯云祥 on 2017/1/13.
//  Copyright © 2017年 今晚打老虎. All rights reserved.
//

#import "ViewController.h"
#import "Ticket.h"

@interface ViewController ()

@property (weak, nonatomic) UITextView *textView;

@property (strong, nonatomic) NSOperationQueue *queue;
@end

@implementation ViewController
#pragma mark 追加多行文本框内容
- (void)appendContent:(NSString *)text
{
    // 1. 取出textView中的当前文本内容
    NSMutableString *str = [NSMutableString stringWithString:self.textView.text];
    
    // 2. 将text追加至textView内容的末尾
    [str appendFormat:@"%@\n", text];
    
    // 3. 使用追加后的文本，替换textView中的内容
    [self.textView setText:str];
    
    // 4. 将textView滚动至视图底部，保证能够及时看到新追加的内容
    NSRange range = NSMakeRange(str.length - 1, 1);
    [self.textView scrollRangeToVisible:range];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // 建立多行文本框
    UITextView *textView = [[UITextView alloc]initWithFrame:self.view.bounds];
    textView.font = [UIFont systemFontOfSize:22];
    // 不能编辑
    [textView setEditable:NO];
    [self.view addSubview:textView];
    self.textView = textView;
    
    // 预设可以卖30张票
    [Ticket sharedTicket].tickets = 30;
    
    // 实例化操作队列
    self.queue = [[NSOperationQueue alloc]init];
    
    // 开始卖票
    [self threadSales];
    [self operationSales];
    [self gcdSales];
}
#pragma mark - NSOperation卖票
- (void)operationSales
{
    // 提示，operation中没有群组任务完成通知功能
    // 两个线程卖票
    [self.queue setMaxConcurrentOperationCount:2];
    
    [self.queue addOperationWithBlock:^{
        [self operationSaleTicketWithName:@"op-1"];
    }];
    [self.queue addOperationWithBlock:^{
        [self operationSaleTicketWithName:@"op-2"];
    }];
    [self.queue addOperationWithBlock:^{
        [self operationSaleTicketWithName:@"op-3"];
    }];
}
- (void)operationSaleTicketWithName:(NSString *)name
{
    while (YES) {
        // 同步锁synchronized要锁的范围，对被抢夺资源修改/读取的代码部分
        @synchronized(self) {
            // 判断是否还有票
            if ([Ticket sharedTicket].tickets > 0) {
                [Ticket sharedTicket].tickets--;
                
                // 提示，涉及到被抢夺资源的内容定义方面的操作，千万不要跨线程去处理
                NSString *str = [NSString stringWithFormat:@"剩余票数 %ld 线程名称 %@", (long)[Ticket sharedTicket].tickets, name];
                
                // 更新UI
                [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                    [self appendContent:str];
                }];
            } else {
                NSLog(@"卖票完成 %@ %@", name, [NSThread currentThread]);
                break;
            }
        }
        // 模拟卖票休息
        if ([name isEqualToString:@"op-1"]) {
            [NSThread sleepForTimeInterval:0.6f];
        } else {
            [NSThread sleepForTimeInterval:0.4f];
        }
    }
}

#pragma mark - NSThread卖票
- (void)threadSaleTicketWithName:(NSString *)name
{
    // 使用NSThread时，线程调用的方法千万要使用@autoreleasepool
    @autoreleasepool {
        while (YES) {
            @synchronized(self) {
                if ([Ticket sharedTicket].tickets > 0) {
                    [Ticket sharedTicket].tickets--;
                    
                    NSString *str = [NSString stringWithFormat:@"剩余票数 %ld 线程名称 %@", (long)[Ticket sharedTicket].tickets, name];
                    
                    // 更新UI
                    [self performSelectorOnMainThread:@selector(appendContent:) withObject:str waitUntilDone:YES];
                } else {
                    break;
                }
            }
            
            // 模拟休息
            if ([name isEqualToString:@"thread-1"]) {
                [NSThread sleepForTimeInterval:1.0f];
            } else {
                [NSThread sleepForTimeInterval:0.1f];
            }
        }
    }
}

- (void)threadSales
{
    [NSThread detachNewThreadSelector:@selector(threadSaleTicketWithName:) toTarget:self withObject:@"thread-1"];
    [NSThread detachNewThreadSelector:@selector(threadSaleTicketWithName:) toTarget:self withObject:@"thread-2"];
}
#pragma mark - GCD卖票
- (void)gcdSaleTicketWithName:(NSString *)name
{
    while (YES) {
        // 同步锁synchronized要锁的范围，对被抢夺资源修改/读取的代码部分
        @synchronized(self) {
            if ([Ticket sharedTicket].tickets > 0) {
                
                [Ticket sharedTicket].tickets--;
                
                // 提示内容
                NSString *str = [NSString stringWithFormat:@"剩余票数 %ld, 线程名称 %@", (long)[Ticket sharedTicket].tickets, name];
                
                // 更新界面
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self appendContent:str];
                });
            } else {
                break;
            }
        }
        
        // 模拟线程休眠
        if ([name isEqualToString:@"gcd-1"]) {
            [NSThread sleepForTimeInterval:1.0f];
        } else {
            [NSThread sleepForTimeInterval:0.2f];
        }
    }
}

- (void)gcdSales
{
    // 1) 创建全局队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // 2) 创建三个个异步任务分别卖票
    //    dispatch_async(queue, ^{
    //        [self gcdSaleTicketWithName:@"gcd-1"];
    //    });
    //    dispatch_async(queue, ^{
    //        [self gcdSaleTicketWithName:@"gcd-2"];
    //    });
    //    dispatch_async(queue, ^{
    //        [self gcdSaleTicketWithName:@"gcd-3"];
    //    });
    
    // 3. GCD中可以将一组相关联的操作，定义到一个群组中
    // 定义到群组中之后，当所有线程完成时，可以获得通知
    // 1) 定义群组
    dispatch_group_t group = dispatch_group_create();
    
    // 2） 定义群组的异步任务
    dispatch_group_async(group, queue, ^{
        [self gcdSaleTicketWithName:@"gcd-1"];
    });
    dispatch_group_async(group, queue, ^{
        [self gcdSaleTicketWithName:@"gcd-2"];
    });
    
    // 3) 群组任务完成通知
    dispatch_group_notify(group, queue, ^{
        NSLog(@"卖完了");
    });
}


@end
