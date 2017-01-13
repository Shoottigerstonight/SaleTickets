//
//  Ticket.h
//  SaleTickets
//
//  Created by 侯云祥 on 2017/1/13.
//  Copyright © 2017年 今晚打老虎. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Ticket : NSObject


/**
 创建唯一的，线程访问安全的Ticket对象

 @return Ticket对象
 */
+ (Ticket *)sharedTicket;


// 在多线程应用中，所有被抢夺资源的属性需要设置为原子属性
// 系统会在多线程抢夺时，保证该属性有且仅有一个线程能够访问
// 注意：使用atomic属性，会降低系统性能
// 另外，atomic属性，必须与@syncronized（同步锁）一起使用
/** 剩余的票数   */
@property (atomic , assign) NSInteger tickets;


@end
