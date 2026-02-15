//
//  BAU7ChunkView.m
//  BAU7ChunkView
//
//  Created by Dan Brooker on 8/31/21.
//
#import "BAU7Objects.h"
#import "BAU7ChunkView.h"


#define MAXPASSES 16
#define BLIT 1
#define HEIGHTOFFSET 4

@implementation BAU7ChunkView

/**/
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    int chunksWide=(rect.size.width)/(CHUNKSIZE*TILESIZE);
    int chunksHigh=(rect.size.height)/(CHUNKSIZE*TILESIZE);
    
    CGPoint center=CGPointMake((rect.size.width+rect.origin.x)/2, (rect.size.height+rect.origin.y)/2);
    NSLog(@"Center: %f,%f",center.x,center.y);
    
    
    
    int startX=chunksWide/2;
    int startY=chunksHigh/2;
    
    
    NSLog(@"Rect: %f,%f, Center: %i,%i start: %i,%i",rect.size.width,rect.size.height, chunksWide,chunksHigh,startX,startY);
    switch (drawStyle) {
            
        case drawRawChunkStyle:
        {
            [self drawRawChunk:rawChunk forX:startX forY:startY];
        }
            break;
        case drawMapChunkStyle:
        {
            [self drawMapChunk:mapChunk forX:startX forY:startY];
        }
            break;
            
        default:
            break;
    }
}

-(id)init
{
    self=[super init];
    drawStyle=drawMapChunkStyle;
    mapChunk=NULL;
    rawChunk=NULL;
    return self;
}

-(void)setMapLocation:(CGPoint)thePoint
{
    mapLocation=thePoint;
    mapChunk=[environment mapChunkForLocation:thePoint];
    [self setNeedsDisplay];
}

-(void)setChunkID:(int)theID
{
    chunkID=theID;
    rawChunk=[environment chunkForID:chunkID];
    [self setNeedsDisplay];
}

-(void)setDrawStyle:(enum BAU7ChunkDrawStyle)theStyle
{
    drawStyle=theStyle;
}

-(void)drawRawChunk:(U7Chunk*)chunk forX:(int)x forY:(int)y
{
    //NSLog(@"drawChunk");
    //printf("drawChunk");
    //U7Chunk * chunk=[environment->U7Chunks objectAtIndex:mapChunk->masterChunkID];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, self.bounds);
    for(int pass=0;pass<2;pass++)
    {
    for(int tileY=0;tileY<CHUNKSIZE;tileY++)
        {
        for(int tileX=0;tileX<CHUNKSIZE;tileX++)
            {
                //U7Tile * tile=[chunk->chunkMap objectAtIndex:(y*16)+x];
                //NSLog(@"X: %i, Y:%i, chunkindex %i", tileY,tileY,(tileY*CHUNKSIZE)+tileX);
                U7ChunkIndex * chunkIndex=[chunk->chunkMap objectAtIndex:(tileY*CHUNKSIZE)+tileX];
                //[chunkIndex dump];
                U7Shape * shape;
               
                if(pass==0) //draw tiles
                    {
                        
                        shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
                        if(shape->tile)
                        {
                            shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
                            //shape=[U7Shapes objectAtIndex:chunkIndex->shapeIndex];
                            //printf("shape/frame: %li,",chunkIndex->shapeIndex);
                                if(chunkIndex->frameIndex > ([shape->frames count]-1))
                                    {
                                    //NSLog(@"Frame too big!");
                                    //shape=[U7Shapes objectAtIndex:0];
                                    //[self drawShape:shape forFrame:0 forX:tileX+(x*CHUNKSIZE) forY:tileY+(y*CHUNKSIZE) forZ:0];
                                    //[self drawShape:shape forFrame:0 forX:tileX forY:tileY];
                                    }
                                else
                                    {
                                    [self drawShape:shape forFrame:chunkIndex->frameIndex forX:tileX+(x*CHUNKSIZE) forY:tileY+(y*CHUNKSIZE)forZ:0  forPalletCycle:0];
                                }
                            }
                    }
                    else if(pass==1)  //draw ground shapes
                        {
                            
                        shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
                        if(!shape->tile)
                            {
                            shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
                            //NSLog(@"index too big!");
                            //shape=[U7Shapes objectAtIndex:0];
                            [self drawShape:shape forFrame:chunkIndex->frameIndex forX:tileX+(x*CHUNKSIZE) forY:tileY+(y*CHUNKSIZE)forZ:pass-1  forPalletCycle:0];
                            //[self drawShape:shape forFrame:0 forX:tileX forY:tileY];
                            }
                        }
                    }
                }
            }
    }

