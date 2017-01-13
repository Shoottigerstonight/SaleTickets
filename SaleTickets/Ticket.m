//
//  Ticket.m
//  SaleTickets
//
//  Created by 侯云祥 on 2017/1/13.
//  Copyright © 2017年 今晚打老虎. All rights reserved.
//

#import "Ticket.h"

@implementation Ticket

static Ticket *SharedInstance;

+ (Ticket *)sharedTicket
{
//    利用GCD的单一创建方法创建
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedInstance = [[Ticket alloc]init];
    });
    
    return SharedInstance;
}
@end
