#import "SVGKParserSVG.h"

#import "SVGSVGElement.h"
#import "SVGCircleElement.h"
#import "SVGDefsElement.h"
#import "SVGDescriptionElement.h"
//#import "SVGKSource.h"
#import "SVGEllipseElement.h"
#import "SVGGElement.h"
#import "SVGImageElement.h"
#import "SVGLineElement.h"
#import "SVGPathElement.h"
#import "SVGPolygonElement.h"
#import "SVGPolylineElement.h"
#import "SVGRectElement.h"
#import "SVGTitleElement.h"
#import "SVGTextElement.h"

#import "SVGDocument_Mutable.h"

@implementation SVGLine
-(BOOL)isEqual:(id)object{
    if (![object isKindOfClass:[SVGLine class]]) {
        return NO;
    }
    SVGLine *another = (SVGLine *)object;
    if (self.x1==another.x1&&self.x2 == another.x2&&self.y1 == another.y1&&self.y2 == self.y2) {
        return YES;
    }else{
        return NO;
    }
}

-(NSString *)description{
    return [NSString stringWithFormat:@"%@ (%f,%f) (%f,%f)",self.id,self.x1,self.y1,self.x2,self.y2];
}


-(CGPoint)pedalFromPoint:(CGPoint)point{
    return [self pedalPoint:CGPointMake(self.x1, self.y1) Start:CGPointMake(self.x2, self.y2) End:point];
}

-(CGPoint)pedalPoint:(CGPoint)p1 Start: (CGPoint )p2 End: (CGPoint)x0{
    
    float A=p2.y-p1.y;
    float B=p1.x-p2.x;
    float C=p2.x*p1.y-p1.x*p2.y;
    
    float x=(B*B*x0.x-A*B*x0.y-A*C)/(A*A+B*B);
    float y=(-A*B*x0.x+A*A*x0.y-B*C)/(A*A+B*B);
    
    CGPoint ptCross=CGPointMake(x, y);
    return ptCross;
}

@end


@implementation SVGKParserSVG

static NSDictionary *elementMap;

- (id)init {
	self = [super init];
	if (self) {
		
		if (!elementMap) {
			elementMap = [[NSDictionary dictionaryWithObjectsAndKeys:
						   [SVGSVGElement class], @"svg",
                          [SVGCircleElement class], @"circle",
                          [SVGDescriptionElement class], @"description",
                          [SVGEllipseElement class], @"ellipse",
                          [SVGGElement class], @"g",
                          [SVGImageElement class], @"image",
                          [SVGLineElement class], @"line",
                          [SVGPathElement class], @"path",
                          [SVGPolygonElement class], @"polygon",
                          [SVGPolylineElement class], @"polyline",
                          [SVGRectElement class], @"rect",
                          [SVGTitleElement class], @"title",
						   [SVGTextElement class], @"text",
						   nil] retain];
		}
        self.lines = [[NSMutableArray alloc] initWithCapacity:10];
	}
	return self;
}

- (void)dealloc {
	
	[super dealloc];
}

-(NSArray*) supportedNamespaces
{
	return [NSArray arrayWithObjects:
			 @"http://www.w3.org/2000/svg",
			nil];
}

/** "tags supported" is exactly the set of all SVGElement subclasses that already exist */
-(NSArray*) supportedTags
{
	return [NSMutableArray arrayWithArray:[elementMap allKeys]];
}

