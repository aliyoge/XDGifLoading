//
//  ViewController.m
//  XDGifLoading
//
//  Created by wenjunhuang on 15/8/15.
//  Copyright © 2016年 kongkongss. All rights reserved.
//

#import "ViewController.h"
#import "XDGifLoading.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    HUD_SHOW()
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
