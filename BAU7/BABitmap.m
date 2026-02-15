//
//  BABitmap.m
//  BAU7
//
//  Created by Dan Brooker on 12/11/22.
//
#import <UIKit/UIKit.h>
#import "CGPointUtilities.h"
#import "BABitmap.h"

@implementation BABitmap

-(void)clear
{
 
}


-(void)dump
{
 
}

-(BOOL)validPosition:(CGPoint)thePosition
{
    if(thePosition.x<size.width&&thePosition.x>=0&&thePosition.y>=0&&thePosition.y<size.height)
        return YES;
    else
        return NO;
}

-(CGRect)getBounds
{
    return CGRectMake(0, 0, size.width, size.height);
}

-(CGPoint)midpoint
{
    return(CGPointMake(size.width/2, size.height/2));
}

-(float)width
{
    return size.width;
}

-(float)height
{
    return size.height;
}

@end

@implementation BAIntBitmap
+(BAIntBitmap*)createWithCGSize:(CGSize)theSize
{
    
    BAIntBitmap * newBitmap=[[BAIntBitmap alloc]init];
    newBitmap->size=theSize;
    newBitmap->bitmap = [[NSMutableArray alloc]init];
    
    for(long y=0;y<theSize.height;y++)
    {
        for(long x=0;x<theSize.width;x++)
        {
            long index=(y*theSize.width)+x;
            NSNumber * number=[NSNumber numberWithInt:0];
            [newBitmap->bitmap addObject:number];
        }
    }
    
    return newBitmap;
}
+(BAIntBitmap*)clipBitmapToSize:(BAIntBitmap *)sourceBitmap forSize:(CGSize)theSize padWithValue:(int)padValue
{
    BAIntBitmap * newBitmap=[BAIntBitmap createWithCGSize:theSize];
    
    for (long y=0; y<theSize.height; y++)
    {
        for (long x=0; x<theSize.width; x++)
        {
            //handle case where source
            if(y>=sourceBitmap->size.height-1||
               x>=sourceBitmap->size.width-1)
            {
                [newBitmap setValueAtPosition:padValue forPosition:CGPointMake(x, y)];
                continue;
            }
            int value=[sourceBitmap valueAtPosition:CGPointMake(x, y) from:@"copyToBitmap"];
            [newBitmap setValueAtPosition:value forPosition:CGPointMake(x, y)];
        }
    }
    
    
    return newBitmap;
}


+(BAIntBitmap*)clipBitmapToRect:(BAIntBitmap *)sourceBitmap forSize:(CGRect)theRect padWithValue:(int)padValue
{
    if(!validLocation(theRect.origin))
    {
        NSLog(@"not valid location");
        return NULL;
    }
    if((theRect.size.width+theRect.origin.x)>sourceBitmap->size.width)
    {
        //NSLog(@"too wide: %f",destination->size.width);
        return NULL;
    }
    if((theRect.size.height+theRect.origin.y)>sourceBitmap->size.height)
    {
        NSLog(@"too high");
        return NULL;
    }
    
    
    
    BAIntBitmap * newBitmap=[BAIntBitmap createWithCGSize:theRect.size];
    
    for (long y=0; y<theRect.size.height; y++)
    {
        for (long x=0; x<theRect.size.width; x++)
        {
            //handle case where source
            if(y>=sourceBitmap->size.height-1||
               x>=sourceBitmap->size.width-1)
            {
                [newBitmap setValueAtPosition:padValue forPosition:CGPointMake(x, y)];
                continue;
            }
            int value=[sourceBitmap valueAtPosition:CGPointMake(x+theRect.origin.x, y+theRect.origin.y) from:@"copyToBitmap"];
            [newBitmap setValueAtPosition:value forPosition:CGPointMake(x, y)];
        }
    }
    
    
    return newBitmap;
}

