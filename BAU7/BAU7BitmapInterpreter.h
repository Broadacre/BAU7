//
//  BAU7BitmapInterpreter.h
//  BAU7
//
//  Created by Dan Brooker on 12/11/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
enum BATileType{
  NoTileType=0,
    WaterTileType=1,
    AreaTileType=2,
    GrassTileType=3,
    WoodsTileType=4,
    MountainTileType=5,
    SolidRockTileType=6,
    SwampTileType=7,
    DesertTileType=8,
    JungleTileType=9,
    SnowTileType=10,
    InlandWaterTileType=11,
    
    //Outdoor paths
    WideRoadTileType=12,  //done
    NarrowRoadTileType=13, //done
    CarriagePathTileType=14,//done
    WidePathTileType=15,//done
    NarrowPathTileType=16,//done
    StreamPathTileType=17,  //incomplete - need 4 way
    RiverPathTileType=18, //incomplete - need 4 way, threeways and dead ends
    
    //Indoor paths
    DirtCavePassageTileType=19,  //done
    DungeonPassageTileType=20,  //done
    
    //Indoor Areas
    DirtCaveTileType,
    
    
    GrassToWater_North_TransitionTileType=100,
    GrassToWater_East_TransitionTileType,
    GrassToWater_South_TransitionTileType,
    GrassToWater_West_TransitionTileType,
    GrassToWater_InsideCorner_NorthEast_TransitionTileType,
    GrassToWater_InsideCorner_SouthEast_TransitionTileType,
    GrassToWater_InsideCorner_SouthWest_TransitionTileType,
    GrassToWater_InsideCorner_NorthWest_TransitionTileType,
    GrassToWater_OutsideCorner_NorthEast_TransitionTileType,
    GrassToWater_OutsideCorner_SouthEast_TransitionTileType,
    GrassToWater_OutsideCorner_SouthWest_TransitionTileType,
    GrassToWater_OutsideCorner_NorthWest_TransitionTileType,
    
    
    GrassToWoods_North_TransitionTileType,
    GrassToWoods_East_TransitionTileType,
    GrassToWoods_South_TransitionTileType,
    GrassToWoods_West_TransitionTileType,
    GrassToWoods_InsideCorner_NorthEast_TransitionTileType,
    GrassToWoods_InsideCorner_SouthEast_TransitionTileType,
    GrassToWoods_InsideCorner_SouthWest_TransitionTileType,
    GrassToWoods_InsideCorner_NorthWest_TransitionTileType,
    GrassToWoods_OutsideCorner_NorthEast_TransitionTileType,
    GrassToWoods_OutsideCorner_SouthEast_TransitionTileType,
    GrassToWoods_OutsideCorner_SouthWest_TransitionTileType,
    GrassToWoods_OutsideCorner_NorthWest_TransitionTileType,
    
    GrassToDesert_North_TransitionTileType,
    GrassToDesert_East_TransitionTileType,
    GrassToDesert_South_TransitionTileType,
    GrassToDesert_West_TransitionTileType,
    GrassToDesert_InsideCorner_NorthEast_TransitionTileType,
    GrassToDesert_InsideCorner_SouthEast_TransitionTileType,
    GrassToDesert_InsideCorner_SouthWest_TransitionTileType,
    GrassToDesert_InsideCorner_NorthWest_TransitionTileType,
    GrassToDesert_OutsideCorner_NorthEast_TransitionTileType,
    GrassToDesert_OutsideCorner_SouthEast_TransitionTileType,
    GrassToDesert_OutsideCorner_SouthWest_TransitionTileType,
    GrassToDesert_OutsideCorner_NorthWest_TransitionTileType,
    
