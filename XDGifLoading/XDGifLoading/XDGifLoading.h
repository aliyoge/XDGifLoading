//
//  XDGifLoading.h
//  XDGifLoading
//
//  Created by wenjunhuang on 15/8/15.
//  Copyright (c) 2015 wenjunhuang. All rights reserved.
//

#import <UIKit/UIKit.h>

#define HUD_SHOW() [XDGifLoading setGifWithImageName:@"loading.gif"]; [XDGifLoading showWithOverlay];
#define HUD_HIDE() [XDGifLoading dismiss];

@interface XDGifLoading : UIView

+ (void)show;
+ (void)showWithOverlay;
+ (void)showWithGray;

+ (void)dismiss;

+ (void)setGifWithImages:(NSArray *)images;
+ (void)setGifWithImageName:(NSString *)imageName;
+ (void)setGifWithURL:(NSURL *)gifUrl;

@end
