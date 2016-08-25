//
//  XDGifLoading.m
//  XDGifLoading
//
//  Created by wenjunhuang on 15/8/15.
//  Copyright (c) 2015 wenjunhuang. All rights reserved.
//


#import "XDGifLoading.h"
#import "AppDelegate.h"
#import <ImageIO/ImageIO.h>


#define Size            130
#define FadeDuration    0.3
#define GifSpeed        0.3

#define APPDELEGATE     ((AppDelegate*)[[UIApplication sharedApplication] delegate])

#if __has_feature(objc_arc)
#define toCF (__bridge CFTypeRef)
#define fromCF (__bridge id)
#else
#define toCF (CFTypeRef)
#define fromCF (id)
#endif



#pragma mark - UIImage Animated GIF


@implementation UIImage (animatedGIF)

static int delayCentisecondsForImageAtIndex(CGImageSourceRef const source, size_t const i) {
    int delayCentiseconds = 1;
    CFDictionaryRef const properties = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
    if (properties) {
        CFDictionaryRef const gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
        if (gifProperties) {
            NSNumber *number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            if (number == NULL || [number doubleValue] == 0) {
                number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
            }
            if ([number doubleValue] > 0) {
                // 将gif毫秒延时转换为秒。
                delayCentiseconds = (int)lrint([number doubleValue] * 100);
            }
        }
        CFRelease(properties);
    }
    return delayCentiseconds;
}

static void createImagesAndDelays(CGImageSourceRef source, size_t count, CGImageRef imagesOut[count], int delayCentisecondsOut[count]) {
    for (size_t i = 0; i < count; ++i) {
        imagesOut[i] = CGImageSourceCreateImageAtIndex(source, i, NULL);
        delayCentisecondsOut[i] = delayCentisecondsForImageAtIndex(source, i);
    }
}

static int sum(size_t const count, int const *const values) {
    int theSum = 0;
    for (size_t i = 0; i < count; ++i) {
        theSum += values[i];
    }
    return theSum;
}

static int pairGCD(int a, int b) {
    if (a < b)
        return pairGCD(b, a);
    while (true) {
        int const r = a % b;
        if (r == 0)
            return b;
        a = b;
        b = r;
    }
}

static int vectorGCD(size_t const count, int const *const values) {
    int gcd = values[0];
    for (size_t i = 1; i < count; ++i) {
        gcd = pairGCD(values[i], gcd);
    }
    return gcd;
}

static NSArray *frameArray(size_t const count, CGImageRef const images[count], int const delayCentiseconds[count], int const totalDurationCentiseconds) {
    int const gcd = vectorGCD(count, delayCentiseconds);
    size_t const frameCount = totalDurationCentiseconds / gcd;
    UIImage *frames[frameCount];
    for (size_t i = 0, f = 0; i < count; ++i) {
        UIImage *const frame = [UIImage imageWithCGImage:images[i]];
        for (size_t j = delayCentiseconds[i] / gcd; j > 0; --j) {
            frames[f++] = frame;
        }
    }
    return [NSArray arrayWithObjects:frames count:frameCount];
}

static void releaseImages(size_t const count, CGImageRef const images[count]) {
    for (size_t i = 0; i < count; ++i) {
        CGImageRelease(images[i]);
    }
}

static UIImage *animatedImageWithAnimatedGIFImageSource(CGImageSourceRef const source) {
    size_t const count = CGImageSourceGetCount(source);
    CGImageRef images[count];
    int delayCentiseconds[count];
    createImagesAndDelays(source, count, images, delayCentiseconds);
    int const totalDurationCentiseconds = sum(count, delayCentiseconds);
    NSArray *const frames = frameArray(count, images, delayCentiseconds, totalDurationCentiseconds);
    UIImage *const animation = [UIImage animatedImageWithImages:frames duration:(NSTimeInterval)totalDurationCentiseconds / 100.0];
    releaseImages(count, images);
    return animation;
}

static UIImage *animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceRef CF_RELEASES_ARGUMENT source) {
    if (source) {
        UIImage *const image = animatedImageWithAnimatedGIFImageSource(source);
        CFRelease(source);
        return image;
    } else {
        return nil;
    }
}

+ (UIImage *)animatedImageWithAnimatedGIFData:(NSData *)data {
    return animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceCreateWithData(toCF data, NULL));
}

+ (UIImage *)animatedImageWithAnimatedGIFURL:(NSURL *)url {
    return animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceCreateWithURL(toCF url, NULL));
}

@end



#pragma mark - XDGifLoading Private

@interface XDGifLoading ()

+ (instancetype)instance;