- (Node*) handleStartElement:(NSString *)name document:(SVGKSource*) SVGKSource namePrefix:(NSString*)prefix namespaceURI:(NSString*) XMLNSURI attributes:(NSMutableDictionary *)attributes parseResult:(SVGKParseResult *)parseResult parentNode:(Node*) parentNode
{
	if( [[self supportedNamespaces] containsObject:XMLNSURI] )
	{
		Class elementClass = [elementMap objectForKey:name];
		
		if (!elementClass) {
			elementClass = [SVGElement class];
			DDLogWarn(@"Support for '%@' element has not been implemented", name);
		}
        
        if ([name isEqualToString:@"line"]) {
            SVGLine *line = [[SVGLine alloc] init];
            NSString *id = [attributes[@"id"] value];
            NSString *x1 = [attributes[@"x1"] value];
            NSString *x2 = [attributes[@"x2"] value];
            NSString *y1 = [attributes[@"y1"] value];
            NSString *y2 = [attributes[@"y2"] value];
            line.id = id;
            line.x1 = [x1 integerValue];
            line.x2 = [x2 integerValue];
            line.y1 = [y1 integerValue];
            line.y2 = [y2 integerValue];
            [self.lines addObject:line];
            [line release];
        }
		/**
		 NB: following the SVG Spec, it's critical that we ONLY use the DOM methods for creating
		 basic 'Element' nodes.
		 
		 Our SVGElement root class has an implementation of init that delegates to the same
		 private methods that the DOM methods use, so it's safe...
		 
		 FIXME: ...but in reality we ought to be using the DOMDocument createElement/NS methods, although "good luck" trying to find a DOMDocument if your SVG is embedded inside a larger XML document :(
		 */
		
		
		NSString* qualifiedName = (prefix == nil) ? name : [NSString stringWithFormat:@"%@:%@", prefix, name];
		/** NB: must supply a NON-qualified name if we have no specific prefix here ! */
		SVGElement *element = [[[elementClass alloc] initWithQualifiedName:qualifiedName inNameSpaceURI:XMLNSURI attributes:attributes] autorelease];
		
		/** NB: all the interesting handling of shared / generic attributes - e.g. the whole of CSS styling etc - takes place in this method: */
		[element postProcessAttributesAddingErrorsTo:parseResult];
		
		/** special case: <svg:svg ... version="XXX"> */
		if( [@"svg" isEqualToString:name] )
		{
			NSString* svgVersion = nil;
			
			/** According to spec, if the first XML node is an SVG node, then it
			 becomes TWO THINGS:
			 
			 - An SVGSVGElement
			 *and*
			 - An SVGDocument
			 - ...and that becomes "the root SVGDocument"
			 
			 If it's NOT the first XML node, but it's the first SVG node, then it ONLY becomes:
			 
			 - An SVGSVGElement
			 
			 If it's NOT the first SVG node, then it becomes:
			 
			 - An SVGSVGElement
			 *and*
			 - An SVGDocument
			 
			 Yes. It's Very confusing! Go read the SVG Spec!
			 */
			
			BOOL generateAnSVGDocument = FALSE;
			BOOL overwriteRootSVGDocument = FALSE;
			BOOL overwriteRootOfTree = FALSE;
			
			if( parentNode == nil )
			{
				/** This start element is the first item in the document
				 PS: xcode has a new bug for Lion: it can't format single-line comments with two asterisks. This line added because Xcode sucks.
				 */
				generateAnSVGDocument = overwriteRootSVGDocument = overwriteRootOfTree = TRUE;
				
			}
			else if( parseResult.rootOfSVGTree == nil )
			{
				/** It's not the first XML, but it's the first SVG node */
				overwriteRootOfTree = TRUE;
			}
			else
			{
				/** It's not the first SVG node */
				// ... so: do nothing special
			}
			
			/**
			 Handle the complex stuff above about SVGDocument and SVG node
			 */
			if( overwriteRootOfTree )
			{
				parseResult.rootOfSVGTree = (SVGSVGElement*) element;
				
				/** Post-processing of the ROOT SVG ONLY (doesn't apply to embedded SVG's )
				 */
				if ((svgVersion = [attributes objectForKey:@"version"])) {
					SVGKSource.svgLanguageVersion = svgVersion;
				}
			}
			if( generateAnSVGDocument )
			{
				NSAssert( [element isKindOfClass:[SVGSVGElement class]], @"Trying to create a new internal SVGDocument from a Node that is NOT of type SVGSVGElement (tag: svg). Node was of type: %@", NSStringFromClass([element class]));
				
				SVGDocument* newDocument = [[[SVGDocument alloc] init] autorelease];
				newDocument.rootElement = (SVGSVGElement*) element;
				
				if( overwriteRootSVGDocument )
				{
					parseResult.parsedDocument = newDocument;
				}
				else
				{
					NSAssert( FALSE, @"Currently not supported: multiple SVG Document nodes in a single SVG file" );
				}
			}
			
		}
		
		
		return element;
	}
	
	return nil;
}

-(void)handleEndElement:(Node *)newNode document:(SVGKSource *)document parseResult:(SVGKParseResult *)parseResult
{
	
}


@end