-(int)valueAtPosition:(CGPoint)position from:(NSString*)caller;
{
    if(![self validPosition:position])
    {
        NSLog(@"BAIntBitmap valueAtPosition: %f,%f Out of Bounds from %@",position.x,position.y,caller);
        return 0;
    }
    long index=(position.y*size.width)+position.x;
    NSNumber * number=[bitmap objectAtIndex:index];
    int value=[number intValue];
    return value;
}


-(void)setValueAtPosition:(int)theValue forPosition:(CGPoint)position
{
    if(![self validPosition:position])
    {
        NSLog(@"BAIntBitmap valueAtPosition: Out of Bounds");
        return;
    }
    long index=(position.y*size.width)+position.x;
    NSNumber * number=[NSNumber numberWithInt:theValue];
    
    [bitmap replaceObjectAtIndex:index withObject:number];
    
}

-(void)setValuesAtPositions:(int)theValue forPositions:(CGPointArray*)positions
{
    if(!positions)
    {
        NSLog(@"Bad Positions");
        return;
    }
    if(![positions count])
    {
        NSLog(@"No Count");
        return;
    }
    for(long index=0;index<[positions count];index++)
    {
        CGPoint position=[positions pointAtIndex:index];
        [self setValueAtPosition:theValue forPosition:position];
    }
}


-(void)setValueForRect:(int)theValue forRect:(CGRect)theRect
{

    if(CGRectContainsRect([self getBounds], theRect))
    {
        //NSLog(@"in bounds");
        for(long y=theRect.origin.y;y<theRect.size.height+theRect.origin.y;y++)
        {
            for(long x=theRect.origin.x;x<theRect.size.width+theRect.origin.x;x++)
            {
                [self setValueAtPosition:theValue forPosition:CGPointMake(x, y)];
                
            }
        }
    }
    
    
}

-(void)setValueForRectWithMask:(int)theValue forRect:(CGRect)theRect forMask:(BABooleanBitmap*)theMask
{
    if(CGRectContainsRect([self getBounds], theRect))
    {
        
        
        for(long y=0;y<(theRect.size.height);y++)
        {
            for(long x=0;x<(theRect.size.width);x++)
            {
                BOOL shouldSetValue=0;
                    shouldSetValue=[theMask valueAtPosition:CGPointMake(x, y)];
                if(shouldSetValue)
                    [self setValueAtPosition:theValue forPosition:CGPointMake(theRect.origin.x+x, theRect.origin.y+y)];
                
                
            }
        }
        
    }
}

-(void)fillWithValue:(int)theValue
{
    for(long y=0;y<size.height;y++)
    {
        for(long x=0;x<size.width;x++)
        {
            [self setValueAtPosition:theValue forPosition:CGPointMake(x, y)];
            
        }
    }
}


-(void)fillWithArray:(NSArray*)theArray
{
    //this is incomplete...Need to check size first
    
    for(long y=0;y<[self height];y++)
    {
        for(long x=0;x<[self width];x++)
        {
        long index=(y*[self height])+x;
            NSNumber * number=[theArray objectAtIndex:index];
            [self setValueAtPosition:[number intValue] forPosition:CGPointMake(x, y)];
        }
    }
    
    
}


-(long)countOfValue:(int)theValue
{
    long count=0;
    for(long y=0;y<[self height];y++)
    {
        for(long x=0;x<[self width];x++)
        {
            if([self containsValue:theValue forPosition:CGPointMake(x, y)])
                count++;
        }
    }
    return count;
}



-(BOOL)containsValue:(int)theValue forPosition:(CGPoint)position
{
    int value=[self valueAtPosition:position from:@"BAIntBitmap containsValue"];
    if(value==theValue)
        return YES;
    return NO;
}


-(void)clear
{
    [self fillWithValue:0];
}


-(void)dump
{
    printf("\n");
    for(long y=0;y<size.height;y++)
    {
        for(long x=0;x<size.width;x++)
        {
            int value=[self valueAtPosition:CGPointMake(x, y) from:@"BAIntBitmap dump"];
            printf("%i,",value);
        }
        printf("\n");
    }
}