    GrassToSwamp_North_TransitionTileType,
    GrassToSwamp_East_TransitionTileType,
    GrassToSwamp_South_TransitionTileType,
    GrassToSwamp_West_TransitionTileType,
    GrassToSwamp_InsideCorner_NorthEast_TransitionTileType,
    GrassToSwamp_InsideCorner_SouthEast_TransitionTileType,
    GrassToSwamp_InsideCorner_SouthWest_TransitionTileType,
    GrassToSwamp_InsideCorner_NorthWest_TransitionTileType,
    GrassToSwamp_OutsideCorner_NorthEast_TransitionTileType,
    GrassToSwamp_OutsideCorner_SouthEast_TransitionTileType,
    GrassToSwamp_OutsideCorner_SouthWest_TransitionTileType,
    GrassToSwamp_OutsideCorner_NorthWest_TransitionTileType,
    
    
    //Water to Grass
    WaterToGrass_North_TransitionTileType,
    WaterToGrass_East_TransitionTileType,
    WaterToGrass_South_TransitionTileType,
    WaterToGrass_West_TransitionTileType,
    WaterToGrass_InsideCorner_NorthEast_TransitionTileType,
    WaterToGrass_InsideCorner_SouthEast_TransitionTileType,
    WaterToGrass_InsideCorner_SouthWest_TransitionTileType,
    WaterToGrass_InsideCorner_NorthWest_TransitionTileType,
    WaterToGrass_OutsideCorner_NorthEast_TransitionTileType,
    WaterToGrass_OutsideCorner_SouthEast_TransitionTileType,
    WaterToGrass_OutsideCorner_SouthWest_TransitionTileType,
    WaterToGrass_OutsideCorner_NorthWest_TransitionTileType,
    
    //Water to Desert
    WaterToDesert_North_TransitionTileType,
    WaterToDesert_East_TransitionTileType,
    WaterToDesert_South_TransitionTileType,
    WaterToDesert_West_TransitionTileType,
    WaterToDesert_InsideCorner_NorthEast_TransitionTileType,
    WaterToDesert_InsideCorner_SouthEast_TransitionTileType,
    WaterToDesert_InsideCorner_SouthWest_TransitionTileType,
    WaterToDesert_InsideCorner_NorthWest_TransitionTileType,
    WaterToDesert_OutsideCorner_NorthEast_TransitionTileType,
    WaterToDesert_OutsideCorner_SouthEast_TransitionTileType,
    WaterToDesert_OutsideCorner_SouthWest_TransitionTileType,
    WaterToDesert_OutsideCorner_NorthWest_TransitionTileType,
    
    //Woods to Grass
    WoodsToGrass_Solo_TransitionTileType,
    
    WoodsToGrass_North_TransitionTileType,
    WoodsToGrass_East_TransitionTileType,
    WoodsToGrass_South_TransitionTileType,
    WoodsToGrass_West_TransitionTileType,
    
    WoodsToGrass_InsideCorner_NorthEast_TransitionTileType,
    WoodsToGrass_InsideCorner_SouthEast_TransitionTileType,
    WoodsToGrass_InsideCorner_SouthWest_TransitionTileType,
    WoodsToGrass_InsideCorner_NorthWest_TransitionTileType,
    
    WoodsToGrass_OutsideCorner_NorthEast_TransitionTileType,
    WoodsToGrass_OutsideCorner_SouthEast_TransitionTileType,
    WoodsToGrass_OutsideCorner_SouthWest_TransitionTileType,
    WoodsToGrass_OutsideCorner_NorthWest_TransitionTileType,
    
    //Swamp to Grass
    SwampToGrass_Solo_TransitionTileType,
    
    SwampToGrass_North_TransitionTileType,
    SwampToGrass_East_TransitionTileType,
    SwampToGrass_South_TransitionTileType,
    SwampToGrass_West_TransitionTileType,
    
    SwampToGrass_InsideCorner_NorthEast_TransitionTileType,
    SwampToGrass_InsideCorner_SouthEast_TransitionTileType,
    SwampToGrass_InsideCorner_SouthWest_TransitionTileType,
    SwampToGrass_InsideCorner_NorthWest_TransitionTileType,
    
    SwampToGrass_OutsideCorner_NorthEast_TransitionTileType,
    SwampToGrass_OutsideCorner_SouthEast_TransitionTileType,
    SwampToGrass_OutsideCorner_SouthWest_TransitionTileType,
    SwampToGrass_OutsideCorner_NorthWest_TransitionTileType,
    
    //Swamp to Water
    SwampToWater_North_TransitionTileType,
    SwampToWater_East_TransitionTileType,
    SwampToWater_South_TransitionTileType,
    SwampToWater_West_TransitionTileType,
    
