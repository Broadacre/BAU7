//
//  U7CharacterSprite.m
//  BAU7
//
//  Created by Dan Brooker on 9/26/21.
//
#import "U7CharacterSprite.h"
#import <Foundation/Foundation.h>

enum U7CharacterSprite randomHumanSpriteID(void)
{
    int rando=arc4random_uniform(30);
    
    switch (rando) {
        case 0:
            return HermitMaleCharacterSprite;
            break;
        case 1:
            return HoodedRobedCharacterSprite;
            break;
        case 2:
            return NudeManCharacterSprite;
            break;
        case 3:
            return NudeWomanCharacterSprite;
            break;
        case 4:
            return KnightCharacterSprite;
            break;
        case 5:
            return NobleMaleCharacterSprite;
            break;
        case 6:
            return TradesmanCharacterSprite;
            break;
        case 7:
            return HoodedRobedTwoCharacterSprite;
            break;
        case 8:
            return PeasantMaleCharacterSprite;
            break;
        case 9:
            return GuardCharacterSprite;
            break;
        case 10:
            return PirateMaleCharacterSprite;
            break;
        case 11:
            return BatlinCharacterSprite;
            break;
        case 12:
            return HermitFemaleCharacterSprite;
            break;
        case 13:
            return HoodedRobedFemaleCharacterSprite;
            break;
        case 14:
            return NobleMaleTwoCharacterSprite;
            break;
        case 16:
            return MerchantFemaleTwoCharacterSprite;
            break;
        case 17:
            return MerchantMaleTwoCharacterSprite;
            break;
        case 18:
            return NobleFemaleTwoCharacterSprite;
            break;
        case 19:
            return PirateMaleTwoCharacterSprite;
            break;
        case 20:
            return PirateMaleThreeCharacterSprite;
            break;
        case 21:
            return PirateFemaleCharacterSprite;
            break;
        case 22:
            return RangerMaleCharacterSprite;
            break;
        case 23:
            return RangerFemaleCharacterSprite;
            break;
        case 24:
            return FighterMaleCharacterSprite;
            break;
        case 25:
            return FighterFemaleCharacterSprite;
            break;
        case 26:
            return KnightMaleTwoCharacterSprite;
            break;
        case 27:
            return IoloCharacterSprite;
            break;
        case 28:
            return BrtishCharacterSprite;
            break;
        case 42:
            return JesterCharacterSprite;
            break;
        case 29:
            return MerchantMaleThreeCharacterSprite;
            break;
       
        default:
            break;
    }
    return AvatarMaleCharacterSprite;
}

enum U7CharacterSprite randomCharacterSpriteID(void)
{
    int rando=arc4random_uniform(115);
    