-(void)frameWithValue:(int)theValue
{
    BOOL shouldFill=NO;
    for(int row=0; row < [self height]; row++)
     {
         //NSLog(@"RandomFill 2: %i",row);
        for(int column = 0; column < [self width]; column++)
        {
            // If coordinants lie on the the edge of the map (creates a border)
            shouldFill=NO;
            if(column == 0)
            {
                shouldFill=YES;
            }
            else if (row == 0)
            {
                shouldFill=YES;
            }
            else if (column == [self width]-1)
            {
                shouldFill=YES;
            }
            else if (row == [self height]-1)
            {
                shouldFill=YES;
            }
            // Else, fill with a wall a random percent of the time
            
            if(shouldFill)
            {
             [self setValueAtPosition:theValue forPosition:CGPointMake(column, row)];
        
            }
        }
    }
}


-(CGPoint)closestPositionOnYAxisWithValue:(int)theValue atX:(long)x atZeroY:(BOOL)startAtZeroY
{
    
    if(x<0)
    {
        return CGPointMake(-1, -1);
    }
    if(x>([self width]-1))
    {
        return CGPointMake(-1, -1);
    }
    if(startAtZeroY)
    {
        for(int y=0; y < [self height]; y++)
        {
            if(theValue==[self valueAtPosition:CGPointMake(x, y) from:@"closestPositionInColumnWithValue"])
            {
                return CGPointMake(x, y);
            }
            //else NSLog(@"No");
        }
    }
    else
    {
        for(int y=[self height]-1; y > 0; y--)
        {
            if(theValue==[self valueAtPosition:CGPointMake(x, y) from:@"closestPositionInColumnWithValue"])
            {
                return CGPointMake(x, y);
            }
        }
    }
    return CGPointMake(-1, -1);
}




-(CGPoint)closestPositionOnXAxisWithValue:(int)theValue atY:(long)y atZeroX:(BOOL)startAtZeroX
{
    
    if(y<0)
    {
        NSLog(@"closestPositionInRowWithValue invalid");
        return CGPointMake(-1, -1);
    }
    if(y>([self height]-1))
    {
        NSLog(@"closestPositionInRowWithValue invalid");
        return CGPointMake(-1, -1);
    }
    
    if(startAtZeroX)
    {
        for(int x=0; x < [self width]; x++)
        {
            if(theValue==[self valueAtPosition:CGPointMake(x, y) from:@"closestPositionInRowWithValue"])
            {
                return CGPointMake(x, y);
            }
        }
    }
    else
    {
        for(int x=[self width]-1; x > 0; x--)
        {
            if(theValue==[self valueAtPosition:CGPointMake(x, y) from:@"closestPositionInRowWithValue"])
            {
                return CGPointMake(x, y);
            }
        }
    }
    return CGPointMake(-1, -1);
}

-(CGPointArray *)closestPositionOnXAxisWithValue:(int)theValue atZeroX:(BOOL)startAtZeroX
{
    
    float closestX=-1;
    //first find closest x
    for(long y=0;y<[self width];y++)
    {
        CGPoint newPoint=[self closestPositionOnXAxisWithValue:theValue atY:y atZeroX:startAtZeroX];
       
        if(validLocation(newPoint))
        {
            if(closestX==-1)//first hit
            {
                closestX=newPoint.x;
            }
            else if(startAtZeroX)
            {
                if(newPoint.x<closestX)
                {
                    closestX=newPoint.x;
                }
            }
            else
            {
                if(newPoint.x>closestX)
                {
                    closestX=newPoint.x;
                }
            }
        }
    }
    //NSLog(@"Closest X: %f",closestX);
    
    if(closestX==-1)
        return NULL;
    
    CGPointArray * pointArray=[[CGPointArray alloc]init];
    for(long y=0;y<[self width];y++)
    {
        CGPoint newPoint=[self closestPositionOnXAxisWithValue:theValue atY:y atZeroX:startAtZeroX];
        
        if(validLocation(newPoint))
            {
                
            if(newPoint.x==closestX)
                {
                [pointArray addPoint:newPoint];
                }
            }
        else
        {
         //   NSLog(@"Bad");
        }
    }
    return pointArray;
}

