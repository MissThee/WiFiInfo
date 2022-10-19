#import "WiFiInfo.h"
#include <dlfcn.h>
// 获取wifi ip地址
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <objc/runtime.h>


// ------------------------------------------------------------------------------------------------------------------------

static WiFiManagerRef wifiManager()
{
	static WiFiManagerRef manager;
	if(!manager) {
		manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0);
	}
	return manager;
}



static NSString* stringForSecurityMode(int securityMode)
{
	switch(securityMode)
	{
		case kCWSecurityNone:
			return nil;
		case kCWSecurityWEP:
			return @"WEP";
		case kCWSecurityWPAPersonal:
			return @"WPA-PSK";
		case kCWSecurityWPAPersonalMixed:
			return @"WPA-PSK/Mix";
		case kCWSecurityWPA2Personal:
			return @"WPA2-PSK";
		case kCWSecurityPersonal:
			return @"PSK";
		case kCWSecurityDynamicWEP:
			return @"WEP/Dync";
		case kCWSecurityWPAEnterprise:
			return @"WPA";
		case kCWSecurityWPAEnterpriseMixed:
			return @"WPA/Mix";
		case kCWSecurityWPA2Enterprise:
			return @"WPA2";
		case kCWSecurityEnterprise:
			return @"WPA";
	}
	return nil;
}

/*
// 获取当前wifi ip地址
static NSString* getIPAddress ()
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    // retrieve the current interfaces - returns 0 on success
    if (getifaddrs(&interfaces) == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}
*/
// -------

static NSArray* networksList;
static WFNetworkScanRecord* currNetwork;

static WFNetworkScanRecord* networkForName(NSString* name)
{
	@try {
		if(networksList) {
			for(WFNetworkScanRecord* netNow in networksList) {
				if(netNow.ssid && [netNow.ssid isEqualToString:name]) {
					return netNow;
				}
			}
		}
		if(currNetwork) {
			if(currNetwork.ssid && [currNetwork.ssid isEqualToString:name]) {
				return currNetwork;
			}
		}
	} @catch(NSException* ex) {
	}
	return nil;
}


%hook WFNetworkListCell
%property (nonatomic, retain) id labelSec;
%property (nonatomic, retain) id labelRssi;
%property (nonatomic, retain) id labelChannel;
%property (nonatomic, retain) id labelMac;
%property (nonatomic, retain) id network;
%property (nonatomic,copy) NSString * macTmp; // mac地址
%property (nonatomic,copy) NSString * subtitleTmp; 


- (void)setSubtitle:(NSString*)arg1{
	if(arg1!=nil){
		self.subtitleTmp=arg1;
	}
	arg1 = [NSString stringWithFormat:@"%@%@",self.macTmp, self.subtitleTmp?[NSString stringWithFormat:@"\n%@",self.subtitleTmp]:@""];
	%orig;
}

