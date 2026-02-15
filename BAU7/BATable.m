//
//  BATable.m
//  BAU7
//
//  Created by Dan Brooker on 7/4/22.
//

#import "BATable.h"

@implementation BATableEntry
-(id)init
{
    self=[super init];
    title=@"Untitled";
    desiredPercent=0;
    value=0;
    return self;
}

-(void)dump
{
    NSLog(@"  BATableEntry dump");
    NSLog(@"  BATableEntry Title: %@",title);
    NSLog(@"  BATableEntry desiredPercent %i",desiredPercent);
    NSLog(@"  BATableEntry actualPercent %i",actualPercent);
    NSLog(@"  BATableEntry value %li",value);
    NSLog(@"  BATableEntry range start: %li length: %li",range.location,range.length);
    
}
-(long)getValue
{
    return value;
}

@end

@implementation BATable

-(id)init
{
    self=[super init];
    table=[[NSMutableArray alloc]init];
    fitToOneHundredPercent=YES;
    title=@"Untitled";
    return self;
}
-(void)dump
{
    NSLog(@"BATable dump");
    NSLog(@"BATable Title: %@",title);
    for(long index=0;index<[table count];index++)
    {
        BATableEntry * entry=[table objectAtIndex:index];
        [entry dump];
    }
}

-(void)addTableEntry:(BATableEntry *)tableEntry
{
    if(tableEntry)
        [table addObject:tableEntry];
}

-(long)count
{
    return [table count];
}

-(void)setFitToOneHundredPercent:(BOOL)shouldFit
{
    fitToOneHundredPercent=shouldFit;
    
}


-(void)updateEntries
{
    //sort by %
    [table sortUsingFunction:compare context:Nil];
  
    //expand or contract to 100%
    if(fitToOneHundredPercent)
    {
        int sum=0;
        for(long index=0;index<[table count];index++)
        {
            BATableEntry * entry=[table objectAtIndex:index];
            sum+=entry->desiredPercent;
        }
        
        //NSLog(@"sum: %i",sum);
        float adjustment=100.0/sum;
        //NSLog(@"Adjustment: %f",adjustment);
        for(long index=0;index<[table count];index++)
        {
            BATableEntry * entry=[table objectAtIndex:index];
            float adjustedValue=entry->desiredPercent*adjustment;
            entry->actualPercent=adjustedValue;
        }
    }
    else
    {
        for(long index=0;index<[table count];index++)
        {
            BATableEntry * entry=[table objectAtIndex:index];
            entry->actualPercent=entry->desiredPercent;
        }
    }
    
    //calculate ranges
    long location=1;
    for(long index=0;index<[table count];index++)
    {
        BATableEntry * entry=[table objectAtIndex:index];
        entry->range=NSMakeRange(location, entry->actualPercent);
        location+=entry->actualPercent;
    }
}

NSComparisonResult compare(BATableEntry *firstEntry, BATableEntry *secondEntry, void *context) {
  if (firstEntry->desiredPercent  < secondEntry->desiredPercent)
    return NSOrderedAscending;
  else if (firstEntry->desiredPercent  > secondEntry->desiredPercent)
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}

-(BATableEntry *)entryAtLocation:(int)location
{
    for(long index=0;index<[table count];index++)
    {
        BATableEntry * entry=[table objectAtIndex:index];
        BOOL inRange=NSLocationInRange(location, entry->range);
        if(inRange)
            return entry;
    }
    return NULL;
}

#define MAXTRIES 100
-(BATableEntry *)randomEntry
{
    BATableEntry * entry=NULL;
    int minimum=1;
    int maximum=100;
    long tries=0;
    while(!entry)
    {
        int theRandom=arc4random() % (maximum+1-minimum)+minimum;
        //NSLog(@"theRandom: %i",theRandom);
        entry=[self entryAtLocation:theRandom];
        tries++;
        if(tries>MAXTRIES)
            NSLog(@"Warning in randomEntry - tries is greater than MAXTRIES");
    }
    
    return entry;
}


+(BOOL)fileExists:(NSString *) fileName
{
    BOOL result=YES;
    NSString* path = [[NSBundle mainBundle] pathForResource:fileName
                                               ofType:@"txt"];
    
    result = [[NSFileManager defaultManager] fileExistsAtPath:path];
    /*
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:fileName];
    result = [[NSFileManager defaultManager] fileExistsAtPath:path];
     */
    return result;
}

+(NSArray*)BATablesFromFile:(NSString*)fileName
{
    NSMutableArray * tables=[[NSMutableArray alloc]init];
    BOOL fileExists=[BATable fileExists:fileName];
    if(!fileExists)
    {
        NSLog(@"BATableFromFile bad file");
        return NULL;
    }
    NSString* path = [[NSBundle mainBundle] pathForResource:fileName
                                               ofType:@"txt"];
    
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    
    NSString * stringWithoutNewlines= [[content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
    
    NSArray * tableData=[stringWithoutNewlines componentsSeparatedByString:@"BATABLE***"];
    
    
    //NSLog(@"%li tables",[tableData count]);
    
    for(long index=0;index<[tableData count];index++)
    {
        //NSLog(@"Table %li",index);
        NSString * string=[tableData objectAtIndex:index];
        //NSLog(@"%@",string);
        NSArray * tableEntries=[string componentsSeparatedByString:@","];
        long numberOfEntries=([tableEntries count]-1)/3;
        //NSLog(@"%li entries",numberOfEntries);
        
        long currentIndex=0;
        if(numberOfEntries>0)
        {
            BATable * table=[[BATable alloc]init];
            table->title=[tableEntries objectAtIndex:currentIndex];
            currentIndex++;
            for(long entryIndex=0;entryIndex<numberOfEntries;entryIndex++)
            {
                BATableEntry * entry=[[BATableEntry alloc]init];
                //currentIndex=entryIndex*3;
                NSString * entryString=[tableEntries objectAtIndex:currentIndex];
                entry->title=entryString;
                currentIndex++;
                entryString=[tableEntries objectAtIndex:currentIndex];
                entry->desiredPercent=[entryString intValue];
                currentIndex++;
                entryString=[tableEntries objectAtIndex:currentIndex];
                entry->value=[entryString intValue];
                currentIndex++;
                [table addTableEntry:entry];
            }
            //[table dump];
            [table updateEntries];
            [tables addObject:table];
        }
            
        
        
    }
    
    
    //NSLog(@"%@",stringWithoutNewlines);
    return tables;
}

+(BATable*)fetchTableByTitleFromArray:(NSArray*)theArray forTitle:(NSString*)title
{
    BATable * table=NULL;
    
    for(long index=0;index<[theArray count];index++)
    {
        table=[theArray objectAtIndex:index];
        if([table->title isEqualToString:title])
            return table;
    }
    NSLog(@"fetchTableByTitleFromArray Table %@ Not Found",title);
    return NULL;
}

@end
