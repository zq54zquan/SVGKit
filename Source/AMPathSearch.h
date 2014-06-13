//
//  AMPathSearch.h
//  Metro
//
//  Created by ZhouQuan on 14-6-5.
//  Copyright (c) 2014年 iOSTeam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SVGKParserSVG.h"
@interface AMPathSearch : NSObject
-(instancetype)initWithLines:(NSArray *)lines;
-(SVGLine *)linesFromPoint:(CGPoint)source toDestinate:(CGPoint)des;
-(float)distanceBetweenPoint:(CGPoint)p1 point:(CGPoint)p2;
@end