- (void)layoutSubviews
{
	@try {
		self.network = networkForName(self.title);

		if(self.network) {
			// mac地址--------------------
			self.macTmp = self.network.bssid;
			[self setSubtitle:nil];
			UIImageView* _lockView = (UIImageView *)object_getIvar(self, class_getInstanceVariable([self class], "_lockImageView"));
			// lock icon
			if(_lockView) {
				// --------------------
				if(!self.labelSec) {
					self.labelSec = (UILabel *)[_lockView viewWithTag:4455]?:[[UILabel alloc] init];
					self.labelSec.tag = 4455;
				}
				[self.labelSec setText:nil];
				self.labelSec.center = _lockView.center;
				self.labelSec.frame = CGRectMake((0 - (30 / 3)), _lockView.frame.size.height + 3, 30, 10);
				[self.labelSec setText:stringForSecurityMode([self.network securityMode])];
				[self.labelSec setBackgroundColor:[UIColor clearColor]];
				[self.labelSec setNumberOfLines:0];
				self.labelSec.font = [UIFont systemFontOfSize:7];
				self.labelSec.textAlignment = NSTextAlignmentCenter;
				self.labelSec.adjustsFontSizeToFitWidth = YES;
				if([_lockView viewWithTag:4455]==nil) {
					[_lockView addSubview:self.labelSec];
				}
			}
			// signal icon
			UIImageView* _barsView = (UIImageView *)object_getIvar(self, class_getInstanceVariable([self class], "_signalImageView"));
			if(_barsView) {
				// --------------------
				if(!self.labelRssi) {
					self.labelRssi = (UILabel *)[_barsView viewWithTag:4456]?:[[UILabel alloc] init];
					self.labelRssi.tag = 4456;
				}
				[self.labelRssi setText:nil];
				self.labelRssi.center = _barsView.center;
				self.labelRssi.frame = CGRectMake(0, _barsView.frame.size.height-3 , _barsView.frame.size.width, 10);
				NSString* rssiSignal = nil;
				@try {
					rssiSignal = [@([self.network rssi]) stringValue];
				} @catch(NSException* ex) {
				}
				[self.labelRssi setText:rssiSignal];
				[self.labelRssi setBackgroundColor:[UIColor clearColor]];
				[self.labelRssi setNumberOfLines:0];
				self.labelRssi.font = [UIFont systemFontOfSize:10];
				self.labelRssi.textAlignment = NSTextAlignmentCenter;
				self.labelRssi.adjustsFontSizeToFitWidth = YES;
				if([_barsView viewWithTag:4456]==nil) {
					[_barsView addSubview:self.labelRssi];
				}
				// --------------------
				if(!self.labelChannel) {
					self.labelChannel = (UILabel *)[_barsView viewWithTag:4457]?:[[UILabel alloc] init];
					self.labelChannel.tag = 4457;
				}
				[self.labelChannel setText:nil];
				self.labelChannel.center = _barsView.center;
				self.labelChannel.frame = CGRectMake(0, 0-5 , _barsView.frame.size.width, 10);
				NSString* canNumber = nil;
				@try {
					canNumber = [[self.network channel] stringValue];
					if(canNumber) {
						canNumber = [NSString stringWithFormat:@"%@", canNumber];
					}
				} @catch(NSException* ex) {
				}
				[self.labelChannel setText:canNumber];
				[self.labelChannel setBackgroundColor:[UIColor clearColor]];
				[self.labelChannel setNumberOfLines:0];
				self.labelChannel.font = [UIFont systemFontOfSize:10];
				self.labelChannel.textAlignment = NSTextAlignmentCenter;
				self.labelChannel.adjustsFontSizeToFitWidth = YES;
				if([_barsView viewWithTag:4457]==nil) {
					[_barsView addSubview:self.labelChannel];
				}
				// --------------------
				// if(!self.labelMac) {
				// 	self.labelMac = (UILabel *)[_barsView viewWithTag:4458]?:[[UILabel alloc] init];
				// 	self.labelMac.tag = 4458;
				// }
				// [self.labelMac setText:nil];
				// //self.labelMac.center = _barsView.center;
				// self.labelMac.frame = CGRectMake(20, 20, 200, 8);
				// NSString* macAddr = nil;
				// @try {
				// 	macAddr = self.network.bssid;
				// } @catch(NSException* ex) {
				// }
				// [self.labelMac setText:macAddr];
				// [self.labelMac setBackgroundColor:[UIColor clearColor]];
				// [self.labelMac setNumberOfLines:0];
				// self.labelMac.font = [UIFont systemFontOfSize:10];
				// self.labelMac.textAlignment = NSTextAlignmentLeft;
				// self.labelMac.adjustsFontSizeToFitWidth = YES;
				// if([_barsView viewWithTag:4458]==nil) {
				// 	[_barsView addSubview:self.labelMac];
				// }
			}
		
		}
	}@catch(NSException* ex) {
	}
	
	%orig;
	
}
%end

 
static WFNetworkListController* currDelegate;

%hook WFAirportViewController

-(void)setListDelegate:(id)arg1
{
	currDelegate = arg1;
	%orig;
}

