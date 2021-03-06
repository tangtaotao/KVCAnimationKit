//
//  TTAnimationModel.m
//  tension
//
//  Created by 唐韬 on 16/9/22.
//  Copyright © 2016年 TT. All rights reserved.
//

#import <UIKit/UIKit.h>


#import "TTCGModel.h"
#import "TTAnimationModel.h"
#import "NSObject+Extension.h"
#import "CGRect+Extension.h"


@interface TTAnimationModel(){

    void * _varAddress;
    IMP _imp;
    SEL _sel;

    void * _originalValue;
    void * _targetValue;
}

@property(nonatomic, strong) TTCGModel * cgModel;

@property(nonatomic, assign) TTBaseType valueType;
@property(nonatomic, copy) NSString * lastKey;
@property(nonatomic, weak) id objOfIvar;

@property(nonatomic, assign) NSUInteger timeCounter;

@end

@implementation TTAnimationModel

-(void)initialData {

    id targetObj = _animationObj;

    // 所有的key
    NSArray <NSString *> * keys = [self.keyPath componentsSeparatedByString:@"."];
    NSInteger charactorsCount = 0;
    _lastKey = keys.lastObject;

    for(int i = 0; i < keys.count; i++) {

        NSString * key = keys[i];
        self.objOfIvar     = targetObj;

        TTBaseType valueType = TTBaseTypeInvalid;
        BOOL isProperty = NO;
        valueType = [targetObj typeWithKey:key isProperty:&isProperty];

        if (valueType == TTBaseTypeIvarCGRect ||
            valueType == TTBaseTypeIvarCGPoint ||
            valueType == TTBaseTypeIvarCGSize ||
            valueType == TTBaseTypePropertyCGRect ||
            valueType == TTBaseTypePropertyCGPoint ||
            valueType == TTBaseTypePropertyCGSize ||
            i == keys.count - 1) {

            self.valueType = valueType;

            if (isProperty) {

                _originalValue = [[targetObj valueForKey:keys[i]] valueForBaseType:_valueType];
                _sel = [targetObj impSetter:&_imp property:key];

            } else {

                NSString * var     = [NSString stringWithFormat:@"_%@", key];
                Ivar ivar          = class_getInstanceVariable([targetObj class], [var UTF8String]);
                _originalValue = [targetObj getValueInIvar:ivar valueType:_valueType];
                _varAddress = [targetObj getIvarHead:ivar];
            }


            if (i == keys.count - 1) {

                _targetValue = [self.value valueForBaseType:_valueType];
            } else {

                CGKeyPathType cgType = CGTypeForKey([keys.lastObject UTF8String]);
                NSAssert(cgType != CGKeyPathTypeInvalid, @"the key %@ does not exist", keys.lastObject);
                void * original = CGValueForValueBaseTypeKeyPathType(_originalValue, valueType, cgType);
                void * target = [self.value valueForKeyPathType:cgType];
                TTCGModel * cgmoedel = [[TTCGModel alloc] initWithOriginal:original target:target keyPathTyep:cgType];
                self.cgModel = cgmoedel;
            }

            self.lastKey = [_keyPath substringFromIndex:charactorsCount];

            break;
        }

        charactorsCount += (key.length + 1);
        targetObj = [targetObj valueForKey:key];
        NSAssert1(targetObj != nil, @"the value for key %@ could not be nil.", key);
    }
}

-(NSUInteger)hashValue {

    if (_hashValue == 0) {
        _hashValue = [NSString stringWithFormat:@"%p.%@", _objOfIvar, _lastKey].hash;
    }
    return _hashValue;
}

- (BOOL) isEqualToModel:(TTAnimationModel *)model {

    return self.hashValue == model.hashValue;
}

- (void) animation {

    __weak typeof(self) weakSelf = self;
    [self.queue addOperationWithBlock:^{

        _timeCounter += 1;
        if (_timeCounter >= _animationDuration * 60) {
            
            [weakSelf setCurrentValueForProgress:1];

            if (_completion) {
                _completion();
            }
            [weakSelf.delegate animationModelDidFinish:weakSelf];
            return;
        }

        if (_timeCounter % self.frameInterval == 0) {
            double progress = _timeCounter / (_animationDuration * 60.0);
            [weakSelf setCurrentValueForProgress:progress];
        }

    }];
}

