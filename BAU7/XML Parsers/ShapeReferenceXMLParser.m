//
//  ShapeReferenceXMLParser.m
//  BAU7
//
//  Created by Dan Brooker on 6/4/24.
//

#import "Includes.h"
#import "ShapeReferenceXMLParser.h"



@implementation U7ShapeReferenceXMLParser

- (instancetype)initWithXMLData:(NSData *)xmlData {
    self = [super init];
    if (self) {
        shapeReference = [[U7ShapeReference alloc] init];
        NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
        xmlParser.delegate = self;
        [xmlParser parse];
    }
    return self;
}

- (void)parse {
    // This method is called to initialize parsing, handled by the NSXMLParserDelegate methods
}

#pragma mark - NSXMLParserDelegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    currentElementValue = [[NSMutableString alloc] init];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [currentElementValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"GameObject"]) {
        shapeReference->GameObject = [currentElementValue isEqualToString:@"true"];
    } else if ([elementName isEqualToString:@"StaticObject"]) {
        shapeReference->StaticObject = [currentElementValue isEqualToString:@"true"];
    } else if ([elementName isEqualToString:@"GroundObject"]) {
        shapeReference->GroundObject = [currentElementValue isEqualToString:@"true"];
    } else if ([elementName isEqualToString:@"shapeID"]) {
        shapeReference->shapeID = [currentElementValue longLongValue];
    } else if ([elementName isEqualToString:@"frameNumber"]) {
        shapeReference->frameNumber = [currentElementValue intValue];
    } else if ([elementName isEqualToString:@"parentChunkID"]) {
        shapeReference->parentChunkID = [currentElementValue longLongValue];
    } else if ([elementName isEqualToString:@"parentChunkXCoord"]) {
        shapeReference->parentChunkXCoord = [currentElementValue intValue];
    } else if ([elementName isEqualToString:@"parentChunkYCoord"]) {
        shapeReference->parentChunkYCoord = [currentElementValue intValue];
    } else if ([elementName isEqualToString:@"xloc"]) {
        shapeReference->xloc = [currentElementValue intValue];
    } else if ([elementName isEqualToString:@"yloc"]) {
        shapeReference->yloc = [currentElementValue intValue];
    } else if ([elementName isEqualToString:@"lift"]) {
        shapeReference->lift = [currentElementValue intValue];
    } else if ([elementName isEqualToString:@"eulerRotation"]) {
        shapeReference->eulerRotation = [currentElementValue floatValue];
    } else if ([elementName isEqualToString:@"speed"]) {
        shapeReference->speed = [currentElementValue intValue];
    } else if ([elementName isEqualToString:@"depth"]) {
        shapeReference->depth = [currentElementValue intValue];
    } else if ([elementName isEqualToString:@"animates"]) {
        shapeReference->animates = [currentElementValue isEqualToString:@"true"];
    } else if ([elementName isEqualToString:@"numberOfFrames"]) {
        shapeReference->numberOfFrames = [currentElementValue longLongValue];
    } else if ([elementName isEqualToString:@"currentFrame"]) {
        shapeReference->currentFrame = [currentElementValue longLongValue];
    } else if ([elementName isEqualToString:@"maxY"]) {
        shapeReference->maxY = [currentElementValue floatValue];
    } else if ([elementName isEqualToString:@"maxX"]) {
        shapeReference->maxX = [currentElementValue floatValue];
    } else if ([elementName isEqualToString:@"maxZ"]) {
        shapeReference->maxZ = [currentElementValue floatValue];
    }
}

@end
