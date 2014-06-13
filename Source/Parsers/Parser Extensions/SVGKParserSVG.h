#import <Foundation/Foundation.h>

#import "SVGKParser.h"


@interface SVGLine : NSObject
@property (nonatomic, copy) NSString *id;
@property (nonatomic, assign) float x1;
@property (nonatomic, assign) float x2;
@property (nonatomic, assign) float y1;
@property (nonatomic, assign) float y2;
@property (nonatomic, assign) NSInteger G;
@property (nonatomic, assign) NSInteger H;
@property (nonatomic, strong) SVGLine *parent;
@property (nonatomic, assign) BOOL isFirst;
-(CGPoint)pedalFromPoint:(CGPoint)point;
@end

@interface SVGKParserSVG : NSObject <SVGKParserExtension> {
}
@property (nonatomic, strong) NSMutableArray *lines;
@end
