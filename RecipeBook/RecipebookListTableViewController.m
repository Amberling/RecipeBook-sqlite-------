/*
 1,2014.04.09 增加菜单删除功能，（重新运行时菜单恢复）；
 遗留问题：怎样彻底删除。
 2,利用sqlite3数据库存储和删除数据；（试试能不能成功）
 3,2041.04.10 添加删除功能的对应同步数据库数据删除 （OK）;(卸载掉app后数据可恢复和.plist相同)
 */
//  RecipebookListTableViewController.m
//  RecipeBook
//
//  Created by amber on 14-4-3.
//  Copyright (c) 2014年 amber. All rights reserved.
//

#define DBNAME      @"recipebook.sqlite"


#import "RecipebookListTableViewController.h"

@interface RecipebookListTableViewController ()
{
    NSMutableDictionary*dic;
    NSString *path;
}
@property (nonatomic, strong)NSUserDefaults *userDefaults;
@end

@implementation RecipebookListTableViewController
@synthesize recipebook;
@synthesize cellImages;
@synthesize prepareTime;

@synthesize userDefaults;


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self operationOnDatabase];

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    return self.recipebook.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.imageView.image = [UIImage imageNamed:self.cellImages[indexPath.row]];
    cell.detailTextLabel.text = self.prepareTime[indexPath.row];
    cell.textLabel.text = self.recipebook[indexPath.row];
    NSLog(@"cell.textlabel.text:%@",cell.textLabel.text);
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"recipeDetail"]) {
        NSIndexPath *indexPath = [self.tableview indexPathForSelectedRow];
        DetailViewController *detailViewController = segue.destinationViewController;
        detailViewController.title = recipebook[indexPath.row];
    }
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];//???
        
        //删除数组中元素，目的在cell不用再显示
        [self.recipebook removeObjectAtIndex:indexPath.row];
        [self.cellImages removeObjectAtIndex:indexPath.row];
        [self.prepareTime removeObjectAtIndex:indexPath.row];
        [tableView reloadData];
        
        //数据库中删除行,目的彻底删除数据
        [self deleteSql:indexPath.row];

        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"删除";
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//added 2014.04.09
#pragma mark - operation on database
- (void)operationOnDatabase
{
    //获取路径
    NSArray *recipePaths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory , NSUserDomainMask , YES);
    NSString *document = [recipePaths objectAtIndex:0];
    NSLog(@"doucumentpath:%@",document);
    recipePath = [document stringByAppendingString:DBNAME];
    NSLog(@"recipePath:%@",recipePath);

    //sqlite3_open([recipePath UTF8String], &recipeDB);
    
    if (sqlite3_open([recipePath UTF8String], &recipeDB) == SQLITE_OK) {
        NSLog(@"数据库打开成功");
    }else if (sqlite3_open([recipePath UTF8String], &recipeDB) != SQLITE_OK)
    {
        sqlite3_close(recipeDB);
        NSLog(@"数据库打开失败");
    }
    
    //创建数据库表
    NSString *recipeBookTable = @"CREATE TABLE IF NOT EXISTS tb_c_recipebook (id INTEGER PRIMARY KEY AUTOINCREMENT, RecipeName text, Thumbnail text, PrepTime text)";
    [self execSql:recipeBookTable];
    
    //如果第一次运行，插入数据
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"]) {
        [self inserteSql];
    }
    
    //查询并打印数据，读出数据放到数组中便于每次加载显示到tableviewcell中
    [self querySqlAndPrint];
    

}
//创建一个独立的执行sql语句的方法，传入sql语句，就执行sql语句
-(void)execSql:(NSString *)sql
{
    char *err;
    if (sqlite3_exec(recipeDB, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        sqlite3_close(recipeDB);
        NSLog(@"数据库操作数据失败");
    }
}
- (void)inserteSql
{
    //找到recipe.plist文件路径
    path = [[NSBundle mainBundle] pathForResource:@"recipe" ofType:@"plist"];
    
    //加载文件中的内容，并导入到array中(利用dictionary和array将plist中的数据导入到sqlite数据库中)
    dic = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    NSLog(@"初始化dic:%@",dic);
    NSArray *recipebookArray = [dic objectForKey:@"RecipeName"];
    NSArray *cellImageArray = [dic objectForKey:@"Thumbnail"];
    NSArray *prepareTimeArray = [dic objectForKey:@"PrepTime"];
    
    int count = self.recipebook.count;
    for (int i = 0 ; i < count; i++) {
        NSString *insertStrSql = [NSString stringWithFormat:@"INSERT INTO tb_c_recipebook ('RecipeName' , 'Thumbnail' , 'PrepTime' ) values ('%@' , '%@' , '%@' )",recipebookArray[i],cellImageArray[i],prepareTimeArray[i]];
        [self execSql:insertStrSql];
    }
}
- (void)deleteSql:(NSInteger)deleteRow
{
    NSString *sqlDelete =[NSString stringWithFormat:@"DELETE FROM tb_c_recipebook WHERE id = '%d'",deleteRow+1];//'%d'的单引号不能遗漏掉
    [self execSql:sqlDelete];
    NSLog(@"delete row %d",deleteRow);
}

- (void)querySqlAndPrint
{
    int count = 0;
    self.recipebook = [[NSMutableArray alloc] init];
    self.cellImages = [[NSMutableArray alloc] init];
    self.prepareTime = [[NSMutableArray alloc] init];
    
    NSString *sqlQuery = @"SELECT * FROM tb_c_recipebook";
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(recipeDB, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *RecipeName = (char*)sqlite3_column_text(statement, 1);
            NSString *recipeNameStr = [[NSString alloc]initWithUTF8String:RecipeName];
            
            char *Thumbnail = (char*)sqlite3_column_text(statement, 2);
            NSString *cellImageStr = [[NSString alloc]initWithUTF8String:Thumbnail];
            
            char *PrepTime = (char*)sqlite3_column_text(statement, 3);
            NSString *prepTimeStr = [[NSString alloc]initWithUTF8String:PrepTime];
            
            //从数据库中得到数据，初始化数组，目的显示到tableviewCell中
            self.recipebook[count] = recipeNameStr;
            NSLog(@"self.recipebook[%d]:%@",count,self.recipebook[count]);
            self.cellImages[count] = cellImageStr;
            self.prepareTime[count] = prepTimeStr;
            
            NSLog(@"RecipeName:%@ ; Thumbnail:%@ ; PrepTime:%@ ; ",recipeNameStr,cellImageStr,prepTimeStr);
            
            
            
            count ++;
        }
    }
    sqlite3_close(recipeDB);
}
@end