-(void)setNetworks:(NSSet*)arg1
{
	@try {
		networksList = arg1?[[arg1 allObjects] copy]:nil;
	}@catch(NSException* ex) {
	}
	%orig;
}
- (void)viewWillAppear:(BOOL)arg1
{
	%orig;
	static __strong UIRefreshControl *refreshControl;
		//if(!refreshControl) {
			refreshControl = [[UIRefreshControl alloc] init];
			[refreshControl addTarget:self action:@selector(refreshScan:) forControlEvents:UIControlEventValueChanged];
			refreshControl.tag = 8654;
		//}
		if(UITableView* tableV = self.tableView) {
			if(UIView* rem = [tableV viewWithTag:8654]) {
				[rem removeFromSuperview];
			}
			[tableV addSubview:refreshControl];
		}
}
%new
- (void)refreshScan:(UIRefreshControl *)refresh
{
	@try {
		[currDelegate stopScanning];
		[currDelegate startScanning];
	}@catch(NSException* ex) {
	}
	[refresh endRefreshing];
}
- (WFNetworkListCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	WFNetworkListCell* cell = %orig;

	@try {
		cell.network = nil;
		if(indexPath == [self _currentNetworkCellIndexPath]) {
			currNetwork = [self currentNetwork];
			cell.network = currNetwork;
		} else if(networksList && indexPath.section == 1) {
			for(WFNetworkScanRecord* netNow in networksList) {
				if(netNow.ssid && [netNow.ssid isEqualToString:cell.textLabel.text]) {
					cell.network = netNow;
					break;
				}
			}
		}
	}@catch(NSException* ex) {
	}
	return cell;
}
%end


%hook WFClient
- (BOOL)isKnownNetworkUIEnabled
{
	return YES;
}
%end

%hook WFScanRequest
- (BOOL)applyRssiThresholdFilter
{
	return NO;
}
%end


static CFArrayRef networksListArr()
{
	static time_t lastTime;
	static CFArrayRef networks;
	if(networks && (([[NSDate date] timeIntervalSince1970]-lastTime) > 5) ) { // 5secs refetch timeout
		CFRelease(networks);
		networks = nil;
	}
	if(!networks) {
		lastTime = [[NSDate date] timeIntervalSince1970];
		networks = WiFiManagerClientCopyNetworks(wifiManager());
	}
	return networks;
}

static NSString* getPassForNetworkName(NSString* networkName)
{
	NSString* passwordRet = nil;
	@try {
		if(networkName) {
			if(CFArrayRef networks = networksListArr()) {
				for(id networkNow in (__bridge NSArray*)networks) {
					if(CFStringRef name = WiFiNetworkGetSSID((__bridge WiFiNetworkRef)networkNow)) {
						if([(__bridge NSString*)name isEqualToString:networkName]) {
							if(CFStringRef pass = WiFiNetworkCopyPassword((__bridge WiFiNetworkRef)networkNow)) {
								passwordRet = [NSString stringWithFormat:@"%@", pass];
								CFRelease(pass);
							}
							break;
						}
					}					
				}
			}
		}
	} @catch(NSException* ex) {
	}
	return passwordRet;
}