    switch (rando) {
        case 0:
            return HermitMaleCharacterSprite;
            break;
        case 1:
            return WingedGargoyleCharacterSprite;
            break;
        case 2:
            return HoodedRobedCharacterSprite;
            break;
        case 3:
            return NudeManCharacterSprite;
            break;
        case 4:
            return NudeWomanCharacterSprite;
            break;
        case 5:
            return BohemothCharacterSprite;
            break;
        case 6:
            return KnightCharacterSprite;
            break;
        case 7:
            return NobleMaleCharacterSprite;
            break;
        case 8:
            return WingedGargoyleTwoCharacterSprite;
            break;
        case 9:
            return FemaleGhostCharacterSprite;
            break;
        case 10:
            return TradesmanCharacterSprite;
            break;
        case 11:
            return MaleGhostCharacterSprite;
            break;
        case 12:
            return HoodedRobedTwoCharacterSprite;
            break;
        case 13:
            return PeasantMaleCharacterSprite;
            break;
        case 14:
            return GhostCharacterSprite;
            break;
        case 15:
            return LichKingCharacterSprite;
            break;
        case 16:
            return UnicornCharacterSprite;
            break;
        case 17:
            return CyclopsCharacterSprite;
            break;
        case 18:
            return HydraCharacterSprite;
            break;
        case 19:
            return PixieCharacterSprite;
            break;
        case 20:
            return GuardCharacterSprite;
            break;
        case 21:
            return PirateMaleCharacterSprite;
            break;
        case 22:
            return BatlinCharacterSprite;
            break;
        case 23:
            return HermitMaleTwoCharacterSprite;
            break;
        case 24:
            return HermitFemaleCharacterSprite;
            break;
        case 25:
            return HoodedRobedFemaleCharacterSprite;
            break;
        case 26:
            return PeasantCrutchesCharacterSprite;
            break;
        case 27:
            return PeasantLeglessCharacterSprite;
            break;
        case 28:
            return NobleMaleTwoCharacterSprite;
            break;
        case 29:
            return MerchantFemaleTwoCharacterSprite;
            break;
        case 30:
            return MerchantMaleTwoCharacterSprite;
            break;
        case 31:
            return NobleFemaleTwoCharacterSprite;
            break;
        case 32:
            return PirateMaleTwoCharacterSprite;
            break;
        case 33:
            return PirateMaleThreeCharacterSprite;
            break;
        case 34:
            return PirateFemaleCharacterSprite;
            break;
        case 35:
            return RangerMaleCharacterSprite;
            break;
        case 36:
            return RangerFemaleCharacterSprite;
            break;
        case 37:
            return FighterMaleCharacterSprite;
            break;
        case 38:
            return FighterFemaleCharacterSprite;
            break;
        case 39:
            return KnightMaleTwoCharacterSprite;
            break;
        case 40:
            return IoloCharacterSprite;
            break;
        case 41:
            return BrtishCharacterSprite;
            break;
        case 42:
            return JesterCharacterSprite;
            break;
        case 43:
            return MerchantMaleThreeCharacterSprite;
            break;
        case 44:
            return PirateFemaleTwoCharacterSprite;
            break;
        case 45:
            return PeasantChildCharacterSprite;
            break;
        case 46:
            return NobleChildCharacterSprite;
            break;
        case 47:
            return WingedGargoyleThreeCharacterSprite;
            break;
        case 48:
            return WinglessGargoyleCharacterSprite;
            break;
        case 49:
            return HorseCharacterSprite;
            break;
        case 50:
            return FoxNecklaceCharacterSprite;
            break;
        case 51:
            return MouseNecklaceCharacterSprite;
            break;
        case 52:
            return EmpCharacterSprite;
            break;
        case 53:
            return WingedGargoyleFourCharacterSprite;
            break;
        case 54:
            return BatlinTwoCharacterSprite;
            break;
        case 55:
            return DewRagMerchantCharacterSprite;
            break;
        case 56:
            return ShaminoCharacterSprite;
            break;
        case 57:
            return FighterMaleTwoCharacterSprite;
            break;
        case 58:
            return SpikeCharacterSprite;
            break;
        case 59:
            return FemaleRobedCharacterSprite;
            break;
        case 60:
            return SlugCharacterSprite;
            break;
        case 61:
            return CrocCharacterSprite;
            break;
        case 62:
            return BatCharacterSprite;
            break;
        case 63:
            return BeeCharacterSprite;
            break;
        case 64:
            return CatCharacterSprite;
            break;
        case 65:
            return DogCharacterSprite;
            break;
        case 66:
            return ChickenCharacterSprite;
            break;
        case 67:  //need to fix!
            return ChickenCharacterSprite;
            //return RoperCharacterSprite;
            break;
        case 68:
            return CowCharacterSprite;
            break;
        case 69:
            return CyclopsTwoCharacterSprite;
            break;
        case 70:
            return DeerCharacterSprite;
            break;
        case 71:
            return RedDragoCharacterSprite;
            break;
        case 72:
            return GreenDrakeCharacterSprite;
            break;
        case 73:
            return HookCharacterSprite;
            break;
        case 74:
            return FoxCharacterSprite;
            break;
        case 75:
            return PhaserCharacterSprite;
            break;
        case 76:
            return GremlinCharacterSprite;
            break;
        case 77:
            return HeadlessCharacterSprite;
            break;
        case 78:
            return GnatCharacterSprite;
            break;
        case 79:
            return SkeletonMageCharacterSprite;
            break;
        case 80:
            return MouseCharacterSprite;
            break;
        case 81:
            return RatCharacterSprite;
            break;
        case 82:
            return ReaperCharacterSprite;
            break;
        case 83:
            return NessieCharacterSprite;
            break;
        case 84:
            return SkeletonCharacterSprite;
            break;
        case 85:
            return SnakeCharacterSprite;
            break;
        case 86:
            return HarpyCharacterSprite;
            break;
        case 87:
            return TrollCharacterSprite;
            break;
        case 88:
            return WispCharacterSprite;
            break;
        case 89:
            return SeaTentacleCharacterSprite;
            break;
        case 90:
            return WolfCharacterSprite;
            break;
        case 91:
            return FlyingMonkeyCharacterSprite;
            break;
        case 92:
            return ScorpionCharacterSprite;
            break;
        case 93:
            return DoveCharacterSprite;
            break;
        case 94:
            return GuardMaleCharacterSprite;
            break;
        case 95:
            return AvatarMaleCharacterSprite;
            break;
        case 96:
            return HorseTwoCharacterSprite;
            break;
        case 97:
            return StoneHarpyCharacterSprite;
            break;
        case 98:
            return WinglessGargoyleTwoCharacterSprite;
            break;
        case 99:
            return GuardFemaleCharacterSprite;
            break;
        case 100:
            return TrollTwoCharacterSprite;
            break;
        case 101:
            return ToddlerCharacterSprite;
            break;
        case 102:
            return SpiderCharacterSprite;
            break;
        case 103:
            return NobleFemaleCharacterSprite;
            break;
        case 104:
            return NobleMaleThreeCharacterSprite;
            break;
        case 105:
            return WinglessGargoyleThreeCharacterSprite;
            break;
        case 106:
            return MerchantMaleCharacterSprite;
            break;
        case 107:
            return BarkeepFemaleCharacterSprite;
            break;
        case 108:
            return GuardFemaleTwoCharacterSprite;
            break;
        case 109:
            return HoodedSkeletonMageCharacterSprite;
            break;
        case 110:
            return MerchantMaleFourCharacterSprite;
            break;
        case 111:
            return PeasantChildTwoCharacterSprite;
            break;
        case 112:
            return SheepCharacterSprite;
            break;
        case 113:
            return AvatarFemaleCharacterSprite;
            break;
        case 114:
            return GolemCharacterSprite;
            break;
        default:
            break;
    }
    return AvatarMaleCharacterSprite;
 
}