@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIView *grayView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) BOOL shown;

@end



#pragma mark - XDGifLoading Implementation

@implementation XDGifLoading


#pragma mark Lifecycle

static XDGifLoading *instance;

+ (instancetype)instance {
    if (!instance) {
        instance = [[XDGifLoading alloc] init];
    }
    return instance;
}

- (instancetype)init {
    if ((self = [super initWithFrame:CGRectMake(0, 0, Size, Size)])) {
        
        [self setAlpha:0];
        [self setCenter:APPDELEGATE.window.center];
        [self setClipsToBounds:NO];
        
        [self.layer setBackgroundColor:[[UIColor colorWithWhite:0 alpha:0.0] CGColor]];
        [self.layer setCornerRadius:10];
        [self.layer setMasksToBounds:YES];
        
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectInset(self.bounds, 20, 20)];
        [self addSubview:self.imageView];
        
        [APPDELEGATE.window addSubview:self];
    }
    return self;
}



#pragma mark HUD

+ (void)showWithGray {
    [self dismiss:^{
        [APPDELEGATE.window addSubview:[[self instance] overlayView]];
        [APPDELEGATE.window addSubview:[[self instance] grayView]];
        [self show];
    }];
}

+ (void)showWithOverlay {
    [self dismiss:^{
        [APPDELEGATE.window addSubview:[[self instance] overlayView]];
        [self show];
    }];
}

+ (void)show {
    [self dismiss:^{
        [APPDELEGATE.window bringSubviewToFront:[self instance]];
        [[self instance] setShown:YES];
        [[self instance] fadeIn];
    }];
}

+ (void)dismiss {
    if (![[self instance] shown]){
        return;
    }
    [[[self instance] overlayView] removeFromSuperview];
    [[[self instance] grayView] removeFromSuperview];
    [[self instance] fadeOut];
}

+ (void)dismiss:(void(^)(void))complated {
    if (![[self instance] shown]){
        return complated ();
    }
    
    [[self instance] fadeOutComplate:^{
        [[[self instance] overlayView] removeFromSuperview];
        [[[self instance] grayView] removeFromSuperview];
        complated ();
    }];
}

#pragma mark Effects

- (void)fadeIn {
    [self.imageView startAnimating];
    [UIView animateWithDuration:FadeDuration animations:^{
        [self setAlpha:1];
    }];
}

- (void)fadeOut {
    [UIView animateWithDuration:FadeDuration animations:^{
        [self setAlpha:0];
    } completion:^(BOOL finished) {
        [self.imageView stopAnimating];
        [self setShown:NO];
    }];
}

- (void)fadeOutComplate:(void(^)(void))complated {
    [UIView animateWithDuration:FadeDuration animations:^{
        [self setAlpha:0];
    } completion:^(BOOL finished) {
        [self.imageView stopAnimating];
        [self setShown:NO];
        complated ();
    }];
}


- (UIView *)overlayView {
    
    if (!_overlayView) {
        _overlayView = [[UIView alloc] initWithFrame:APPDELEGATE.window.frame];
//        [_overlayView setBackgroundColor:[UIColor clearColor]];
        [_overlayView setBackgroundColor:[UIColor blackColor]];
        [_overlayView setAlpha:0];
        
        [UIView animateWithDuration:FadeDuration animations:^{
            [_overlayView setAlpha:0.3];
        }];
    }
    return _overlayView;
}

- (UIView *)grayView {
    if (!_grayView) {
        _grayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, Size - 20, Size - 20)];
        _grayView.backgroundColor = [UIColor blackColor];
        [_grayView setAlpha:0.5];
        [_grayView setCenter:APPDELEGATE.window.center];
        [_grayView setClipsToBounds:NO];
        
        [_grayView.layer setCornerRadius:10];
        [_grayView.layer setMasksToBounds:YES];
    }
    return _grayView;
}

#pragma mark Gif

+ (void)setGifWithImages:(NSArray *)images {
    [[[self instance] imageView] setAnimationImages:images];
    [[[self instance] imageView] setAnimationDuration:GifSpeed];
}

+ (void)setGifWithImageName:(NSString *)imageName {
    [[[self instance] imageView] stopAnimating];
    [[[self instance] imageView] setImage:[UIImage animatedImageWithAnimatedGIFURL:[[NSBundle mainBundle] URLForResource:imageName withExtension:nil]]];
}

+ (void)setGifWithURL:(NSURL *)gifUrl {
    [[[self instance] imageView] stopAnimating];
    [[[self instance] imageView] setImage:[UIImage animatedImageWithAnimatedGIFURL:gifUrl]];
}

@end