static NSDictionary* getDicForNetworkName(NSString* networkName)
{
	NSDictionary* recordRet = nil;
	@try {
		if(networkName) {
			if(CFArrayRef networks = networksListArr()) {
				for(id networkNow in (__bridge NSArray*)networks) {
					if(CFStringRef name = WiFiNetworkGetSSID((__bridge WiFiNetworkRef)networkNow)) {
						if([(__bridge NSString*)name isEqualToString:networkName]) {
							if(CFDictionaryRef record = WiFiNetworkCopyRecord((__bridge WiFiNetworkRef)networkNow)) {
								recordRet = (__bridge NSDictionary*)record;
								CFRelease(record);
							}
							break;
						}
					}					
				}
			}
		}
	} @catch(NSException* ex) {
		// NSLog(@"getLastJoinedAtForNetworkName异常:%@ %@",ex.name,ex.reason);
	}
	return recordRet;
}
// 获取最后使用wifi的时间
static NSDate* getLastUseDate(NSDictionary* dic){
	if(!dic){
		return [NSDate dateWithTimeIntervalSince1970:0];
	}
	NSMutableArray* dates = [[NSMutableArray alloc] init];
	// NSDate *addedAt = (NSDate *)[dic objectForKey:@"lastUpdated"];
	// if(addedAt){
	// 	 [dates addObject:addedAt];
	// }
	// NSDate *knownBSSUpdatedDate = (NSDate *)[dic objectForKey:@"knownBSSUpdatedDate"];
	// if(knownBSSUpdatedDate){
	// 	 [dates addObject:knownBSSUpdatedDate];
	// }
	[dates addObject:[NSDate dateWithTimeIntervalSince1970:0]];
	NSDate *addedAt = (NSDate *)[dic objectForKey:@"addedAt"];
	if(addedAt){
		 [dates addObject:addedAt];
	}
	NSDate *lastAutoJoined = (NSDate *)[dic objectForKey:@"lastAutoJoined"];
	if(lastAutoJoined){
		 [dates addObject:lastAutoJoined];
	}
	NSDate *lastJoined = (NSDate *)[dic objectForKey:@"lastJoined"];
	if(lastJoined){
		 [dates addObject:lastJoined];
	}
	NSDate *prevJoined = (NSDate *)[dic objectForKey:@"prevJoined"];
	if(prevJoined){
		 [dates addObject:prevJoined];
	}
	// NSLog(@"----%@",[dates sortedArrayUsingComparator:^NSComparisonResult(NSDate *date1, NSDate *date2){
	// 	return [date1 compare: date2];
    // }]);
	return [[dates sortedArrayUsingComparator:^NSComparisonResult(NSDate *date1, NSDate *date2){
		return [date2 compare: date1];
    }] objectAtIndex:0];

}

 

%hook WFKnownNetworksViewController
%property (assign,nonatomic) int sortType;
%property (assign,nonatomic) BOOL hasSetBarButton;
- (void)setKnownNetworksArray:(id)arg1
{
	if(!self.hasSetBarButton){
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle: @"↑↓"  style:UIBarButtonItemStylePlain target:self  action:@selector(toggleSort)];
		self.hasSetBarButton = YES;
	}
	// self.navigationItem.rightBarButtonItem = nil;
	if(self.sortType==1){
		arg1 = [arg1 sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
			NSDate *date1 = getLastUseDate(getDicForNetworkName((NSString *)obj1)) ;
			NSDate *date2 = getLastUseDate(getDicForNetworkName((NSString *)obj2)) ;
			// if([(NSString *)obj1 isEqualToString:@"dengbasyq209-210"] ){
			// 	NSLog(@" %@  %@",(NSString *)obj1,getDicForNetworkName((NSString *)obj1));
			// }
			//  NSOrderedAscending,    // < 升序
    		//  NSOrderedSame,       // = 等于
    		//  NSOrderedDescending   // > 降序
			return [date2 compare: date1];
		}];
	}else if(self.sortType==2){
		// NSSortDescriptor *ns=[NSSortDescriptor sortDescriptorWithKey:nil ascending:YES];
		// arg1 = [(NSMutableArray*)arg1 sortedArrayUsingDescriptors:@[ns]];
		arg1 = [arg1 sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
			NSMutableString * name1 = [[NSMutableString alloc]initWithString:obj1];
			NSMutableString * name2 = [[NSMutableString alloc]initWithString:obj2];
			NSString *firstWord1=[obj1 substringToIndex:1];
			NSString *firstWord2=[obj2 substringToIndex:1];
			// unichar firstChar1=[obj1 characterAtIndex:1];
			// unichar firstChar2=[obj2 characterAtIndex:1];
			if(![obj2 length]||![obj1 length]){
				return [obj1 compare: obj2 options:NSLiteralSearch];
			}
			CFStringTransform((__bridge CFMutableStringRef)name1, NULL, kCFStringTransformToLatin, NO);
			CFStringTransform((__bridge CFMutableStringRef)name1, NULL, kCFStringTransformStripCombiningMarks, NO);
			CFStringTransform((__bridge CFMutableStringRef)name2, NULL, kCFStringTransformToLatin, NO);
			CFStringTransform((__bridge CFMutableStringRef)name2, NULL, kCFStringTransformStripCombiningMarks, NO);
			// NSLog(@"------\n%@,%@,%@,%@",name1,firstWord1,name2,firstWord2);

			NSComparisonResult result1 = [[name1 substringToIndex:1] compare:[name2 substringToIndex:1] options:NSCaseInsensitiveSearch];
			NSString *name1FirstWord=[name1 substringToIndex:1];
			NSString *name2FirstWord=[name2 substringToIndex:1];
			
			// 首字母分块
			if(result1!=NSOrderedSame){
				return result1;
			}else {
				// 中文在后
				if([name1FirstWord isEqualToString:firstWord1]&&![name2FirstWord isEqualToString:firstWord2]){
					return NSOrderedAscending;
				}else if(![name1FirstWord isEqualToString:firstWord1]&&[name2FirstWord isEqualToString:firstWord2]){
					return NSOrderedDescending;
				}else{
					// 大写字母在后
					for (int i = 0; i<([name1 length]>[name2 length]?[name2 length]:[name1 length]); i++){
						char name1FirstChar=[name1 characterAtIndex:i];
						char name2FirstChar=[name2 characterAtIndex:i];
						if((name1FirstChar>='a'&&name1FirstChar<='z')&&(name2FirstChar>='A'&&name2FirstChar<='Z')){
							return NSOrderedAscending;
						}else if((name1FirstChar>='A'&&name1FirstChar<='Z')&&(name2FirstChar>='a'&&name2FirstChar<='z')){
							return NSOrderedDescending;
						}
					}
					if([name1 length]>[name2 length]){
						return NSOrderedDescending;
					}else if([name1 length]<[name2 length]){
						return NSOrderedAscending;
					}else{
						return NSOrderedSame;
					}
				}
			}
		}];
	}
	%orig;
}