-(CGPointArray *)closestPositionOnYAxisWithValue:(int)theValue atZeroY:(BOOL)startAtZeroY
{
    
    float closestY=-1;
    //first find closest x
    for(long x=0;x<[self height];x++)
    {
        CGPoint newPoint=[self closestPositionOnYAxisWithValue:theValue atX:x atZeroY:startAtZeroY];
       
        if(validLocation(newPoint))
        {
            if(closestY==-1)//first hit
            {
                closestY=newPoint.y;
            }
            else if(startAtZeroY)
            {
                if(newPoint.y<closestY)
                {
                    closestY=newPoint.y;
                }
            }
            else
            {
                if(newPoint.y>closestY)
                {
                    closestY=newPoint.y;
                }
            }
        }
    }
    //NSLog(@"Closest X: %f",closestX);
    
    if(closestY==-1)
        return NULL;
    
    CGPointArray * pointArray=[[CGPointArray alloc]init];
    for(long x=0;x<[self height];x++)
    {
        CGPoint newPoint=[self closestPositionOnYAxisWithValue:theValue atX:x atZeroY:startAtZeroY];
        
        if(validLocation(newPoint))
            {
                
            if(newPoint.y==closestY)
                {
                [pointArray addPoint:newPoint];
                }
            }
        else
        {
         //   NSLog(@"Bad");
        }
    }
    return pointArray;
}


-(CGPointArray *)BordersOnXAxisWithValue:(int)theValue atZeroX:(BOOL)startAtZeroX
{
    CGPointArray * pointArray=[[CGPointArray alloc]init];
    for(long y=0;y<[self width];y++)
    {
        CGPoint newPoint=[self closestPositionOnXAxisWithValue:theValue atY:y atZeroX:startAtZeroX];
       
        if(validLocation(newPoint))
        {
            [pointArray addPoint:newPoint];
        }
    }
    //NSLog(@"Closest X: %f",closestX);
   
    return pointArray;
}

-(CGPointArray *)BordersOnYAxisWithValue:(int)theValue atZeroY:(BOOL)startAtZeroY
{
    CGPointArray * pointArray=[[CGPointArray alloc]init];
    for(long x=0;x<[self height];x++)
    {
        CGPoint newPoint=[self closestPositionOnYAxisWithValue:theValue atX:x atZeroY:startAtZeroY];
        
        if(validLocation(newPoint))
            {
                [pointArray addPoint:newPoint];
            }
        
    }
    return pointArray;
}

-(CGPointArray *)allBordersWithValue:(int)theValue
    {
        CGPointArray * pointArray=[[CGPointArray alloc]init];
        CGPointArray * tempArray;
        
        tempArray=[self BordersOnXAxisWithValue:theValue atZeroX:YES];
        [pointArray addUniquePoints:tempArray];
        tempArray=[self BordersOnXAxisWithValue:theValue atZeroX:NO];
        [pointArray addUniquePoints:tempArray];
        tempArray=[self BordersOnYAxisWithValue:theValue atZeroY:YES];
        [pointArray addUniquePoints:tempArray];
        tempArray=[self BordersOnYAxisWithValue:theValue atZeroY:NO];
        [pointArray addUniquePoints:tempArray];
        
        return pointArray;
    }

