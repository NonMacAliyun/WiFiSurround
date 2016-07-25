//
//  RecordListVC.m
//  WiFi_Souround
//
//  Created by Non on 16/7/21.
//  Copyright © 2016年 NonMac. All rights reserved.
//

#import "RecordListVC.h"
#import "ListDetailVC.h"

@interface RecordListVC ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation RecordListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
}

#pragma -mark UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sourceSum integerValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellID"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%ld.txt", indexPath.row + 1];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ListDetailVC *LDVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ListDetailVC"];
    LDVC.path = [NSString stringWithFormat:@"%@/Documents/%ld.txt",NSHomeDirectory(), indexPath.row];
    [self.navigationController pushViewController:LDVC animated:YES];
}

@end