    SwampToWater_InsideCorner_NorthEast_TransitionTileType,
    SwampToWater_InsideCorner_SouthEast_TransitionTileType,
    SwampToWater_InsideCorner_SouthWest_TransitionTileType,
    SwampToWater_InsideCorner_NorthWest_TransitionTileType,
    
    SwampToWater_OutsideCorner_NorthEast_TransitionTileType,
    SwampToWater_OutsideCorner_SouthEast_TransitionTileType,
    SwampToWater_OutsideCorner_SouthWest_TransitionTileType,
    SwampToWater_OutsideCorner_NorthWest_TransitionTileType,
    
    //Swamp to Mountain
    SwampToMountain_North_TransitionTileType,
    SwampToMountain_East_TransitionTileType,
    SwampToMountain_South_TransitionTileType,
    SwampToMountain_West_TransitionTileType,
    
    SwampToMountain_InsideCorner_NorthEast_TransitionTileType,
    SwampToMountain_InsideCorner_SouthEast_TransitionTileType,
    SwampToMountain_InsideCorner_SouthWest_TransitionTileType,
    SwampToMountain_InsideCorner_NorthWest_TransitionTileType,
    
    SwampToMountain_OutsideCorner_NorthEast_TransitionTileType,
    SwampToMountain_OutsideCorner_SouthEast_TransitionTileType,
    SwampToMountain_OutsideCorner_SouthWest_TransitionTileType,
    SwampToMountain_OutsideCorner_NorthWest_TransitionTileType,
    
#pragma mark Mountain To Grass
    // Mountain to Grass
    MountainToGrass_North_TransitionTileType,
    MountainToGrass_East_TransitionTileType,
    MountainToGrass_South_TransitionTileType,
    MountainToGrass_West_TransitionTileType,
    
    MountainToGrass_InsideCorner_NorthEast_TransitionTileType,
    MountainToGrass_InsideCorner_SouthEast_TransitionTileType,
    MountainToGrass_InsideCorner_SouthWest_TransitionTileType,
    MountainToGrass_InsideCorner_NorthWest_TransitionTileType,
    
    MountainToGrass_OutsideCorner_NorthEast_TransitionTileType,
    MountainToGrass_OutsideCorner_SouthEast_TransitionTileType,
    MountainToGrass_OutsideCorner_SouthWest_TransitionTileType,
    MountainToGrass_OutsideCorner_NorthWest_TransitionTileType,
    
#pragma mark Mountain To Water
    // Mountain to Water
    MountainToWater_North_TransitionTileType,
    MountainToWater_East_TransitionTileType,
    MountainToWater_South_TransitionTileType,
    MountainToWater_West_TransitionTileType,
    
    MountainToWater_InsideCorner_NorthEast_TransitionTileType,
    MountainToWater_InsideCorner_SouthEast_TransitionTileType,
    MountainToWater_InsideCorner_SouthWest_TransitionTileType,
    MountainToWater_InsideCorner_NorthWest_TransitionTileType,
    
    MountainToWater_OutsideCorner_NorthEast_TransitionTileType,
    MountainToWater_OutsideCorner_SouthEast_TransitionTileType,
    MountainToWater_OutsideCorner_SouthWest_TransitionTileType,
    MountainToWater_OutsideCorner_NorthWest_TransitionTileType,
    

    
#pragma mark Mountain To Swamp
    // Mountain to Swamp
    MountainToSwamp_North_TransitionTileType,
    MountainToSwamp_East_TransitionTileType,
    MountainToSwamp_South_TransitionTileType,
    MountainToSwamp_West_TransitionTileType,
    
    MountainToSwamp_InsideCorner_NorthEast_TransitionTileType,
    MountainToSwamp_InsideCorner_SouthEast_TransitionTileType,
    MountainToSwamp_InsideCorner_SouthWest_TransitionTileType,
    MountainToSwamp_InsideCorner_NorthWest_TransitionTileType,
    
    MountainToSwamp_OutsideCorner_NorthEast_TransitionTileType,
    MountainToSwamp_OutsideCorner_SouthEast_TransitionTileType,
    MountainToSwamp_OutsideCorner_SouthWest_TransitionTileType,
    MountainToSwamp_OutsideCorner_NorthWest_TransitionTileType,
    
#pragma mark Mountain To Desert
    // Mountain to Grass
    MountainToDesert_North_TransitionTileType,
    MountainToDesert_East_TransitionTileType,
    MountainToDesert_South_TransitionTileType,
    MountainToDesert_West_TransitionTileType,
    