-(BOOL)copyToBitmap:(BAIntBitmap*)destination atPosition:(CGPoint)thePosition
    {
        if(!validLocation(thePosition))
        {
            NSLog(@"not valid location");
            return NO;
        }
        if((size.width+thePosition.x)>destination->size.width)
        {
            NSLog(@"too wide: %f",destination->size.width);
            return NO;
        }
        if((size.height+thePosition.y)>destination->size.height)
        {
            NSLog(@"too high");
            return NO;
        }
        
        
        for (long y=0; y<size.height; y++)
        {
            for (long x=0; x<size.width; x++)
            {
                int value=[self valueAtPosition:CGPointMake(x, y) from:@"copyToBitmap"];
                [destination setValueAtPosition:value forPosition:CGPointMake(x+thePosition.x, y+thePosition.y)];
            }
        }
        
        return YES;
    }
    
-(BOOL)isRectFilledWithValue:(CGRect)theRect withValue:(int)theValue
    {
        if((theRect.size.width+theRect.origin.x)>[self width])
        {
            return NO;
        }
        if((theRect.size.height+theRect.origin.y)>[self height])
        {
            return NO;
        }
        if(theRect.origin.x<0)
            return NO;
        if(theRect.origin.y<0)
            return NO;
        
        //so valid rect
        for (long y=0; y<theRect.size.height; y++)
        {
            for (long x=0; x<theRect.size.width; x++)
            {
                int value=[self valueAtPosition:CGPointMake(x+theRect.origin.x, y+theRect.origin.y) from:@"isRectFilledWithValue"];
                if(theValue!=value)
                    return NO;
            }
        }
        
        return YES;
    }
    
-(CGPointArray *)originsOfRectsFilledWithValue:(int)theValue ofSize:(CGSize)size
    {
        CGPointArray *pointArray=[[CGPointArray alloc]init];
        for (long y=0; y<[self height]; y++)
        {
            for (long x=0; x<[self width]; x++)
            {
                if([self isRectFilledWithValue:CGRectMake(x, y, size.width, size.height) withValue:theValue])
                {
                    //printf("Y");
                    [pointArray addPoint:CGPointMake(x, y)];
                }
                    
                else
                {
                    //printf("N");
                }
                
            }
            //printf("\n");
        }
        
        return pointArray;
    }
    
-(CGPoint)originOfRandomRectFilledWithValue:(int)theValue ofSize:(CGSize) theSize
    {
        CGPointArray * pointArray;
        pointArray=[self originsOfRectsFilledWithValue:theValue ofSize:theSize];
        if(![pointArray count])
            return invalidLocation();
        CGPoint thePoint=[pointArray getRandomPoint];
        if(validLocation(thePoint))
            return thePoint;
        return invalidLocation();
        
    }


-(BOOL)compareBitmap:(BAIntBitmap*)comparisonBitmap atPosition:(CGPoint)position
{
    if((comparisonBitmap->size.width+position.x)>size.width)
        return NO;
    if((comparisonBitmap->size.height+position.y)>size.height)
        return NO;
    if(position.x<0)
        return NO;
    if(position.y<0)
        return NO;
    for(long y=0;y<(comparisonBitmap.height);y++)
    {
        for(long x=0;x<(comparisonBitmap.width);x++)
        {
            int value=[self valueAtPosition:CGPointMake(x+position.x, y+position.y) from:@"compareBitmap"];
            int compareValue=[comparisonBitmap valueAtPosition:CGPointMake(x,y) from:@"compareBitmap"];
            if(compareValue!=value)
                return NO;
            
        }
    }
    
    
    return YES;
    
}

