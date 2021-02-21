#import "WiFiInfo.h"

#define NSLog1(...)


static WiFiManagerRef wifiManager()
{
	static WiFiManagerRef manager;
	if(!manager) {
		manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0);
	}
	return manager;
}

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
%property (nonatomic, retain) id labelCan;
%property (nonatomic, retain) id labelMac;
%property (nonatomic, retain) id network;
%property (nonatomic,copy) NSString * subtitleTmp; 
%property (assign,nonatomic) BOOL hasInitMacAddr;    
- (void)setSubtitle:(NSString*)arg1{
if ([arg1 hasPrefix:@"MissThee"]){
	arg1=[arg1 substringFromIndex:8];
}else{
	self.subtitleTmp=arg1;
}
%orig;

	//NSString* temp=[NSString stringWithFormat:@"%@%@",self.network.bssid?:@"", arg1?[NSString stringWithFormat:@" \n%@",arg1]:@""];
	//if(temp.length>0){
	//	arg1 = temp;
	//}
	//%orig;
}
- (void)layoutSubviews
{
	@try {
		self.network = networkForName(self.title);
		if(self.network) {
			if(self.subtitleTmp) {
				NSString* temp=[NSString stringWithFormat:@"MissThee%@%@",self.network.bssid, self.subtitleTmp?[NSString stringWithFormat:@" \n%@",self.subtitleTmp]:@""];
				[self setSubtitle:temp];
			}else{
				[self setSubtitle:[NSString stringWithFormat:@"MissThee%@",self.network.bssid]];
			}
			UIImageView* _barsView = (UIImageView *)object_getIvar(self, class_getInstanceVariable([self class], "_signalImageView"));
			UIImageView* _lockView = (UIImageView *)object_getIvar(self, class_getInstanceVariable([self class], "_lockImageView"));
		
			if(_lockView) {
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
			
			if(_barsView) {
				
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
				
				if(!self.labelCan) {
					self.labelCan = (UILabel *)[_barsView viewWithTag:4457]?:[[UILabel alloc] init];
					self.labelCan.tag = 4457;
				}
				[self.labelCan setText:nil];
				self.labelCan.center = _barsView.center;
				self.labelCan.frame = CGRectMake(0, 0-6 , _barsView.frame.size.width, 10);
				NSString* canNumber = nil;
				@try {
					canNumber = [[self.network channel] stringValue];
					if(canNumber) {
						canNumber = [NSString stringWithFormat:@"%@", canNumber];
					}
				} @catch(NSException* ex) {
					
				}
				[self.labelCan setText:canNumber];
				[self.labelCan setBackgroundColor:[UIColor clearColor]];
				[self.labelCan setNumberOfLines:0];
				self.labelCan.font = [UIFont systemFontOfSize:10];
				self.labelCan.textAlignment = NSTextAlignmentCenter;
				self.labelCan.adjustsFontSizeToFitWidth = YES;
				if([_barsView viewWithTag:4457]==nil) {
					[_barsView addSubview:self.labelCan];
				}
				
				if(!self.labelMac) {
					self.labelMac = (UILabel *)[_barsView viewWithTag:4458]?:[[UILabel alloc] init];
					self.labelMac.tag = 4458;
				}
				[self.labelMac setText:nil];
				//self.labelMac.center = _barsView.center;
				self.labelMac.frame = CGRectMake(20, 20, 200, 8);
				NSString* macAddr = nil;
				@try {
					macAddr = self.network.bssid;
				} @catch(NSException* ex) {
					
				}
				[self.labelMac setText:macAddr];
				[self.labelMac setBackgroundColor:[UIColor clearColor]];
				[self.labelMac setNumberOfLines:0];
				self.labelMac.font = [UIFont systemFontOfSize:10];
				self.labelMac.textAlignment = NSTextAlignmentLeft;
				self.labelMac.adjustsFontSizeToFitWidth = YES;
				if([_barsView viewWithTag:4458]==nil) {
					[_barsView addSubview:self.labelMac];
				}
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

%hook WFKnownNetworksViewController
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cellOrig = %orig;
   NSString* wfname = cellOrig.textLabel.text;
   UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"myCell"];
   cell.accessoryType = UITableViewCellAccessoryNone;
   [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	@try {
		cell.textLabel.text = wfname;
      cell.detailTextLabel.text = getPassForNetworkName(wfname)?:@"";
      cell.textLabel.numberOfLines = 0;
      cell.detailTextLabel.numberOfLines = 0;
      cell.detailTextLabel.textColor = [UIColor grayColor];
      
	} @catch(NSException* ex) {
	}
	
	return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing) {
        return UITableViewCellEditingStyleDelete;
    }
    else
    {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//点击事件
//点击的cell
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  
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
