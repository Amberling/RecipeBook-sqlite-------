RecipeBook
=================================

1,显示菜单
其中包括：菜品名称、对应图片、准备菜具体时间

2，Storyboard
视图是通过storyboard显示，除了UItableview，又添加了检点的TabBar做练习，其中view转换数据传输是利用segue
传输（效率高，代码少，）

3，tableview操作
（1）storyboard中自定义tableviewcell
（2）cell中显示数据有三种方式：
	1，代码手动添加viewDidLoad中，手动逐个添加arry元素（代码量大，可扩展性低，不适应数据源很多			的情况）
	2，利用“.plist”加载数据；
	3，利用 sqlite 数据库（此方法最佳，但是导入数据需要以.plist为基础）
（3）删除单元行：目前自己的练习和尝试来看，只有利用数据库才能彻底删除数据；