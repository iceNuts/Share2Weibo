
@interface purchaseChecker : NSObject
-(id) readCode;
-(BOOL) purchase;
-(BOOL) isPurchased;
@end

@interface dataParser : NSObject<NSXMLParserDelegate>
@property(nonatomic, retain) id parseData;
@end