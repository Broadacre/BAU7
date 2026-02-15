//
//  BATable.h
//  BAU7
//
//  Created by Dan Brooker on 7/4/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BATableEntry: NSObject
{
    @public
    NSString * title;
    int desiredPercent;
    long value;
    
    //for use by table
    int actualPercent;  //
    NSRange range;
    
}
-(void)dump;
-(long)getValue;
@end

@interface BATable : NSObject
{
    NSString * title;
    NSMutableArray * table;
    BOOL fitToOneHundredPercent;
}
-(void)addTableEntry:(BATableEntry *)tableEntry;
-(long)count;
-(void)setFitToOneHundredPercent:(BOOL)shouldFit;
-(void)updateEntries;
-(void)dump;
-(BATableEntry *)entryAtLocation:(int)location;
-(BATableEntry *)randomEntry;

+(BOOL)fileExists:(NSString *) fileName;
+(NSArray *)BATablesFromFile:(NSString*)fileName;
+(BATable*)fetchTableByTitleFromArray:(NSArray*)theArray forTitle:(NSString*)title;
@end

NS_ASSUME_NONNULL_END