    MountainToDesert_InsideCorner_NorthEast_TransitionTileType,
    MountainToDesert_InsideCorner_SouthEast_TransitionTileType,
    MountainToDesert_InsideCorner_SouthWest_TransitionTileType,
    MountainToDesert_InsideCorner_NorthWest_TransitionTileType,
    
    MountainToDesert_OutsideCorner_NorthEast_TransitionTileType,
    MountainToDesert_OutsideCorner_SouthEast_TransitionTileType,
    MountainToDesert_OutsideCorner_SouthWest_TransitionTileType,
    MountainToDesert_OutsideCorner_NorthWest_TransitionTileType,
    
#pragma mark Desert To Grass
    // Desert to Grass
    
    
    DesertToGrass_Solo_TransitionTileType,
    
    DesertToGrass_North_TransitionTileType,
    DesertToGrass_East_TransitionTileType,
    DesertToGrass_South_TransitionTileType,
    DesertToGrass_West_TransitionTileType,
    
    DesertToGrass_InsideCorner_NorthEast_TransitionTileType,
    DesertToGrass_InsideCorner_SouthEast_TransitionTileType,
    DesertToGrass_InsideCorner_SouthWest_TransitionTileType,
    DesertToGrass_InsideCorner_NorthWest_TransitionTileType,
    
    DesertToGrass_OutsideCorner_NorthEast_TransitionTileType,
    DesertToGrass_OutsideCorner_SouthEast_TransitionTileType,
    DesertToGrass_OutsideCorner_SouthWest_TransitionTileType,
    DesertToGrass_OutsideCorner_NorthWest_TransitionTileType,
    
#pragma mark Desert To Water
    // Desert to Water
    DesertToWater_North_TransitionTileType,
    DesertToWater_East_TransitionTileType,
    DesertToWater_South_TransitionTileType,
    DesertToWater_West_TransitionTileType,
    
    DesertToWater_InsideCorner_NorthEast_TransitionTileType,
    DesertToWater_InsideCorner_SouthEast_TransitionTileType,
    DesertToWater_InsideCorner_SouthWest_TransitionTileType,
    DesertToWater_InsideCorner_NorthWest_TransitionTileType,
    
    DesertToWater_OutsideCorner_NorthEast_TransitionTileType,
    DesertToWater_OutsideCorner_SouthEast_TransitionTileType,
    DesertToWater_OutsideCorner_SouthWest_TransitionTileType,
    DesertToWater_OutsideCorner_NorthWest_TransitionTileType,

#pragma mark Desert To Mountain
    // Desert to Mountain
    DesertToMountain_North_TransitionTileType,
    DesertToMountain_East_TransitionTileType,
    DesertToMountain_South_TransitionTileType,
    DesertToMountain_West_TransitionTileType,
    
    DesertToMountain_InsideCorner_NorthEast_TransitionTileType,
    DesertToMountain_InsideCorner_SouthEast_TransitionTileType,
    DesertToMountain_InsideCorner_SouthWest_TransitionTileType,
    DesertToMountain_InsideCorner_NorthWest_TransitionTileType,
    
    DesertToMountain_OutsideCorner_NorthEast_TransitionTileType,
    DesertToMountain_OutsideCorner_SouthEast_TransitionTileType,
    DesertToMountain_OutsideCorner_SouthWest_TransitionTileType,
    DesertToMountain_OutsideCorner_NorthWest_TransitionTileType,
    
    //StoneCave
    StoneCaveAreaTileType,//891,
    
    StoneCaveAreaNorthWallTileType,
    StoneCaveAreaSouthWallTileType,
    StoneCaveAreaEastWallTileType,
    StoneCaveAreaWestWallTileType,
    