-(BOOL)compareBitmapWithMask:(BAIntBitmap*)comparisonBitmap withMask:(BABooleanBitmap*)maskBitmap atPosition:(CGPoint)position
{
    if((comparisonBitmap->size.width+position.x)>size.width)
        return NO;
    if((comparisonBitmap->size.height+position.y)>size.height)
        return NO;
    if(comparisonBitmap->size.width!=maskBitmap->size.width)
        return NO;
    if(comparisonBitmap->size.height!=maskBitmap->size.height)
        return NO;
    if(position.x<0)
        return NO;
    if(position.y<0)
        return NO;
    for(long y=0;y<(comparisonBitmap.height);y++)
    {
        for(long x=0;x<(comparisonBitmap.width);x++)
        {
            int value=[self valueAtPosition:CGPointMake(x+position.x, y+position.y) from:@"compareBitmapWithMask"];
            int compareValue=[comparisonBitmap valueAtPosition:CGPointMake(x,y) from:@"compareBitmapWithMask"];
            BOOL maskValue=[maskBitmap valueAtPosition:CGPointMake(x,y)];
            if(maskValue) //if we have a mask value we ARE comparing
            {
                if(compareValue!=value)
                    return NO;
            }
            
            
        }
    }
    
    
    return YES;
    
}
-(CGPointArray*)pointsMatchingBitmapWithMask:(BAIntBitmap*)comparisonBitmap forMask:(BABooleanBitmap*)theMask
{
    CGPointArray *pointArray=[[CGPointArray alloc]init];
    for (long y=0; y<[self height]; y++)
    {
        for (long x=0; x<[self width]; x++)
        {
            
            if([self compareBitmapWithMask:comparisonBitmap withMask:theMask atPosition:CGPointMake(x, y)])
            {
                //printf("Y");
                [pointArray addPoint:CGPointMake(x, y)];
            }
                
            else
            {
                //printf("N");
            }
            
        }
        //printf("\n");
    }
    
    return pointArray;
    
}


@end

@implementation BACharBitmap
+(BACharBitmap*)createWithCGSize:(CGSize)theSize
{
    
    BACharBitmap * newBitmap=[[BACharBitmap alloc]init];
    newBitmap->size=theSize;
    newBitmap->bitmap = [[NSMutableArray alloc]init];
    
    for(long y=0;y<theSize.height;y++)
    {
        for(long x=0;x<theSize.width;x++)
        {
            long index=(y*theSize.width)+x;
            NSNumber * number=[NSNumber numberWithChar:0];
            [newBitmap->bitmap addObject:number];
        }
    }
    
    return newBitmap;
}


-(char)valueAtPosition:(CGPoint)position
{
    if(position.x>size.width||position.y>size.height)
    {
        NSLog(@"valueAtPosition: Out of Bounds");
        
    }
    long index=(position.y*size.width)+position.x;
    NSNumber * number=[bitmap objectAtIndex:index];
    char value=[number charValue];
    return value;
}


-(void)setValueAtPosition:(char)theValue forPosition:(CGPoint)position
{
    if(position.x>size.width||position.y>size.height)
    {
        NSLog(@"setValueAtPosition: Out of Bounds");
        
    }
    long index=(position.y*size.width)+position.x;
    NSNumber * number=[NSNumber numberWithChar:theValue];
    
    [bitmap replaceObjectAtIndex:index withObject:number];
}

-(void)setValueForRect:(char)theValue forRect:(CGRect)theRect
{

    if(CGRectContainsRect([self getBounds], theRect))
    {
        NSLog(@"in bounds");
        for(long y=theRect.origin.y;y<theRect.size.height+theRect.origin.y;y++)
        {
            for(long x=theRect.origin.x;x<theRect.size.width+theRect.origin.x;x++)
            {
                [self setValueAtPosition:theValue forPosition:CGPointMake(x, y)];
                
            }
        }
    }
    
    
}

-(void)fillWithValue:(char)theValue
{
    for(long y=0;y<size.height;y++)
    {
        for(long x=0;x<size.width;x++)
        {
            [self setValueAtPosition:theValue forPosition:CGPointMake(x, y)];
            
        }
    }
}

-(void)clear
{
    [self fillWithValue:0];
}


-(void)dump
{
    for(long y=0;y<size.height;y++)
    {
        for(long x=0;x<size.width;x++)
        {
            char value=[self valueAtPosition:CGPointMake(x, y)];
            printf("%c",value);
        }
        printf("\n");
    }
}




