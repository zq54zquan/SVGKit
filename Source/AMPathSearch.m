//
//  AMPathSearch.m
//  Metro
//
//  Created by ZhouQuan on 14-6-5.
//  Copyright (c) 2014年 iOSTeam. All rights reserved.
//

#import "AMPathSearch.h"

@interface AMPathSearch ()
@property (nonatomic, strong) NSArray *lines;
@end

@implementation AMPathSearch
-(instancetype)initWithLines:(NSArray *)lines{
    if (self = [super init]){
        _lines = lines;
    }
    return self;
    
}

-(SVGLine *)linesFromPoint:(CGPoint)source toDestinate:(CGPoint)des{
    NSArray *points = [self nearPointsFromPoint:source toDestinate:des];
    return [self linesFromPoints:points];
}


-(NSArray *)nearPointsFromPoint:(CGPoint)source toDestinate:(CGPoint)des{
    CGPoint nearStart = CGPointZero;
    CGPoint nearDes = CGPointZero;
    float minStart = MAXFLOAT;
    float minEnd = MAXFLOAT;
    for (SVGLine *line in _lines) {
        CGPoint lineStart = CGPointMake(line.x1, line.y1);
        CGPoint lineEnd = CGPointMake(line.x2, line.y2);
        float startDis = [self distanceBetweenPoint:lineStart point:source];
        float endDis = [self distanceBetweenPoint:lineEnd point:source];
        if (minStart>startDis) {
            minStart = startDis;
            nearStart = lineStart;
        }
        
        if (minStart>endDis) {
            minStart = endDis;
            nearStart = lineEnd;
        }
        
        float startDis1 = [self distanceBetweenPoint:lineStart point:des];
        float endDis1 = [self distanceBetweenPoint:lineEnd point:des];
        
        if (minEnd>startDis1) {
            minEnd = startDis1;
            nearDes = lineStart;
        }
        
        if (minEnd>endDis1) {
            minEnd = endDis1;
            nearDes = lineEnd;
        }
    }
    
    return @[[NSValue valueWithCGPoint:nearStart],[NSValue valueWithCGPoint:nearDes]];
}

-(SVGLine *)linesFromPoints:(NSArray *)points{
    NSMutableArray *openList = [[NSMutableArray alloc] initWithCapacity:10];
    NSMutableArray *closeList = [[NSMutableArray alloc] initWithCapacity:10];
    CGPoint source = [[points firstObject] CGPointValue];
    CGPoint des = [[points lastObject] CGPointValue];
    NSArray *sourceLines = [self linesContainPoint:source];
    NSArray *desLines = [self linesContainPoint:des];
    SVGLine *desLine = nil;
    float desDis = MAXFLOAT;
    for (SVGLine *line in desLines) {
        float dis = MIN([self distanceBetweenPoint:CGPointMake(line.x1, line.y1) point:des], [self distanceBetweenPoint:CGPointMake(line.x1, line.y1) point:des]);
        if (desDis>dis) {
            desDis = dis;
            desLine = line;
        }
    }
    
    SVGLine *originalLine = nil;
    NSInteger F = MAXFLOAT;
    for (SVGLine *line in sourceLines) {
        float maxDis = MIN([self distanceBetweenPoint:CGPointMake(line.x2, line.y2) point:source], [self distanceBetweenPoint:CGPointMake(line.x1, line.y1) point:source]);
        line.G = maxDis;
        line.H =MIN([self distanceBetweenPoint:CGPointMake(line.x2, line.y2) point:des], [self distanceBetweenPoint:CGPointMake(line.x1, line.y1) point:des]);
        
        NSInteger temp  = line.G+line.H;
        if (temp<F) {
            F = temp;
            originalLine = line;
        }
    }
    originalLine.isFirst = YES;
    if (originalLine) {
        [openList addObject:originalLine];
    }
    SVGLine *currentLine= nil;
    do{
        currentLine = [self lowestLineInList:openList withSource:source withDes:des];
        if (currentLine) {
            [closeList addObject:currentLine];
             [openList removeObject:currentLine];
        }
        if ([closeList containsObject:desLine]) {
            return currentLine;
            break;
        }
        
        NSMutableArray *avaibleLines = [[NSMutableArray alloc] initWithArray:[self linesConnectToLine:currentLine withDes:des withSource:source]];
//        if ([avaibleLines containsObject:desLine]) {
//            desLine.parent = currentLine;
//            return desLine;
//        }
       [avaibleLines removeObject:currentLine];
        for(SVGLine *line in avaibleLines){
            if ([closeList containsObject:line]) {
                continue;
            }
            if (![openList containsObject:line]) {
                [openList addObject:line];
                line.parent = currentLine;
            }
        }
    }while (openList.count!=0);
    return currentLine;
}