    StoneCaveNorthEastCornerTileType,
    StoneCaveNorthWestCornerTileType,
    StoneCaveSouthEastCornerTileType,
    StoneCaveSouthWestCornerTileType,
    
    
    
    
    CavePassageNorthSouth_TileType, //1326,1325, 1628
    CavePassageEastWest_TileType, //1323, 1623, 2319, 1617, 1619, 1618
    CavePassageNorthToEast_TileType,//1322, 2019
    CavePassageNorthToWest_TileType, //1324, 2052,
    CavePassageSouthToEast_TileType, //1327, 1320, 2279
    CavePassageSouthToWest_TileType, //1591, 2278
    CavePassageIntersection_FourWay_TileType,//1264,2318
    CavePassageDeadEndWest_TileType, //1351
    CavePassageDeadEndEast_TileType, //1350, 1347, 1346
    CavePassageDeadEndNorth_TileType, //1340, 1341
    CavePassageDeadEndSouth_TileType, //1349, 1348, 1345,1344
    CaveCornerNorthWest_TileType, //2017, 2105
    CaveCornerNorthEast_TileType, //2018
    CaveCornerSouthWest_TileType, //2055, 2057
    CaveCornerSouthEast_TileType, //20158
    
    //Dirt Cave Passage
    

    DirtCavePassageNorthSouth_TileType, //1326,1325, 1628
    DirtCavePassageEastWest_TileType, //1323, 1623, 2319, 1617, 1619, 1618
    DirtCavePassageNorthToEast_TileType,//1322, 2019
    DirtCavePassageNorthToWest_TileType, //1324, 2052,
    DirtCavePassageSouthToEast_TileType, //1327, 1320, 2279
    DirtCavePassageSouthToWest_TileType, //1591, 2278
    DirtCavePassageIntersection_FourWay_TileType,//1264,2318
    DirtCavePassageDeadEndWest_TileType, //1351
    DirtCavePassageDeadEndEast_TileType, //1350, 1347, 1346
    DirtCavePassageDeadEndNorth_TileType, //1340, 1341
    DirtCavePassageDeadEndSouth_TileType, 
    DirtCavePassageNorthThreeWay_TileType,//1349, 1348, 1345,1344
    DirtCavePassageSouthThreeWay_TileType,
    DirtCavePassageEastThreeWay_TileType,
    DirtCavePassageWestThreeWay_TileType,
    
    
    
    DirtCaveCornerNorthWest_TileType, //2017, 2105
    DirtCaveCornerNorthEast_TileType, //2018
    DirtCaveCornerSouthWest_TileType, //2055, 2057
    DirtCaveCornerSouthEast_TileType, //20158
    
    
    
    DungeonTileType,
    
    DungeonAreaNorthWallTileType,
    DungeonAreaSouthWallTileType,
    DungeonAreaEastWallTileType,
    DungeonAreaWestWallTileType,
    
    
    DungeonCornerNorthWest_TileType, //2481
    DungeonCornerNorthEast_TileType, //2482
    DungeonCornerSouthWest_TileType, //2572
    DungeonCornerSouthEast_TileType, //2490
    
    DungeonNorthEastOutsideCornerBAAreaType,
    DungeonNorthWestOutsideCornerBAAreaType,
    DungeonSouthEastOutsideCornerBAAreaType,
    DungeonSouthWestOutsideCornerBAAreaType,
    
    DungeonSouthWestSouthEastOutsideCornerBAAreaType,
    DungeonNorthWestNorthEastOutsideCornerBAAreaType,
    DungeonNorthEastSouthEastOutsideCornerBAAreaType,
    DungeonNorthWestSouthWestOutsideCornerBAAreaType,
    DungeonNorthWestSouthEastOutsideCornerBAAreaType,
    DungeonSouthWestNorthEastOutsideCornerBAAreaType,
    
    DungeonNorthWestSouthWestSouthEastOutsideCornerBAAreaType,
    DungeonNorthEastSouthWestSouthEastOutsideCornerBAAreaType,
    DungeonNorthWestNorthEastSouthWestOutsideCornerBAAreaType,
    DungeonNorthWestNorthEastSouthEastOutsideCornerBAAreaType,
    DungeonFourWayOutsideCornerBAAreaType,
    
    DungeonDeadEndWest_TileType, //2497
    
