//
//  enums.h
//  BAU7
//
//  Created by Dan Brooker on 6/2/22.
//

#ifndef enums_h
#define enums_h

enum BAMapDrawMode
{
    NormalMapDrawMode=0,
    MiniMapDrawMode=1
};

enum BACardinalDirection
{
    NorthCardinalDirection=0,
    NorthEastCardinalDirection=1,
    EastCardinalDirection=2,
    SouthEastCardinalDirection=3,
    SouthCardinalDirection=4,
    SouthWestCardinalDirection=5,
    WestCardinalDirection=6,
    NorthWestCardinalDirection=7
    
};

enum BASpawnType
{
    NoBASpawnType=0,
    ResourceBASpawnType=1,
    NPCBASpawnType=2
};

enum BAActorType
{
    NoActorBAActorType=0
};
enum BASpriteType
{
    NoBASpriteType=0,
    ActorBASpriteType,
    ResourceBASpriteType,
};

enum BAResourceType
{
    NoResourceType=0,
    StoneResourceType=1,
    WoodResourceType=2,
    TreeResourceType=3,
    BoulderResourceType=4,
    BeverageResourceType,
    FoodResourceType,
    
};
enum BANeeds
{
    NoBANeeds=0,
    
};

enum BAState
{
    NoBAState=0,
    ActionInProgressBAState=1,
    RestBAState=2,
    FindFoodBAState=3,
    FindDrinkBAState=4,
    FindResourceBAState=5,
    FindShelterBAState=6,
    FleeBAState=7,
    FindWoodBAState,
    AttackLikeAManiacBAState,
    DeadBAState,
    
    UserControlBAState,
    
    RandomWanderBAState=1000
};

enum BAEnvironmentType
{
    NoBAEnvironmentType=0,
    WaterBAEnvironmentType=1,
    GrassBAEnvironmentType=2,
    RoadBAEnvironmentType=3,
    FloorBAEnvironmentType=4,
    GrassAndDirtBAEnvironmentType=5,
    DirtBAEnvironmentType=7,
    DirtAndRockBAEnvironmentType=8,
    DirtAndSandBAEnvironmentType=9,
    DirtAndWaterBAEnvironmentType=10,
    GrassAndWaterBAEnvironmentType=11,
    SandAndWaterBAEnvironmentType=12,
    DirtAndSwampBAEnvironmentType=13,
    SwampBAEnvironmentType=14,
    GrassAndSandBAEnvironmentType=15
};

enum SpriteFrameAction
{
    StandNorthFrameAction=0,
    StepRightNorth=1,
    StepLeftNorth=2,
    ReadyNorth=3,
    AttackOneHandNorthOne=4,
    AttackOneHandNorthTwo=5,
    AttackOneHandNorthThree=6,
    AttackTwoHandNorthOne=7,
    AttackTwoHandNorthTwo=8,
    AttackTwoHandNorthThree=9,
    SitNorth=10,
    BowNorth=11,
    KneelNorth=12,
    LayNorth=13,
    SpecialNorthOne=14,
    SpecialNorthTwo=15,
    
    StandSouthFrameAction=16,
    StepRightSouth=17,
    StepLeftSouth=18,
    ReadySouth=19,
    AttackOneHandSouthOne=20,
    AttackOneHandSouthTwo=21,
    AttackOneHandSouthThree=22,
    AttackTwoHandNSouthOne=23,
    AttackTwoHandSouthTwo=24,
    AttackTwoHandSouthThree=25,
    SitSouth=26,
    BowSouth=27,
    KneelSouth=28,
    LaySouth=29,
    SpecialSouthOne=30,
    SpecialSouthTwo=31
    
};



enum AnimationSequenceType
{
    IdleNorthAnimationSequenceType,
    IdleSouthAnimationSequenceType,
    IdleEastAnimationSequenceType,
    IdleWestAnimationSequenceType,
    
    WalkNorthAnimationSequenceType,
    WalkSouthAnimationSequenceType,
    WalkWestAnimationSequenceType,
    WalkEastAnimationSequenceType,
    
    AttackOneHandedNorthAnimationSequenceType,
    AttackOneHandedSouthAnimationSequenceType,
    AttackOneHandedEastAnimationSequenceType,
    AttackOneHandedWestAnimationSequenceType,
    
    AttackTwoHandedNorthAnimationSequenceType,
    AttackTwoHandedSouthAnimationSequenceType,
    AttackTwoHandedEastAnimationSequenceType,
    AttackTwoHandedWestAnimationSequenceType,
    
    PerformSpecialNorthAnimationSequenceType,
    PerformSpecialSouthAnimationSequenceType,
    PerformSpecialEastAnimationSequenceType,
    PerformSpecialWestAnimationSequenceType,
    
    BowNorthAnimationSequenceType,
    BowSouthAnimationSequenceType,
    BowEastAnimationSequenceType,
    BowWestAnimationSequenceType,
    
    BowRecoverNorthAnimationSequenceType,
    BowRecoverSouthAnimationSequenceType,
    BowRecoverEastAnimationSequenceType,
    BowRecoverWestAnimationSequenceType,
    
    KneelNorthAnimationSequenceType,
    KneelSouthAnimationSequenceType,
    KneelEastAnimationSequenceType,
    KneelWestAnimationSequenceType,
    
    KneelRecoverNorthAnimationSequenceType,
    KneelRecoverSouthAnimationSequenceType,
    KneelRecoverEastAnimationSequenceType,
    KneelRecoverWestAnimationSequenceType,
    
    SitNorthAnimationSequenceType,
    SitSouthAnimationSequenceType,
    SitEastAnimationSequenceType,
    SitWestAnimationSequenceType,
    
    SitRecoverNorthAnimationSequenceType,
    SitRecoverSouthAnimationSequenceType,
    SitRecoverEastAnimationSequenceType,
    SitRecoverWestAnimationSequenceType,
    
    LayNorthAnimationSequenceType,
    LaySouthAnimationSequenceType,
    LayEastAnimationSequenceType,
    LayWestAnimationSequenceType,
    
};



#endif /* enums_h */
