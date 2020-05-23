#import <Foundation/Foundation.h>

@interface JCDefaults: NSObject
@end 

@implementation JCDefaults {
	NSUserDefaults *_defaults;	
}

+ (instancetype)sharedInstance {
	static dispatch_once_t once;
	static id sharedInstance;
	dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (instancetype)init {
	self = [super init];
	if(self) {
		_defaults = [[NSUserDefaults alloc] initWithSuiteName:@"codes.jorgecohen.syncTabs"];
	}
	
	return self;
}

- (NSString*)tabSyncUUIDString {
	NSString *tabSyncUUIDString = [_defaults objectForKey:@"tabSyncUUID"];
	if(!tabSyncUUIDString) {
		tabSyncUUIDString = [[NSUUID UUID] UUIDString];
		[_defaults setObject:tabSyncUUIDString forKey:@"tabSyncUUID"];
	}	
	
	return tabSyncUUIDString;
}

- (NSString*)deviceName {
	NSString *deviceName = [_defaults objectForKey:@"deviceName"];
	if(!deviceName) {
		deviceName = [NSString stringWithFormat:@"%@ Firefox", [[NSHost currentHost] localizedName]];
		[_defaults setObject:deviceName forKey:@"deviceName"];
	}
	
	return deviceName;
}

@end

@protocol WBSSafariBookmarksSyncAgentProtocol
- (void)saveTabsForCurrentDeviceWithDictionaryRepresentation:(NSDictionary *)dict 
											deviceUUIDString:(NSString *)uuidString
										   completionHandler:(void (^)(NSError *))completionHandler;
@end

///////////////////////////////////////////////////////////////////////////////////////////////
@interface JCSyncThing : NSObject
@property (strong, nonatomic) NSXPCConnection *connection;
@end

@implementation JCSyncThing

- (instancetype)init {
		self = [super init];
		if (self) {
			self.connection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.apple.SafariBookmarksSyncAgent" options:(NSXPCConnectionOptions)0];				
			self.connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(WBSSafariBookmarksSyncAgentProtocol)];				
			[self.connection resume];
		}
		return self;
}

- (void)saveTabs:(NSArray *)tabs completionHandler:(void (^)(NSError *))completionHandler {
	NSDictionary *dict = @{
		@"Capabilities": @{
			@"CloseTabRequest" : @(YES),
			@"CloudKitBookmarkSyncing" : @(YES)
		},
		@"DeviceName" : [[JCDefaults sharedInstance] deviceName],
		@"DictionaryType" : @"Device",
		@"LastModified" : [NSDate date],
		@"Tabs" : tabs ?: @[]
	};

	[[self.connection remoteObjectProxy] saveTabsForCurrentDeviceWithDictionaryRepresentation:dict 
																			 deviceUUIDString:[[JCDefaults sharedInstance] deviceName] 
																			completionHandler:completionHandler];
}

@end

#define JCPrintf(...)   printf( "%s", [[NSString stringWithFormat: __VA_ARGS__] UTF8String] )
int main(int argc, char *argv[]) {
	@autoreleasepool {
		JCSyncThing *sync = [[JCSyncThing alloc] init];
		
		NSFileHandle *stdin = [NSFileHandle fileHandleWithStandardInput];

		// Firefox send length of message first
		NSData *lenData = [stdin readDataOfLength:4];
		int length = CFSwapInt32LittleToHost(*(int*)([lenData bytes]));
		
		// The rest is tabs data 
		NSData *inputData = [NSData dataWithData:[stdin readDataToEndOfFile]];
		NSArray *tabs = [NSJSONSerialization JSONObjectWithData:inputData options:NSJSONReadingAllowFragments error:nil];

		[sync saveTabs:tabs completionHandler:^(NSError *error) {
			// Native messaging example on MDN did this, not sure if needed
			JCPrintf(@"{'length': \"1\", 'content': 1}");
		}];
	}
}