    //Dungeon Passage
    DungeonPassageNorthSouth_TileType, //38
    DungeonPassageEastWest_TileType, //2473
    DungeonPassageNorthToEast_TileType,//2485
    DungeonPassageNorthToWest_TileType, //
    DungeonPassageSouthToEast_TileType, //2493
    DungeonPassageSouthToWest_TileType, //2494
    DungeonPassageIntersection_FourWay_TileType,// 2318
    DungeonPassageDeadEndWest_TileType, //
    DungeonPassageDeadEndEast_TileType, //2503
    DungeonPassageDeadEndNorth_TileType, //2509
    DungeonPassageDeadEndSouth_TileType,
    DungeonPassageNorthThreeWay_TileType,
    DungeonPassageSouthThreeWay_TileType,
    DungeonPassageEastThreeWay_TileType,
    DungeonPassageWestThreeWay_TileType,
    
    //2504, 2501
    
    //Wide Road
    WideRoadNorthSouth_TileType, //464,239
    WideRoadEastWest_TileType, //238,381
    WideRoadNorthToEast_TileType,//262
    WideRoadNorthToWest_TileType, //263
    WideRoadSouthToEast_TileType, //270
    WideRoadSouthToWest_TileType, //271
    WideRoadIntersection_FourWay_TileType,//234
    WideRoadDeadEndWest_TileType, //457
    WideRoadDeadEndEast_TileType, //459
    WideRoadDeadEndNorth_TileType, //458
    WideRoadDeadEndSouth_TileType, //456
    WideRoadNorthThreeWay_TileType,
    WideRoadSouthThreeWay_TileType,
    WideRoadEastThreeWay_TileType,
    WideRoadWestThreeWay_TileType,
    
    //Narrow Road
    NarrowRoadNorthSouth_TileType, //464,239
    NarrowRoadEastWest_TileType, //238,381
    NarrowRoadNorthToEast_TileType,//262
    NarrowRoadNorthToWest_TileType, //263
    NarrowRoadSouthToEast_TileType, //270
    NarrowRoadSouthToWest_TileType, //271
    NarrowRoadIntersection_FourWay_TileType,//234
    NarrowRoadDeadEndWest_TileType, //457
    NarrowRoadDeadEndEast_TileType, //459
    NarrowRoadDeadEndNorth_TileType, //458
    NarrowRoadDeadEndSouth_TileType, //456
    NarrowRoadNorthThreeWay_TileType,
    NarrowRoadSouthThreeWay_TileType,
    NarrowRoadEastThreeWay_TileType,
    NarrowRoadWestThreeWay_TileType,
    
    //CarriagePathTileType
    CarriagePathNorthSouth_TileType, //464,239
    CarriagePathEastWest_TileType, //238,381
    CarriagePathNorthToEast_TileType,//262
    CarriagePathNorthToWest_TileType, //263
    CarriagePathSouthToEast_TileType, //270
    CarriagePathSouthToWest_TileType, //271
    CarriagePathIntersection_FourWay_TileType,//234
    CarriagePathDeadEndWest_TileType, //457
    CarriagePathDeadEndEast_TileType, //459
    CarriagePathDeadEndNorth_TileType, //458
    CarriagePathDeadEndSouth_TileType, //456
    CarriagePathNorthThreeWay_TileType,
    CarriagePathSouthThreeWay_TileType,
    CarriagePathEastThreeWay_TileType,
    CarriagePathWestThreeWay_TileType,
    
    //WidePathTileType
    WidePathNorthSouth_TileType, //464,239
    WidePathEastWest_TileType, //238,381
    WidePathNorthToEast_TileType,//262
    WidePathNorthToWest_TileType, //263
    WidePathSouthToEast_TileType, //270
    WidePathSouthToWest_TileType, //271
    WidePathIntersection_FourWay_TileType,//234
    WidePathDeadEndWest_TileType, //457
    WidePathDeadEndEast_TileType, //459
    WidePathDeadEndNorth_TileType, //458
    WidePathDeadEndSouth_TileType, //456
    WidePathNorthThreeWay_TileType,
    WidePathSouthThreeWay_TileType,
    WidePathEastThreeWay_TileType,
    WidePathWestThreeWay_TileType,
    
