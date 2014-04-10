//
//  RecipebookListTableViewController.h
//  RecipeBook
//
//  Created by amber on 14-4-3.
//  Copyright (c) 2014年 amber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewController.h"
#import "sqlite3.h"

@interface RecipebookListTableViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>
{
    sqlite3 *recipeDB;//数据库句柄,用于建立和数据库的连接
    NSString *recipePath;//储存数据库存放路径
}

@property (nonatomic, strong)NSMutableArray *recipebook;
@property (nonatomic, strong)NSMutableArray *cellImages;
@property (nonatomic, strong)NSMutableArray *prepareTime;

@property (nonatomic, strong)IBOutlet UITableView *tableview;


@end