-(void)drawMapChunk:(U7MapChunk*)mapChunk forX:(int)x forY:(int)y
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, self.bounds);
    //NSLog(@"drawChunk");
    //printf("drawChunk");
    U7Chunk * chunk=[environment->U7Chunks objectAtIndex:mapChunk->masterChunkID];
    for(int pass=-1;pass<MAXPASSES;pass++)
    {
    for(int tileY=0;tileY<CHUNKSIZE;tileY++)
        {
        for(int tileX=0;tileX<CHUNKSIZE;tileX++)
            {
                //U7Tile * tile=[chunk->chunkMap objectAtIndex:(y*16)+x];
                //NSLog(@"X: %i, Y:%i, chunkindex %i", tileY,tileY,(tileY*CHUNKSIZE)+tileX);
                U7ChunkIndex * chunkIndex=[chunk->chunkMap objectAtIndex:(tileY*CHUNKSIZE)+tileX];
                //[chunkIndex dump];
                U7Shape * shape;
               
                if(pass==-1) //draw tiles
                    {
                        
                        shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
                        if(shape->tile)
                        {
                            shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
                            //shape=[U7Shapes objectAtIndex:chunkIndex->shapeIndex];
                            //printf("shape/frame: %li,",chunkIndex->shapeIndex);
                                if(chunkIndex->frameIndex > ([shape->frames count]-1))
                                    {
                                    //NSLog(@"Frame too big!");
                                    //shape=[U7Shapes objectAtIndex:0];
                                    //[self drawShape:shape forFrame:0 forX:tileX+(x*CHUNKSIZE) forY:tileY+(y*CHUNKSIZE) forZ:0];
                                    //[self drawShape:shape forFrame:0 forX:tileX forY:tileY];
                                    }
                                else
                                    {
                                    [self drawShape:shape forFrame:chunkIndex->frameIndex forX:tileX+(x*CHUNKSIZE) forY:tileY+(y*CHUNKSIZE)forZ:0  forPalletCycle:0];
                                }
                            }
                    }
                    else if(pass==0)  //draw ground shapes
                        {
                            
                        shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
                        if(!shape->tile)
                            {
                            shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
                            //NSLog(@"index too big!");
                            //shape=[U7Shapes objectAtIndex:0];
                            [self drawShape:shape forFrame:chunkIndex->frameIndex forX:tileX+(x*CHUNKSIZE) forY:tileY+(y*CHUNKSIZE)forZ:pass  forPalletCycle:0];
                            //[self drawShape:shape forFrame:0 forX:tileX forY:tileY];
                            }
                        U7ShapeReference * reference=[mapChunk staticShapeForLocation:CGPointMake(tileX, tileY) forHeight:pass];
                          if(reference)
                          {
                              
                              shape=[environment->U7Shapes objectAtIndex:reference->shapeID];
                              [self drawShape:shape forFrame:reference->currentFrame forX:tileX+(x*CHUNKSIZE) forY:tileY+(y*CHUNKSIZE)forZ:pass  forPalletCycle:0];
                          }
                        reference=[mapChunk gameShapeForLocation:CGPointMake(tileX, tileY) forHeight:pass];
                          if(reference)
                          {
                              
                              shape=[environment->U7Shapes objectAtIndex:reference->shapeID];
                              [self drawShape:shape forFrame:reference->currentFrame forX:tileX+(x*CHUNKSIZE) forY:tileY+(y*CHUNKSIZE)forZ:pass  forPalletCycle:0];
                          }
                        }
                    else
                    {
                        U7ShapeReference * reference=[mapChunk staticShapeForLocation:CGPointMake(tileX, tileY) forHeight:pass];
                          if(reference)
                          {
                              
                              shape=[environment->U7Shapes objectAtIndex:reference->shapeID];
                              [self drawShape:shape forFrame:reference->currentFrame forX:tileX+(x*CHUNKSIZE) forY:tileY+(y*CHUNKSIZE)forZ:pass forPalletCycle:0];
                          }
                        reference=[mapChunk gameShapeForLocation:CGPointMake(tileX, tileY) forHeight:pass];
                          if(reference)
                          {
                              
                              shape=[environment->U7Shapes objectAtIndex:reference->shapeID];
                              [self drawShape:shape forFrame:reference->currentFrame forX:tileX+(x*CHUNKSIZE) forY:tileY+(y*CHUNKSIZE)forZ:pass forPalletCycle:0];
                          }
                    }
                }
            }
        }
    }

-(void)drawShape:(U7Shape*)shape forFrame:(long)frame forX:(int)xPos forY:(int)yPos forZ:(int)zPos forPalletCycle:(int)palletCycle
{
    CGContextRef context = UIGraphicsGetCurrentContext();
   // CGContextClearRect(context, self.bounds);
    
    U7Bitmap * bitmap=[shape->frames objectAtIndex:frame];
    //UIImage *image = [[UIImage alloc]initWithCGImage:bitmap->CGImage];
    //UIImageView * imageView=[[UIImageView alloc]init];
    //imageView.contentMode=UIViewContentModeScaleAspectFit;
    //imageView.image=image;
    
    CGRect imageFrame=CGRectMake(0, 0, 0, 0);
    int cycleToDraw=0;
    if(bitmap->palletCycles)
        cycleToDraw=palletCycle%bitmap->palletCycles;
    
    
    CGImageRef CGImageToDraw;
    [[bitmap->CGImages objectAtIndex:cycleToDraw] getValue:&CGImageToDraw ];
    
    if(CGImageToDraw)
    {
        if(shape->tile)
        {

            imageFrame=CGRectMake(xPos*TILESIZE*TILEPIXELSCALE, yPos*TILESIZE*TILEPIXELSCALE, TILESIZE*TILEPIXELSCALE, TILESIZE*TILEPIXELSCALE);
            
        }
    else
        {
        imageFrame=CGRectMake(
            ((xPos+1)*TILESIZE*TILEPIXELSCALE)+([bitmap reverseTranslateX]*TILEPIXELSCALE)-(zPos*HEIGHTOFFSET),
            ((yPos+1)*TILESIZE*TILEPIXELSCALE)+([bitmap reverseTranslateY]*TILEPIXELSCALE)-(zPos*HEIGHTOFFSET),
            bitmap->width*TILEPIXELSCALE,
            bitmap->height*TILEPIXELSCALE);
       
        }
    //if(BLIT)
    {
        CGContextDrawImage(context,imageFrame,CGImageToDraw);
    }
        //else
        {
         //   imageView.frame=imageFrame;
         //   [self addSubview:imageView];
        }
        
        
     
    }
    else
    {
        
           NSLog(@"Bad Image");
    }
    
}


@end