int speedForCharacterSprite(enum U7CharacterSprite theType)
{
    return 1;
    switch (theType) {
                  
        case BohemothCharacterSprite:
        case UnicornCharacterSprite:
        case CyclopsCharacterSprite:
        case HydraCharacterSprite:
        case HorseCharacterSprite:
        case FoxNecklaceCharacterSprite:
        case MouseNecklaceCharacterSprite:
        case BatCharacterSprite:
        case BeeCharacterSprite:
        case CatCharacterSprite:
        case CrocCharacterSprite:
        case DogCharacterSprite:
        case RoperCharacterSprite:
        case CowCharacterSprite:
        case CyclopsTwoCharacterSprite:
        case DeerCharacterSprite:
        case RedDragoCharacterSprite:
        case GreenDrakeCharacterSprite:
        case FoxCharacterSprite:
        case PhaserCharacterSprite:
        case GnatCharacterSprite:
        case MouseCharacterSprite:
        case RatCharacterSprite:
        case NessieCharacterSprite:
        case SnakeCharacterSprite:
        case HarpyCharacterSprite:
        case TrollCharacterSprite:
        case WispCharacterSprite:
        case SeaTentacleCharacterSprite:
        case WolfCharacterSprite:
        case FlyingMonkeyCharacterSprite:
        case ScorpionCharacterSprite:
        case DoveCharacterSprite:
        case HorseTwoCharacterSprite:
        case StoneHarpyCharacterSprite:
        case SpiderCharacterSprite:
        case SheepCharacterSprite:
        case GolemCharacterSprite:
            return 2;
            break;
        default:
            break;
    }
    
    return 1;
}
