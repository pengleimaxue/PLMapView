//
//  ViewController.m
//  PLMapView
//
//  Created by 万安 on 16/9/7.
//  Copyright © 2016年 penglei. All rights reserved.
//@abstract  作者Github址：https://github.com/pengleimaxue
//作者简书地址:http://www.jianshu.com/users/a0288e2a6b8e/latest_articles


#import "ViewController.h"
#import <MapKit/MapKit.h>


#define SCREEN_WIDTH                    CGRectGetWidth([UIScreen mainScreen].bounds)
#define SCREEN_HEIGHT                   CGRectGetHeight([UIScreen mainScreen].bounds)
#define CELL_HEIGHT                     55.f
#define CELL_COUNT                      5
#define TITLE_HEIGHT                    64.f
static NSString *SubCellIndentifier = @"Sub_Address_Cell";
@interface ViewController ()<MKMapViewDelegate,UITableViewDataSource,UISearchBarDelegate,UISearchDisplayDelegate,UITableViewDelegate>
//mapView


@property (nonatomic,strong)CLLocationManager *locationManager;
@property(nonatomic,strong)MKMapView *mapView;
@property(nonatomic,strong) UISearchDisplayController *searchDisplayController;
@property(nonatomic,strong)UISearchBar *searchBar;
@property(nonatomic,strong) NSMutableArray *searchResultArray;
@property(nonatomic,strong)UITableView *tableView;
@property(nonatomic,strong)NSMutableArray *dataRrray;
@property(nonatomic,assign)BOOL isFirstLocated;
@property(nonatomic,strong)CLPlacemark *dangQiang;//当前位置
@property(nonatomic,strong)UIButton *button;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
   
    self.locationManager=[[CLLocationManager alloc]init];;
   
    //判断当前设备定位服务是否打开
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"设备尚未打开定位服务");
    }
    
    //判断当前设备版本大于iOS8以后的话执行里面的方法
    if ([UIDevice currentDevice].systemVersion.floatValue >=8.0) {
        //持续授权
        // [locationManager requestAlwaysAuthorization];
        //当用户使用的时候授权
        [self.locationManager requestWhenInUseAuthorization];
    }
    if ([CLLocationManager authorizationStatus] ==kCLAuthorizationStatusDenied) {
        
        NSString *message = @"您的手机目前未开启定位服务，如欲开启定位服务，请至设定开启定位服务功能";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"无法定位" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alertView show];
        
    }
    //请求授权
    // [locationManager requestWhenInUseAuthorization];
    
    /*
     MKUserTrackingModeNone  不进行用户位置跟踪
     MKUserTrackingModeFollow  跟踪用户的位置变化
     MKUserTrackingModeFollowWithHeading  跟踪用户位置和方向变化
     */
    //设置用户的跟踪模式
    self.mapView.userTrackingMode=MKUserTrackingModeFollow;
    /*
     MKMapTypeStandard  标准地图
     MKMapTypeSatellite    卫星地图
     MKMapTypeHybrid      鸟瞰地图
     MKMapTypeSatelliteFlyover
     MKMapTypeHybridFlyover
     */
    self.mapView.mapType=MKMapTypeStandard;
    //实时显示交通路况
    self.mapView.showsTraffic=NO;
    //设置代理
    self.mapView.delegate=self;
    [self initMapView];
    [self initSearch];
    [self initTableView];
    
    
}
#pragma mark - 初始化
- (void)initMapView
{
    _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0,54, SCREEN_WIDTH, SCREEN_HEIGHT - CELL_HEIGHT*CELL_COUNT)];
    _mapView.delegate = self;
    // 不显示罗盘
    _mapView.showsCompass = NO;
    // 不显示比例尺
    _mapView.showsScale = NO;
    
    MKCoordinateSpan span=MKCoordinateSpanMake(0.021251, 0.016093);
    
    [self.mapView setRegion:MKCoordinateRegionMake(self.mapView.userLocation.coordinate, span) animated:YES];
    // 开启定位
    _mapView.showsUserLocation = YES;
    [self.view addSubview:_mapView];
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(lpgrClick:)];
    [_mapView addGestureRecognizer:lpgr];
}
- (void)initTableView
{
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_mapView.frame), SCREEN_WIDTH, CELL_HEIGHT*CELL_COUNT )];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _dataRrray = [[NSMutableArray alloc]initWithCapacity:0];
    [self.view addSubview:_tableView];
}
- (void)initSearch
{
    _searchResultArray = [NSMutableArray array];
    
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 10, SCREEN_WIDTH, 44)];
    _searchBar.delegate = self;
    _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
    _searchDisplayController.delegate = self;
    _searchDisplayController.searchResultsDelegate = self;
    _searchDisplayController.searchResultsDataSource = self;
    _searchDisplayController.searchResultsTableView.tableFooterView = [UIView new];
    // [_searchDisplayController.searchResultsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:SubCellIndentifier];
    [self.view addSubview:_searchBar];
    //    _searchController.searchBar.delegate = self;
    
    
    
}
/**
 *  跟踪到用户位置时会调用该方法
 *  @param mapView   地图
 *  @param userLocation 大头针模型
 */
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    if (userLocation&& !_isFirstLocated) {
        //创建编码对象
        CLGeocoder *geocoder=[[CLGeocoder alloc]init];
        //反地理编码
        [geocoder reverseGeocodeLocation:userLocation.location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            if (error!=nil || placemarks.count==0) {
                return ;
            }
            //获取地标
            CLPlacemark *placemark=[placemarks firstObject];
            //设置标题
            userLocation.title=placemark.locality;
            //设置子标题
            userLocation.subtitle=placemark.name;
            _dangQiang = placemark;
            [self fetchNearbyInfo:userLocation.location.coordinate.latitude andT:userLocation.location.coordinate.longitude];
        }];
        [_mapView setCenterCoordinate:CLLocationCoordinate2DMake(userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude)];
        _isFirstLocated = YES;
        
    }
    
}
- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error NS_AVAILABLE(10_9, 4_0){
    
    
    NSLog(@"定位失败");
    
}
//回到当前位置
- (IBAction)backCurrentLocation:(id)sender {
    
    MKCoordinateSpan span=MKCoordinateSpanMake(0.021251, 0.016093);
    
    [self.mapView setRegion:MKCoordinateRegionMake(self.mapView.userLocation.coordinate, span) animated:YES];
    
}



