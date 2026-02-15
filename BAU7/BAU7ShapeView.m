//
//  BAU7ShapeView.m
//  BAU7ShapeView
//
//  Created by Dan Brooker on 9/6/21.
//

#import "BAU7Objects.h"
#import "BAU7ShapeView.h"

#define HEIGHTOFFSET 4
@implementation BAU7ShapeView

/**/
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    if([shape numberOfFrames]>0)
        [self drawShape:shape forFrame:currentFrame forX:0 forY:0 forZ:0];
    // Drawing code
}

-(id)init
{
    self=[super init];
    environment=NULL;
    animate=NO;
    currentFrame=0;
    showOrigin=NO;
    self.backgroundColor=[UIColor clearColor];
    return self;
}

-(void)setShapeID:(int)theShapeID
{
    if (!currentShapeLibrary) {
        NSLog(@"Error: currentShapeLibrary is nil. Call setEnvironment: or setShapeLibrary: first.");
        return;
    }
    
    if (theShapeID < 0 || theShapeID >= [currentShapeLibrary count]) {
        NSLog(@"Error: shapeID %d is out of bounds (0-%lu)", theShapeID, (unsigned long)[currentShapeLibrary count] - 1);
        return;
    }
    
    shapeID = theShapeID;
    shape = [currentShapeLibrary objectAtIndex:shapeID];
}

-(void)setEnvironment:(U7Environment*)theEnvironment
{
    if(theEnvironment)
    {
        environment=theEnvironment;
        currentShapeLibrary=environment->U7Shapes;
    }
}


-(void)setShapeLibrary:(NSMutableArray*)theLibrary
{
    if(theLibrary)
    {
        currentShapeLibrary=theLibrary;
    }
}

-(void)setFrameNumber:(int)frameNumber
{
    currentFrame=frameNumber;
}

-(CGSize)sizeForFrame:(int)frameNumber
{
    CGSize theSize=CGSizeMake(0, 0);
    if(shape)
        theSize=[shape sizeForFrame:frameNumber];
    else NSLog(@"Bad shape");
    return theSize;
}

-(long)numberOfFrames
{
    if(shape){
        NSLog(@"Number of Frames:%li",[shape numberOfFrames]);
        return [shape numberOfFrames];
    }
    else NSLog(@"Bad shape");
    return 0;
}

-(void)drawShape:(U7Shape*)shape forFrame:(int)frame forX:(int)xPos forY:(int)yPos forZ:(int)zPos
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, self.bounds);
    self.backgroundColor = [UIColor redColor];
    U7Bitmap * bitmap=[shape->frames objectAtIndex:frame];
    CGRect imageFrame=CGRectMake(0, 0, 0, 0);
    if(bitmap->CGImages)
    {
        if(shape->tile)
        {

            imageFrame=CGRectMake(xPos*TILESIZE*TILEPIXELSCALE, yPos*TILESIZE*TILEPIXELSCALE, TILESIZE*TILEPIXELSCALE, TILESIZE*TILEPIXELSCALE);
            
        }
    else
        {
        imageFrame=CGRectMake(xPos,yPos,bitmap->width,bitmap->height);
        }
    if(showOrigin)
        {
            //CGRect originFrame=CGRectMake(xPos*TILESIZE*TILEPIXELSCALE, yPos*TILESIZE*TILEPIXELSCALE, TILESIZE*TILEPIXELSCALE, TILESIZE*TILEPIXELSCALE);
            
            if(shape->notWalkable)
            {
               
                for(int ySize=0;ySize<shape->TileSizeYMinus1+1;ySize++)
                {
                    for(int xSize=0;xSize<shape->TileSizeXMinus1+1;xSize++)
                    {
                        
                        int newX=bitmap->width-bitmap->rightX-TILESIZE-((xSize)*TILESIZE);
                        int newY=bitmap->height-bitmap->bottomY-TILESIZE-((ySize)*TILESIZE);
                        //passability=[NSNumber numberWithInt:0];
                        //if(newX>=0&&newY>=0&&newX<CHUNKSIZE&&newY<CHUNKSIZE)
                            //[passabilityBitMap replaceObjectAtIndex:(newY*CHUNKSIZE)+newX withObject:passability];
                        CGRect originFrame=CGRectMake( newX,newY,TILESIZE,TILESIZE);
                        UIView *myBox  = [[UIView alloc] initWithFrame:originFrame];
                        myBox.backgroundColor = [UIColor clearColor];
                        myBox.layer.borderColor=[[UIColor blueColor]CGColor];
                        myBox.layer.borderWidth=1;
                        [self addSubview:myBox];
                        
                    }
                }
            }
            CGRect originFrame=CGRectMake( bitmap->width-bitmap->rightX-TILESIZE,bitmap->height-bitmap->bottomY-TILESIZE,TILESIZE,TILESIZE);
            UIView *myBox  = [[UIView alloc] initWithFrame:originFrame];
            myBox.backgroundColor = [UIColor clearColor];
            myBox.layer.borderColor=[[UIColor redColor]CGColor];
            myBox.layer.borderWidth=1;
            [self addSubview:myBox];
            
            
        }
  
    CGImageRef CGImageToDraw;
        [[bitmap->CGImages objectAtIndex:0] getValue:&CGImageToDraw ];
    CGContextDrawImage(context,imageFrame,CGImageToDraw);
 
    }
    else
    {
    NSLog(@"Bad Image");
    }
    
}
@end