%new
-(void)toggleSort{
    self.sortType+=1;
    if(self.sortType>2){
		self.sortType = 1;
	}
	if(self.sortType==1){
    	[self.navigationItem.rightBarButtonItem setTitle:@"Recent"]; 
	}else if(self.sortType==21){
    	[self.navigationItem.rightBarButtonItem setTitle:@"Name"]; 
	}
	[self setKnownNetworksArray:self.knownNetworksArray];
	[self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cellOrig = %orig;
	NSString* wfname = cellOrig.textLabel.text;
	UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"myCell"];
	cell.accessoryType = UITableViewCellAccessoryNone;
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	@try {
		cell.textLabel.text = wfname;
      	cell.textLabel.numberOfLines = 0;
      	cell.detailTextLabel.text = getPassForNetworkName(wfname)?:@"";
      	cell.detailTextLabel.numberOfLines = 0;
      	cell.detailTextLabel.textColor = [UIColor grayColor];
	} @catch(NSException* ex) {
	}
	
	return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.sortType==0){
		return %orig;
	}else{
		return UITableViewCellEditingStyleNone;
	}
    // return tableView.editing?UITableViewCellEditingStyleDelete:UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// 点击事件,点击的cell
	// UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
}

%new
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

%new
- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return (action == @selector(copy:));
}

%new
- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
		@try {
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
			[pasteBoard setString:getPassForNetworkName(cell.textLabel.text)?:@""];
		} @catch(NSException* ex) {
		}
    }
}	


%end


%ctor
{
	@autoreleasepool {
		dlopen("/System/Library/PreferenceBundles/AirPortSettings.bundle/AirPortSettings", RTLD_LAZY);
		dlopen("/System/Library/PrivateFrameworks/WiFiKit.framework/WiFiKit", RTLD_LAZY);
		dlopen("/System/Library/PrivateFrameworks/WiFiKitUI.framework/WiFiKitUI", RTLD_LAZY);
	}
}
