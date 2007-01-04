#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#import <Foundation/NSDictionary.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Cocoa/Cocoa.h>

void findPage(NSFileHandle *fileHandle) {
	
	NSString *stringHeader = @"OggS";
	
	NSData *dataHeader = [stringHeader dataUsingEncoding:NSISOLatin1StringEncoding];	
	NSData *data = [fileHandle readDataOfLength:4];
	
	unsigned long pointer = [fileHandle offsetInFile];
	
	while( ![dataHeader isEqualToData:data]  ) {
		
		[fileHandle seekToFileOffset:pointer++];
		data = [fileHandle readDataOfLength:4]; 
	}
}



Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
	NSAutoreleasePool *pool;
	NSFileHandle *readFile;
	pool = [NSAutoreleasePool new];
	//@"/Users/paul/Music/vicarious.ogg";
	
	readFile = [NSFileHandle fileHandleForReadingAtPath:(NSString *)pathToFile];
	//fileData = [readFile readDataOfLength:10];
	
	// get the second page
	findPage(readFile);
	findPage(readFile);

	// get the current offset
	unsigned long fileHandlePointer = [readFile offsetInFile];
	
	// dunno what this does
	[readFile readDataOfLength:(26-4)];
	
	// get the segments
	NSData *tempD = [readFile readDataOfLength:1];
	unsigned int segments = 0;
	[tempD getBytes:&segments];
	[readFile readDataOfLength:(unsigned int)segments];
	fileHandlePointer = [readFile offsetInFile];
	
	// skip preable
	[readFile readDataOfLength:7];

	
	// skip Vendor
	unsigned long vend;
	NSData *tempD2 = [readFile readDataOfLength:4];
	[tempD2 getBytes:&vend];
	[readFile readDataOfLength:(unsigned int)vend];
	
	// comments
	unsigned long numberOfComments;
	NSData *tempD3 = [readFile readDataOfLength:4];
	[tempD3 getBytes:&numberOfComments];
	//[readFile readDataOfLength:(unsigned int)numberOfComments];
	int i = 0;
	for(i = 0; i < numberOfComments ; i++) {
		unsigned long commentSize;
		NSData *commentSizeData = [readFile readDataOfLength:4];
		[commentSizeData getBytes:&commentSize];
		
		NSString *comment;
		NSData *commentData = [readFile readDataOfLength:(unsigned int)commentSize];
		comment = [[NSString alloc] initWithData:(NSData *)commentData encoding:NSUTF8StringEncoding];
		
		NSArray *commentArray = [comment componentsSeparatedByString:@"="];
		NSString *commentField =[commentArray objectAtIndex:0];
		NSString *commentValue = [commentArray objectAtIndex:1];
		
		if([commentField isEqualToString:@"ALBUM"]) {
			[(NSMutableDictionary *)attributes setObject:commentValue	forKey:(NSString *)kMDItemAlbum];
		} else if([commentField isEqualToString:@"TITLE"]) {
			[(NSMutableDictionary *)attributes setObject:commentValue	forKey:(NSString *)kMDItemTitle];
		} else if([commentField isEqualToString:@"GENRE"]) {
			[(NSMutableDictionary *)attributes setObject:commentValue	forKey:(NSString *)kMDItemMusicalGenre];
		} else if([commentField isEqualToString:@"DATE"]) {
			[(NSMutableDictionary *)attributes setObject:commentValue	forKey:(NSString *)kMDItemRecordingYear];
		} else if([commentField isEqualToString:@"ARTIST"]) {
			NSMutableArray* authors = [NSMutableArray array];
			[authors addObject:commentValue];
			[(NSMutableDictionary *)attributes setObject:authors	forKey:(NSString *)kMDItemAuthors];
		} else if([commentField isEqualToString:@"TRACKNUMBER"]) {
			[(NSMutableDictionary *)attributes setObject:commentValue	forKey:(NSString *)kMDItemAudioTrackNumber];
		} 
		 
		
	}
	
	[pool release];
	
    return TRUE;
}
