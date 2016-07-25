//
//  ListDetailVC.m
//  WiFi_Souround
//
//  Created by Non on 16/7/21.
//  Copyright © 2016年 NonMac. All rights reserved.
//

#import "ListDetailVC.h"

@interface ListDetailVC ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ListDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:self.path]]];
}

@end