@end

@implementation BABooleanBitmap

+(BABooleanBitmap*)createWithCGSize:(CGSize)theSize
{
    
    BABooleanBitmap * newBBitmap=[[BABooleanBitmap alloc]init];
    newBBitmap->size=theSize;
    newBBitmap->bitmap = [[NSMutableArray alloc]init];
    
    for(long y=0;y<theSize.height;y++)
    {
        for(long x=0;x<theSize.width;x++)
        {
            long index=(y*theSize.width)+x;
            NSNumber * number=[NSNumber numberWithInt:0];
            [newBBitmap->bitmap addObject:number];
        }
    }    return newBBitmap;
}


-(BOOL)valueAtPosition:(CGPoint)position
{
    if(position.x>size.width||position.y>size.height)
    {
        NSLog(@"valueAtPosition: Out of Bounds");
        
    }
    
    
    long index=(position.y*size.width)+position.x;
    NSNumber * number=[bitmap objectAtIndex:index];
    BOOL value=[number boolValue];
    return value;
}


-(void)setValueAtPosition:(BOOL)theValue forPosition:(CGPoint)position
{
    if(position.x>size.width||position.y>size.height)
    {
        NSLog(@"setValueAtPosition: Out of Bounds");
        
    }
    long index=(position.y*size.width)+position.x;
    NSNumber * number=[NSNumber numberWithBool:theValue];
    
    [bitmap replaceObjectAtIndex:index withObject:number];
    
    //bitmap->
}

-(void)fillWithValue:(BOOL)theValue
{
    for(long y=0;y<size.height;y++)
    {
        for(long x=0;x<size.width;x++)
        {
            [self setValueAtPosition:theValue forPosition:CGPointMake(x, y)];
            
        }
    }
}

-(void)fillWithArray:(NSArray*)theArray
{
    //this is incomplete...Need to check size first
    
    for(long y=0;y<[self height];y++)
    {
        for(long x=0;x<[self width];x++)
        {
        long index=(y*[self height])+x;
            NSNumber * number=[theArray objectAtIndex:index];
            [self setValueAtPosition:[number boolValue] forPosition:CGPointMake(x, y)];
        }
    }
    
    
}

-(void)frameWithValue:(BOOL)theValue
{
    BOOL shouldFill=NO;
    for(int row=0; row < [self height]; row++)
     {
         //NSLog(@"RandomFill 2: %i",row);
        for(int column = 0; column < [self width]; column++)
        {
            // If coordinants lie on the the edge of the map (creates a border)
            shouldFill=NO;
            if(column == 0)
            {
                shouldFill=YES;
            }
            else if (row == 0)
            {
                shouldFill=YES;
            }
            else if (column == [self width]-1)
            {
                shouldFill=YES;
            }
            else if (row == [self height]-1)
            {
                shouldFill=YES;
            }
            // Else, fill with a wall a random percent of the time
            
            if(shouldFill)
            {
             [self setValueAtPosition:theValue forPosition:CGPointMake(column, row)];
        
            }
        }
    }
}

-(BABooleanBitmap*)inverse
{
    BABooleanBitmap * inverse=[BABooleanBitmap createWithCGSize:size];
    for(long y=0;y<[self height];y++)
    {
        for(long x=0;x<[self width];x++)
        {
        BOOL value=![self valueAtPosition:CGPointMake(x, y)];
        [inverse setValueAtPosition:value forPosition:CGPointMake(x, y)];
        }
    }
    
    
    return inverse;
    
}


-(void)clear
{
    [self fillWithValue:0];
}


-(void)dump
{
    for(long y=0;y<size.height;y++)
    {
        for(long x=0;x<size.width;x++)
        {
            BOOL value=[self valueAtPosition:CGPointMake(x, y)];
            printf("%i",value);
        }
        printf("\n");
    }
}
@end