-(void) setCurrentValueForProgress:(double)progress {

    id currentObj = nil;

    switch (_valueType) {

        case TTBaseTypeIvarInt:
        case TTBaseTypePropertyInt:
        {
            int ori = *((int *)_originalValue);
            int tar = *((int *)_targetValue);
            int curr = ori + (tar - ori) * progress;

            if (_valueType == TTBaseTypeIvarInt) {
                memcpy(_varAddress, &curr, sizeof(int));
            } else {
                ((void (*)(id, SEL, int))_imp)(_objOfIvar, _sel, curr);
            }

            currentObj = @(curr);
            break;
        }

        case TTBaseTypeIvarUInt:
        case TTBaseTypePropertyUInt:
        {
            unsigned int ori = *((unsigned int *)_originalValue);
            unsigned int tar = *((unsigned int *)_targetValue);
            unsigned int curr = ori + (tar - ori) * progress;

            if (_valueType == TTBaseTypeIvarUInt) {
                memcpy(_varAddress, &curr, sizeof(unsigned int));
            } else {

                ((void (*)(id, SEL, long))_imp)(_objOfIvar, _sel, curr);
            }
            currentObj = @(curr);
            break;
        }

        case TTBaseTypeIvarLong:
        case TTBaseTypePropertyLong:
        {
            long ori = *((long *)_originalValue);
            long tar = *((long *)_targetValue);
            long curr = ori + (tar - ori) * progress;
            if (_valueType == TTBaseTypeIvarLong) {
                memcpy(_varAddress, &curr, sizeof(long));
            } else {
                ((void (*)(id, SEL, long))_imp)(_objOfIvar, _sel, curr);
            }
            currentObj = @(curr);
            break;

        }


        case TTBaseTypeIvarULong:
        case TTBaseTypePropertyULong:
        {

            unsigned long ori = *((unsigned long *)_originalValue);
            unsigned long tar = *((unsigned long *)_targetValue);
            unsigned long curr = ori + (tar - ori) * progress;
            if (_valueType == TTBaseTypeIvarULong) {
                memcpy(_varAddress, &curr, sizeof(unsigned long));
            } else {
                ((void (*)(id, SEL, unsigned long))_imp)(_objOfIvar, _sel, curr);
            }
            currentObj = @(curr);
            break;
        }

        case TTBaseTypeIvarLonglong:
        case TTBaseTypePropertyLonglong:
        {
            long long ori = *((long long *)_originalValue);
            long long tar = *((long long *)_targetValue);
            long long curr = ori + (tar - ori) * progress;
            if (_valueType == TTBaseTypeIvarLonglong) {
                memcpy(_varAddress, &curr, sizeof(long long));
            }else {

                ((void (*)(id, SEL, long long))_imp)(_objOfIvar, _sel, curr);
            }
            currentObj = @(curr);
            break;

        }

        case TTBaseTypeIvarULonglong:
        case TTBaseTypePropertyULonglong:
        {
            unsigned long long ori = *((unsigned long long *)_originalValue);
            unsigned long long tar = *((unsigned long long *)_targetValue);
            unsigned long long curr = ori + (tar - ori) * progress;
            if (_valueType == TTBaseTypeIvarULonglong) {
                memcpy(_varAddress, &curr, sizeof(unsigned long long));
            } else {
                ((void (*)(id, SEL, unsigned long long))_imp)(_objOfIvar, _sel, curr);
            }

            currentObj = @(curr);

            break;
        }


        case TTBaseTypeIvarFloat:
        case TTBaseTypePropertyFloat:
        {
            float ori = *((float *)_originalValue);
            float tar = *((float *)_targetValue);
            float curr = ori + (tar - ori) * progress;
            if (_valueType == TTBaseTypeIvarFloat) {

                memcpy(_varAddress, &curr, sizeof(float));
            } else {
                ((void (*)(id, SEL, float))_imp)(_objOfIvar, _sel, curr);
            }
            currentObj = @(curr);

            break;

        }

        case TTBaseTypeIvarDouble:
        case TTBaseTypePropertyDouble:
        {
            double ori = *((double *)_originalValue);
            double tar = *((double *)_targetValue);
            double curr = ori + (tar - ori) * progress;

            if (_valueType == TTBaseTypeIvarDouble) {

                memcpy(_varAddress, &curr, sizeof(double));
            } else {
                ((void (*)(id, SEL, double))_imp)(_objOfIvar, _sel, curr);
            }

            currentObj = @(curr);

            break;
        }

        case TTBaseTypeIvarCGRect:
        case TTBaseTypePropertyCGRect:
        {

            CGRect curr = CGRectZero;

            if (self.cgModel) {
                [self.cgModel getCurrentValue:&curr ForProgress:progress originalTopValue:_originalValue baseType:_valueType];
            } else {

                CGRect original = *((CGRect *)_originalValue);
                CGRect target = *((CGRect *)_targetValue);
                curr = CGRectFromOriginalToTargetWithProgress(original, target, progress);
            }

            if (_valueType == TTBaseTypeIvarCGRect) {
                memcpy(_varAddress, &curr, sizeof(CGRect));
            } else {
                ((void (*)(id, SEL, CGRect))_imp)(_objOfIvar, _sel, curr);
            }

            currentObj = [NSValue valueWithCGRect:curr];

            break;
        }

        case TTBaseTypeIvarCGPoint:
        case TTBaseTypePropertyCGPoint:
        {
            CGPoint curr = CGPointZero;

            if (self.cgModel) {
                [self.cgModel getCurrentValue:&curr ForProgress:progress originalTopValue:_originalValue baseType:_valueType];
            } else {

                CGPoint original = *((CGPoint *)_originalValue);
                CGPoint target = *((CGPoint *)_targetValue);
                curr = CGPointFromOriginalToTargetWithProgress(original, target, progress);
            }

            if (_valueType == TTBaseTypeIvarCGPoint) {

                memcpy(_varAddress, &curr, sizeof(CGPoint));
            } else {
                ((void (*)(id, SEL, CGPoint))_imp)(_objOfIvar, _sel, curr);
            }

            currentObj = [NSValue valueWithCGPoint:curr];

            break;

        }

        case TTBaseTypeIvarCGSize:
        case TTBaseTypePropertyCGSize:
        {
            CGSize curr = CGSizeZero;
            if (self.cgModel) {
                [self.cgModel getCurrentValue:&curr ForProgress:progress originalTopValue:_originalValue baseType:_valueType];
            } else {

                CGSize original = *((CGSize *)_originalValue);
                CGSize target = *((CGSize *)_targetValue);
                curr = CGSizeFromOriginalToTargetWithProgress(original, target, progress);
            }

            if (_valueType == TTBaseTypeIvarCGSize) {

                memcpy(_varAddress, &curr, sizeof(CGSize));
            } else {
                ((void (*)(id, SEL, CGSize))_imp)(_objOfIvar, _sel, curr);
            }

            currentObj = [NSValue valueWithCGSize:curr];
            break;
        }

        default:
            break;
    }

    if (_progress) {
        _progress(progress, currentObj);
    }

}

-(void)dealloc {

    free(_originalValue);
    free(_targetValue);
}


@end