-(SVGLine *)lowestLineInList:(NSArray *)list withSource:(CGPoint)source withDes:(CGPoint)des{
    SVGLine *originalLine = nil;
    NSInteger F = MAXFLOAT;
    for (SVGLine *line in list) {
        NSInteger temp  = line.G+line.H;
        if (temp<F) {
            F = temp;
            originalLine = line;
        }
    }
    return originalLine;
}

-(NSArray *)linesConnectToLine:(SVGLine *)line withDes:(CGPoint)des withSource:(CGPoint)source{
    NSMutableArray *lines = [[NSMutableArray alloc] initWithCapacity:10];
    CGPoint point = CGPointMake(line.x1, line.y1);
    for (SVGLine *eachLine in _lines) {
        if ((fabs(eachLine.x1-point.x)<2&&fabs(eachLine.y1-point.y)<2)||(fabs(eachLine.x2-point.x)<2&&fabs(eachLine.y2-point.y)<2)) {
            eachLine.G = MIN([self distanceBetweenPoint:CGPointMake(eachLine.x1, eachLine.y1) point:source], [self distanceBetweenPoint:CGPointMake(eachLine.x2, eachLine.y2) point:source]);
            eachLine.H = MIN([self distanceBetweenPoint:CGPointMake(eachLine.x1, eachLine.y1) point:des],[self distanceBetweenPoint:CGPointMake(eachLine.x2, eachLine.y2) point:des]);
            if (![lines containsObject:eachLine]) {
                 [lines addObject:eachLine];
            }
           
        }
    }
    
    point  = CGPointMake(line.x2, line.y2);
    for (SVGLine *eachLine in _lines) {
        if ((fabs(eachLine.x1-point.x)<2&&fabs(eachLine.y1-point.y)<2)||(fabs(eachLine.x2-point.x)<2&&fabs(eachLine.y2-point.y)<2)) {
            eachLine.G = MIN([self distanceBetweenPoint:CGPointMake(eachLine.x1, eachLine.y1) point:source], [self distanceBetweenPoint:CGPointMake(eachLine.x2, eachLine.y2) point:source]);
            eachLine.H = MIN([self distanceBetweenPoint:CGPointMake(eachLine.x1, eachLine.y1) point:des],[self distanceBetweenPoint:CGPointMake(eachLine.x2, eachLine.y2) point:des]);
            if (![lines containsObject:eachLine]) {
                [lines addObject:eachLine];
            }
        }
    }
    return lines;
}

-(NSArray*)linesContainPoint:(CGPoint)point{
    NSMutableArray *lines = [[NSMutableArray alloc] initWithCapacity:10];
    for (SVGLine *line in _lines) {
        if ((line.x1==point.x&&line.y1==point.y)||(line.x2==point.x&&line.y2==point.y)) {
            if (![lines containsObject:line]) {
                [lines addObject:line];
            }
        }
    }
    return lines;
}


-(float)distanceBetweenPoint:(CGPoint)p1 point:(CGPoint)p2{
    return sqrtf(powf(p1.x-p2.x, 2)+pow(p1.y-p2.y, 2));
}
@end
