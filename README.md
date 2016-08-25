# XDGifLoading

###方便好用的使用gif作为loading动画。
![](demo.gif)

```Objective-C
@interface XDGifLoading : UIView

+ (void)show;
+ (void)showWithOverlay;
+ (void)showWithGray;

+ (void)dismiss;

+ (void)setGifWithImages:(NSArray *)images;
+ (void)setGifWithImageName:(NSString *)imageName;
+ (void)setGifWithURL:(NSURL *)gifUrl;

@end
###使用方法
```Objective-C
//show
[XDGifLoading setGifWithImageName:@"loading.gif"]; [XDGifLoading showWithOverlay];
//dismiss
[XDGifLoading dismiss];
```