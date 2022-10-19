#import <objc/runtime.h>
#import <notify.h>
#import <Security/Security.h>
#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Preferences/PSListItemsController.h>

extern const char *__progname;

enum {
	kCWSecurityNone                 = 0,
	kCWSecurityWEP                  = 1,
	kCWSecurityWPAPersonal          = 2,
	kCWSecurityWPAPersonalMixed     = 3,
	kCWSecurityWPA2Personal         = 4,
	kCWSecurityPersonal             = 5,
	kCWSecurityDynamicWEP           = 6,
	kCWSecurityWPAEnterprise        = 7,
	kCWSecurityWPAEnterpriseMixed   = 8,
	kCWSecurityWPA2Enterprise       = 9,
	kCWSecurityEnterprise           = 10,
	kCWSecurityUnknown              = NSIntegerMax,
};


typedef struct __WiFiNetwork *WiFiNetworkRef;
typedef struct __WiFiManager *WiFiManagerRef;

extern "C" WiFiManagerRef WiFiManagerClientCreate(CFAllocatorRef allocator, int flags);
extern "C" CFArrayRef WiFiManagerClientCopyNetworks(WiFiManagerRef manager);
extern "C" CFStringRef WiFiNetworkCopyPassword(WiFiNetworkRef);
extern "C" CFStringRef WiFiNetworkGetSSID(WiFiNetworkRef network);
extern "C" CFDictionaryRef WiFiNetworkCopyRecord(WiFiNetworkRef network);

@interface WiFiNetwork : NSObject
- (id)initWithWirelessDict:(id)arg1;
- (NSDictionary*)dictionary;
- (NSString*)BSSID;
- (NSString*)ip;
- (NSString*)password;
- (int)securityMode;
@end

@interface WFNetworkScanRecord : NSObject
@property (nonatomic,copy,readonly) NSString * bssid;
@property (nonatomic,copy,readonly) NSString * ssid;
@property (assign,readonly) long long rssi;
@property (nonatomic,retain) NSNumber * channel; 
@property (assign,nonatomic) long long securityMode;
@property (nonatomic,retain) NSDictionary * attributes;
@property (nonatomic,copy) NSString * crowdsourceDescription;   
@property (copy,readonly) NSString * description; 
@property (copy,readonly) NSString * debugDescription; 

@end




@interface WFKnownNetworksViewController : PSListItemsController
@property (assign,nonatomic) int sortType; // 0不排序；1时间倒序；2名称正序
@property (nonatomic, retain) NSMutableArray *knownNetworksArray;
@property (nonatomic,retain) UITableView *tableView;
@end


@interface WFAssociationStateView : UIView
@property (nonatomic,retain) UIImageView* imageView;
@end

@interface WFNetworkListCell : UITableViewCell
@property (nonatomic,retain) WFAssociationStateView * associationStateView;  
@property (nonatomic,retain) UILabel* labelSec;
@property (nonatomic,retain) UILabel* labelRssi;
@property (nonatomic,retain) UILabel* labelChannel;
@property (nonatomic,retain) UILabel* labelMac;
@property (nonatomic,retain) WFNetworkScanRecord * network;
@property (nonatomic,copy) NSString * title; 
@property (nonatomic,copy) NSString * macTmp; // MAC 地址
@property (nonatomic,copy) NSString * subtitleTmp; 
- (void)setSubtitle:(NSString*)arg1;
@end


@interface WFAirportViewController : UITableViewController
// -(NSString *)getIPAddress;
-(id)_currentNetworkCellIndexPath;
-(WFNetworkScanRecord*)currentNetwork;
-(void)refresh;
-(void)setScanning:(BOOL)arg1 ;
-(void)powerStateDidChange:(BOOL)arg1 ;
@end

@interface WFNetworkListController : UITableViewController 

-(void)startScanning;
-(void)stopScanning;
@end