//缩小地图
- (IBAction)minMapView:(id)sender {
    
    //获取维度跨度并放大一倍
    CGFloat latitudeDelta = self.mapView.region.span.latitudeDelta * 2;
    //获取经度跨度并放大一倍
    CGFloat longitudeDelta = self.mapView.region.span.longitudeDelta * 2;
    //经纬度跨度
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    //设置当前区域
    MKCoordinateRegion region = MKCoordinateRegionMake(self.mapView.centerCoordinate, span);
    
    [self.mapView setRegion:region animated:YES];
}
//放大地图
- (IBAction)maxMapView:(id)sender {
    
    //获取维度跨度并缩小一倍
    CGFloat latitudeDelta = self.mapView.region.span.latitudeDelta * 0.5;
    //获取经度跨度并缩小一倍
    CGFloat longitudeDelta = self.mapView.region.span.longitudeDelta * 0.5;
    //经纬度跨度
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    //设置当前区域
    MKCoordinateRegion region = MKCoordinateRegionMake(self.mapView.centerCoordinate, span);
    
    [self.mapView setRegion:region animated:YES];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)fetchNearbyInfo:(CLLocationDegrees )latitude andT:(CLLocationDegrees )longitude

{

    CLLocationCoordinate2D location=CLLocationCoordinate2DMake(latitude, longitude);
    
    MKCoordinateRegion region=MKCoordinateRegionMakeWithDistance(location, 1 ,1 );
    
    MKLocalSearchRequest *requst = [[MKLocalSearchRequest alloc] init];
    requst.region = region;
    requst.naturalLanguageQuery = @"place"; //想要的信息
    MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:requst];
    [self.dataRrray removeAllObjects];
    [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error){
        if (!error)
        {
            //[_nearbyInfoArray addObjectsFromArray:response.mapItems];
            NSLog(@"%@",response.mapItems);
            for (MKMapItem *map in response.mapItems) {
                NSLog(@"%@",map.name);
            }
            [self.dataRrray addObjectsFromArray:response.mapItems];
            [self.tableView reloadData];
            //
        }
        else
        {
            //
        }
    }];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        return self.searchResultArray.count;
    }
    if (section == 0) {
        return 1;
    }else{
        return self.dataRrray.count;
    }
    
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        return 1;
    }
    return 2;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SubCellIndentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc]initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier:SubCellIndentifier];
            
        }
        
        CLPlacemark *placemark = self.searchResultArray[indexPath.row];
        cell.textLabel.text = placemark.name;
        return cell;
    }else{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell1"];
        if (!cell) {
            
            cell = [[UITableViewCell alloc]initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier:@"cell1"];
        }
        
        if (indexPath.section == 0) {
            
            cell.textLabel.text = _dangQiang.name;
        }else{
            MKMapItem *map = self.dataRrray [indexPath.row];
            
            cell.textLabel.text = map.placemark.name;
            //cell.detailTextLabel.text = map.phoneNumber;
        }
        return cell;
    }
    
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (tableView == self.searchDisplayController.searchResultsTableView ) {
        
        return nil;
        
    }
    UIView *VIew = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 40)];
    VIew.backgroundColor = [UIColor lightGrayColor];
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, SCREEN_WIDTH, 40)];
    label.text = @"附近位置";
    label.textColor = [UIColor darkGrayColor];
    UILabel *label1 = [[UILabel alloc]initWithFrame:CGRectMake(10, 20, SCREEN_WIDTH, 40)];
    label1.text = _dangQiang.name;
    label1.font = [UIFont systemFontOfSize:14.f];
    label1.numberOfLines = 2;
    if (section == 0) {
        label.text = @"当前位置";
    }
    [VIew addSubview:label];
    //[VIew addSubview:label1];
    return VIew;
    
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    if (tableView == self.searchDisplayController.searchResultsTableView   ) {
        
        return 1.f;;
        
    }
    
    return 40.f;
    
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    MKMapItem *map ;
    if (tableView == self.searchDisplayController.searchResultsTableView ) {
        CLPlacemark *placemark = self.searchResultArray[indexPath.row];
        map = [[MKMapItem alloc]initWithPlacemark:[[MKPlacemark alloc]initWithPlacemark:placemark]];
        [self.searchBar resignFirstResponder];
        
        [self.searchDisplayController setActive:NO];
    }else{
        
        
        map = self.dataRrray[indexPath.row];
    }
    [_mapView removeAnnotations:_mapView.annotations];
    
    // 将一个点转化为经纬度坐标
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(map.placemark.coordinate.latitude, map.placemark.coordinate.longitude);;
    MKPointAnnotation *pinAnnotation = [[MKPointAnnotation alloc] init];
    pinAnnotation.coordinate = center;
    pinAnnotation.title = @"长按";
    [_mapView setCenterCoordinate:CLLocationCoordinate2DMake(map.placemark.coordinate.latitude, map.placemark.coordinate.longitude)];
    //创建编码对象
    CLGeocoder *geocoder=[[CLGeocoder alloc]init];
    //反地理编码
    [geocoder reverseGeocodeLocation:map.placemark.location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (error!=nil || placemarks.count==0) {
            return ;
        }
        //获取地标
        CLPlacemark *placemark=[placemarks firstObject];
        //设置标题
        pinAnnotation.title=placemark.locality;
        //设置子标题
        pinAnnotation.subtitle=placemark.name;
        [_mapView addAnnotation:pinAnnotation];
        _dangQiang = placemark;
        [self fetchNearbyInfo:map.placemark.coordinate.latitude andT:map.placemark.coordinate.longitude];
    }];
    
    
    
    
}
#pragma mark -- Search Bar delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    CLGeocoder *geocoder=[[CLGeocoder alloc]init];
    //判断是否为空
    if (searchText.length ==0) {
        return;
    }
    [self.searchResultArray removeAllObjects];
    [geocoder geocodeAddressString:searchText completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (error!=nil || placemarks.count==0) {
            return ;
        }
        //创建placemark对象
        
        
        self.searchResultArray = [[NSMutableArray alloc]initWithArray:placemarks];
        //CLPlacemark *placemark=[self.searchResultArray firstObject];
        [self.searchDisplayController.searchResultsTableView reloadData];
        
        
    }];
    
    
}
// 每次添加大头针都会调用此方法  可以设置大头针的样式
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    // 判断大头针位置是否在原点,如果是则不加大头针
    if([annotation isKindOfClass:[mapView.userLocation class]])
        return nil;
    static NSString *annotationName = @"annotation";
    MKPinAnnotationView *anView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationName];
    if(anView == nil)
    {
        anView = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:annotationName];
    }
    anView.animatesDrop = YES;
    //    // 显示详细信息
    anView.canShowCallout = YES;
    //    anView.leftCalloutAccessoryView   可以设置左视图
    //    anView.rightCalloutAccessoryView   可以设置右视图
    return anView;
}

