//
//  ShapeReferenceXMLParser.h
//  BAU7
//
//  Created by Dan Brooker on 6/4/24.
//



#import <Foundation/Foundation.h>
@class U7ShapeReference;
@interface U7ShapeReferenceXMLParser : NSObject <NSXMLParserDelegate>


{
    U7ShapeReference *shapeReference;
    NSMutableString *currentElementValue;
}

- (instancetype)initWithXMLData:(NSData *)xmlData;
- (void)parse;

@end