    //NarrowPathTileType
    NarrowPathNorthSouth_TileType, //464,239
    NarrowPathEastWest_TileType, //238,381
    NarrowPathNorthToEast_TileType,//262
    NarrowPathNorthToWest_TileType, //263
    NarrowPathSouthToEast_TileType, //270
    NarrowPathSouthToWest_TileType, //271
    NarrowPathIntersection_FourWay_TileType,//234
    NarrowPathDeadEndWest_TileType, //457
    NarrowPathDeadEndEast_TileType, //459
    NarrowPathDeadEndNorth_TileType, //458
    NarrowPathDeadEndSouth_TileType, //456
    NarrowPathNorthThreeWay_TileType,
    NarrowPathSouthThreeWay_TileType,
    NarrowPathEastThreeWay_TileType,
    NarrowPathWestThreeWay_TileType,
    
    //StreamPathTileType
    StreamPathNorthSouth_TileType, //464,239
    StreamPathEastWest_TileType, //238,381
    StreamPathNorthToEast_TileType,//262
    StreamPathNorthToWest_TileType, //263
    StreamPathSouthToEast_TileType, //270
    StreamPathSouthToWest_TileType, //271
    StreamPathIntersection_FourWay_TileType,//234
    StreamPathDeadEndWest_TileType, //457
    StreamPathDeadEndEast_TileType, //459
    StreamPathDeadEndNorth_TileType, //458
    StreamPathDeadEndSouth_TileType, //456
    StreamPathNorthThreeWay_TileType,
    StreamPathSouthThreeWay_TileType,
    StreamPathEastThreeWay_TileType,
    StreamPathWestThreeWay_TileType,
    
    //RiverPathTileType
    RiverPathNorthSouth_TileType, //464,239
    RiverPathEastWest_TileType, //238,381
    RiverPathNorthToEast_TileType,//262
    RiverPathNorthToWest_TileType, //263
    RiverPathSouthToEast_TileType, //270
    RiverPathSouthToWest_TileType, //271
    RiverPathIntersection_FourWay_TileType,//234
    RiverPathDeadEndWest_TileType, //457
    RiverPathDeadEndEast_TileType, //459
    RiverPathDeadEndNorth_TileType, //458
    RiverPathDeadEndSouth_TileType, //456
    RiverPathNorthThreeWay_TileType,
    RiverPathSouthThreeWay_TileType,
    RiverPathEastThreeWay_TileType,
    RiverPathWestThreeWay_TileType,
    
    
   InvalidTileType=10000
    
};

enum BATransitionType
{
    NoTransitionType=0,
    
    NorthTransitionType,
    EastTransitionType,
    SourthTransitionType,
    WestTransitionType=4,
    
    InsideCornerNorthEastTransitionType,
    InsideCornerSouthEastTransitionType,
    InsideCornerSouthWestTransitionType,
    InsideCornerNorthWestTransitionType=8,
    
    OutSideCornerNorthEastTransitionType,
    OutSideCornerSouthEastTransitionType,
    OutSideCornerSouthWestTransitionType,
    OutSideCornerNorthWestTransitionType=12,
    
    ThreeSidedTranstionType,
    FourSidedTransitionType,
    TwoSidedOppositeTransitionType=15,
    
    //Path
    NoPathTransitionType=16,
    
    NorthSouth_PathTransitionType,
    EastWest_PathTransitionType,
    NorthToEast_PathTransitionType,
    NorthToWest_PathTransitionType,
    SouthToEast_PathTransitionType,
    SouthToWest_PathTransitionType,
    
    Intersection_FourWay_PathTransitionType=23,
    DeadEndWest_PathTransitionType,
    DeadEndEast_PathTransitionType,
    DeadEndNorth_PathTransitionType,
    DeadEndSouth_PathTransitionType,
    ThreeWayNorthPathTransitionType,
    ThreeWaySouthPathTransitionType,
    ThreeWayEastPathTransitionType,
    ThreeWayWestPathTransitionType,
    
    InvalidTransitionType=1000
    
};

enum BAPathType
{
    NoPathType=0,
    NorthSouth_PathType,
    EastWest_PathType,
    NorthToEast_PathType,
    NorthToWest_PathType,
    SouthToEast_PathType,
    SouthToWest_PathType,
    Intersection_FourWay_PathType,
    DeadEndWest_PathType,
    DeadEndEast_PathType,
    DeadEndNorth_PathType,
    DeadEndSouth_PathType,
    ThreeWayNorthPathType,
    ThreeWaySouthPathType,
    ThreeWayEastPathType,
    ThreeWayWestPathType
    
};