//长按添加大头针事件
- (void)lpgrClick:(UILongPressGestureRecognizer *)lpgr
{
    // 判断只在长按的起始点下落大头针
    if(lpgr.state == UIGestureRecognizerStateBegan)
    {
        [_mapView removeAnnotations:_mapView.annotations];
        // 首先获取点
        CGPoint point = [lpgr locationInView:_mapView];
        // 将一个点转化为经纬度坐标
        CLLocationCoordinate2D center = [_mapView convertPoint:point toCoordinateFromView:_mapView];
        MKPointAnnotation *pinAnnotation = [[MKPointAnnotation alloc] init];
        pinAnnotation.coordinate = center;
        pinAnnotation.title = @"长按";
        //创建编码对象
        CLGeocoder *geocoder=[[CLGeocoder alloc]init];
        //反地理编码
        [geocoder reverseGeocodeLocation:[[CLLocation alloc]initWithLatitude:center.latitude longitude:center.longitude] completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            if (error!=nil || placemarks.count==0) {
                return ;
            }
            //获取地标
            CLPlacemark *placemark=[placemarks firstObject];
            //设置标题
            pinAnnotation.title=placemark.locality;
            //设置子标题
            pinAnnotation.subtitle=placemark.name;
            [_mapView addAnnotation:pinAnnotation];
            _dangQiang = placemark;
            [self fetchNearbyInfo:center.latitude andT:center.longitude];
        }];
        
    }
    
}


//#pragma mark - 内存优化
//在移除self.map的同时，重新加载mapView，两行代码就可以达到释放内存的效果
-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    
    [self.mapView removeFromSuperview];
    [self.view addSubview:mapView];
    [self applyMapViewMemoryHotFix];
    
    
}
//- (void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//     self.mapView.showsUserLocation = NO;
//     self.mapView.delegate = nil;
//
//
//}
- (void)dealloc {
    self.mapView.showsUserLocation = NO;
    self.mapView.userTrackingMode  = MKUserTrackingModeNone;
    [self.mapView.layer removeAllAnimations];
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView removeFromSuperview];
    self.mapView.delegate = nil;
    self.mapView = nil;
}
- (void)applyMapViewMemoryHotFix{
    
    switch (self.mapView.mapType) {
        case MKMapTypeHybrid:
        {
            self.mapView.mapType = MKMapTypeStandard;
        }
            
            break;
        case MKMapTypeStandard:
        {
            self.mapView.mapType = MKMapTypeHybrid;
        }
            
            break;
        default:
            break;
    }
    
    
    self.mapView.mapType = MKMapTypeStandard;
    
    
    
}

@end