enum BAAreaType
{
    NoBAAreaType=0,
    FourWayAreaType,
    
    NorthWallBAAreaType,
    SouthWallBAAreaType,
    EastWallBAAreaType,
    WestWallBAAreaType,
    
    NorthEastCornerBAAreaType,
    NorthWestCornerBAAreaType,
    SouthEastCornerBAAreaType,
    SouthWestCornerBAAreaType,
    
    NorthEastOutsideCornerBAAreaType,
    NorthWestOutsideCornerBAAreaType,
    SouthEastOutsideCornerBAAreaType,
    SouthWestOutsideCornerBAAreaType,
    
    SouthWestSouthEastOutsideCornerBAAreaType,
    NorthEastSouthEastOutsideCornerBAAreaType,
    NorthWestSouthWestOutsideCornerBAAreaType,
    NorthWestNorthEastOutsideCornerBAAreaType,
    NorthWestSouthEastOutsideCornerBAAreaType,
    SouthWestNorthEastOutsideCornerBAAreaType,
    
    NorthWestSouthWestSouthEastOutsideCornerBAAreaType,
    NorthEastSouthWestSouthEastOutsideCornerBAAreaType,
    NorthWestNorthEastSouthWestOutsideCornerBAAreaType,
    NorthWestNorthEastSouthEastOutsideCornerBAAreaType,
    
    FourWayOutsideCornerBAAreaType,
};

enum BATileSetType
{
    noTileSetType,
    dirtCaveTileSetType,
    stoneCaveTileSetType,
    dungeonTileSetType,
    pavedRoadTileSetType
};

@interface BATileComparator : NSObject
{
  @public
    BOOL North;
    BOOL NorthEast;
    BOOL East;
    BOOL SouthEast;
    BOOL South;
    BOOL SouthWest;
    BOOL West;
    BOOL NorthWest;
    
    //Data for mixed
    BOOL mixed;
    enum BATileType lastTileType;
    enum BATileType fromTileType;
    enum BATileType testTileType;
};
-(void)compareBitmapTiletype:(BAIntBitmap*)bitmap aPosition:(CGPoint)position forType:(enum BATileType)tileType ;
-(void)reset;
-(void)dump;
@end

@interface BAU7BitmapInterpreter : NSObject
{
    U7Environment * environment;
}
-(BOOL)setEnvironment:(U7Environment*)theEnvironment;
-(BOOL)IsOutOfBounds:(BABitmap*)bitmap atX:(int)x atY:(int)y;
-(BOOL)IsTileType:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y forTileType:(enum BATileType)tileType;
-(enum BATransitionType)transitionTypeForTile:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y fromTileType:(enum BATileType)fromType toTileType:(enum BATileType)toType invalidateMixed:(BOOL)invalidMixed;

-(enum BATileType)TileTypeForTransitionType:(enum BATileType)fromType toTileType:(enum BATileType)toType forTransition:(enum BATransitionType)transitionType;



-(U7Shape*)shapeReferenceForTileType:(enum BATileType)tileType;
//-(BOOL)IsTileType:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y forTileType:(enum BATileType)tileType;
-(enum BATileType)TileTypeForSymbol:(NSString*)theSymbol;
-(int)chunkIDForTileType:(enum BATileType)tileType;
-(BAIntBitmap*)tileBitmapForDungeon:(BAIntBitmap*)dungeonBitmap;
-(enum BAPathType)pathTypeForTile:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y fromTileType:(enum BATileType)pathType;

-(enum BAAreaType)areaTypeForTile:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y fromTileType:(enum BATileType)areaType;
-(enum BATileType)tileTypeForAreaType:(enum BAAreaType)areaType forEnvironmentType:(enum BATileSetType)tileSetType;
-(BAIntBitmap*)transitionBitmapForBaseBitmap:(BAIntBitmap*)baseBitmap;
-(enum BATileType)TileTypeForAtTransitionPosition:(BAIntBitmap*)bitmap  atPosition:(CGPoint)position fromTileType:(enum BATileType)fromType toTileType:(enum BATileType)toType forTransition:(enum BATransitionType)transitionType;
@end

NS_ASSUME_NONNULL_END
