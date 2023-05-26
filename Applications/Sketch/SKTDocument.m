/*
     File: SKTDocument.m
 Abstract: The main document class for the application.
  Taken from Apple's Sketch.app example
 
 */

#import "SKTDocument.h"
#import "SKTError.h"
#import "SKTGraphic.h"
#import "SKTRenderingView.h"
#import "SKTCircle.h"
#import "SKTImage.h"
#import "SKTLine.h"
#import "SKTRectangle.h"
#import "SKTText.h"
#import "SKTWindowController.h"


// String constants declared in the header.
NSString *SKTDocumentCanvasSizeKey = @"canvasSize";
NSString *SKTDocumentGraphicsKey = @"graphics";

// More keys, and a version number, which are just used in Sketch's property-list-based file format.
static NSString *SKTDocumentVersionKey = @"version";
static NSString *SKTDocumentPrintInfoKey = @"printInfo";
static NSInteger SKTDocumentCurrentVersion = 2;


// Some methods are invoked by methods above them in this file.
@interface SKTDocument(SKTForwardDeclarations)
- (NSArray *)graphics;
- (void)startObservingGraphics:(NSArray *)graphics;
- (void)stopObservingGraphics:(NSArray *)graphics;
@end


// A class we use to add reference counting to NSMapTable, which was not an object in Mac OS 10.4 and earlier. Why bother with a -mapTable accessor instead of a public instance variable for such a trivial case? Because Foundation's zombie debugging feature kicks in for method invocations but not public instance variable access.
@interface SKTMapTableOwner : NSObject {
    @private
    NSMapTable *_mapTable;
}
@end
@implementation SKTMapTableOwner
- (id)init {
    self = [super init];
    _mapTable = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
    return self;
}
- (void)dealloc {
    NSFreeMapTable(_mapTable);
    [super dealloc];
}
- (NSMapTable *)mapTable {
    return _mapTable;
}
@end


@implementation SKTDocument


// An override of the superclass' designated initializer, which means it should always be invoked.
- (id)init {

    // Do the regular Cocoa thing.
    self = [super init];
    if (self) {
        _graphics = [[NSMutableArray alloc] init];
    }
    return self;

}

+ (BOOL)isNativeType: (NSString*)type {
    return YES;
}

- (void)dealloc {
    [_graphics release];
    [super dealloc];
}


#pragma mark *** Private KVC-Compliance for Public Properties ***


- (NSArray *)graphics {
    return _graphics;
}


- (void)insertGraphics:(NSArray *)graphics atIndexes:(NSIndexSet *)indexes {
    [_graphics insertObjects:graphics atIndexes:indexes];

    // Start observing the just-inserted graphics so that, when they're changed, we can record undo operations.
    [self startObservingGraphics:graphics];
}


- (void)removeGraphicsAtIndexes:(NSIndexSet *)indexes {
    NSArray *graphics = [_graphics objectsAtIndexes:indexes];
    // Stop observing the just-removed graphics to balance what was done in -insertGraphics:atIndexes:.
    [self stopObservingGraphics:graphics];
    // Do the actual removal.
    [_graphics removeObjectsAtIndexes:indexes];
}

#pragma mark *** Simple Property Getting ***

- (NSSize)canvasSize {
    
    // A Sketch's canvas size is the size of the piece of paper that the user selects in the Page Setup panel for it, minus the document margins that are set.
    NSPrintInfo *printInfo = [self printInfo];
    NSSize canvasSize = [printInfo paperSize];
    canvasSize.width -= ([printInfo leftMargin] + [printInfo rightMargin]);
    canvasSize.height -= ([printInfo topMargin] + [printInfo bottomMargin]);
    return canvasSize;
    
}

#pragma mark *** Overrides of NSDocument Methods ***


// This method will only be invoked on Mac 10.6 and later. It's ignored on Mac OS 10.5.x which just means that documents are opened serially.
+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName {

    // There's nothing in Sketch that would cause multithreading trouble when documents are opened in parallel in separate NSOperations.
    return YES;
}


// This method will only be invoked on Mac 10.4 and later. If you're writing an application that has to run on 10.3.x and earlier you should override -loadDataRepresentation:ofType: instead.
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {

    BOOL readSuccessfully;
    NSArray *graphics = nil;
    NSPrintInfo *printInfo = nil;
    NSDictionary *properties = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
    if (properties) {

        // Get the graphics. Strictly speaking the property list of an empty document should have an empty graphics array, not no graphics array, but we cope easily with either. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources.
        NSArray *graphicPropertiesArray = [properties objectForKey:SKTDocumentGraphicsKey];
        graphics = [graphicPropertiesArray isKindOfClass:[NSArray class]] ? [SKTGraphic graphicsWithProperties:graphicPropertiesArray] : [NSArray array];

        /*
        NSData *printInfoData = [properties objectForKey:SKTDocumentPrintInfoKey];
        printInfo = [printInfoData isKindOfClass:[NSData class]] ? [NSUnarchiver unarchiveObjectWithData:printInfoData] : [[[NSPrintInfo alloc] init] autorelease];
        */

    } else if (outError) {

        // If property list parsing fails we have no choice but to admit that we don't know what went wrong. The error description returned by +[NSPropertyListSerialization propertyListFromData:mutabilityOption:format:errorDescription:] would be pretty technical, and not the sort of thing that we should show to a user.
        *outError = SKTErrorWithCode(SKTUnknownFileReadError);
    
    }
    readSuccessfully = properties ? YES : NO;

    if (readSuccessfully) {

	// Update the document's list of graphics by going through KVC-compliant mutation methods. KVO notifications will be automatically sent to observers (which does matter, because this might be happening at some time other than document opening; reverting, for instance). Update its page setup the regular way. Don't let undo actions get registered while doing any of this. The fact that we have to explicitly protect against useless undo actions is considered an NSDocument bug nowadays, and will someday be fixed.
@try {
        [self removeGraphicsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self graphics] count])]];
        [self insertGraphics:graphics atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [graphics count])]];
}
@catch(NSException* ex) {
    NSLog(@"xxx:%@", ex);
}
    ///[self setPrintInfo:printInfo];

    } // else it was the responsibility of something in the previous paragraph to set *outError.
    return readSuccessfully;

}


// This method will only be invoked on Mac OS 10.4 and later. If you're writing an application that has to run on 10.3.x and earlier you should override -dataRepresentationOfType: instead.
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    @try {
        NSData *data;
        NSArray *graphics = [self graphics];
        NSPrintInfo *printInfo = [self printInfo];

        // Convert the contents of the document to a property list and then flatten the property list.
        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        [properties setObject:[NSNumber numberWithInteger:SKTDocumentCurrentVersion] forKey:SKTDocumentVersionKey];
        [properties setObject:[SKTGraphic propertiesWithGraphics:graphics] forKey:SKTDocumentGraphicsKey];
        //error while archiving!
        //[properties setObject:[NSArchiver archivedDataWithRootObject:printInfo] forKey:SKTDocumentPrintInfoKey];

        data = [NSPropertyListSerialization dataFromPropertyList:properties format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];

        //data = [SKTRenderingView tiffDataWithGraphics:graphics error:outError];
        return data;
    }
    @catch(NSException* ex) {
        NSLog(@"%@", ex);
        return nil;
    }
}


- (void)setPrintInfo:(NSPrintInfo *)printInfo {
    // Do the regular Cocoa thing, but also be KVO-compliant for canvasSize, which is derived from the print info.
    [self willChangeValueForKey:SKTDocumentCanvasSizeKey];
    [super setPrintInfo:printInfo];
    [self didChangeValueForKey:SKTDocumentCanvasSizeKey];
}


// This method will only be invoked on Mac 10.4 and later. If you're writing an application that has to run on 10.3.x and earlier you should override -printShowingPrintPanel: instead.
- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError {

    // Figure out a title for the print job. It will be used with the .pdf file name extension in a save panel if the user chooses Save As PDF... in the print panel, or in a similar way if the user hits the Preview button in the print panel, or for any number of other uses the printing system might put it to. We don't want the user to see file names like "My Great Sketch.sketch2.pdf", so we can't just use [self displayName], because the document's file name extension might not be hidden. Instead, because we know that all valid Sketch documents have file name extensions, get the last path component of the file URL and strip off its file name extension, and use what's left.
    NSString *printJobTitle = [[[[self fileURL] path] lastPathComponent] stringByDeletingPathExtension];
    if (!printJobTitle) {

	// Wait, this document doesn't have a file associated with it. Just use -displayName after all. It will be "Untitled" or "Untitled 2" or something, which is fine.
	printJobTitle = [self displayName];

    }

    // Create a view that will be used just for printing.
    NSSize documentSize = [self canvasSize];
    SKTRenderingView *renderingView = [[SKTRenderingView alloc] initWithFrame:NSMakeRect(0.0, 0.0, documentSize.width, documentSize.height) graphics:[self graphics] printJobTitle:printJobTitle];
    
    // Create a print operation.
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:renderingView printInfo:[self printInfo]];
    [renderingView release];
    
    // Specify that the print operation can run in a separate thread. This will cause the print progress panel to appear as a sheet on the document window.
    [printOperation setCanSpawnSeparateThread:YES];
    
    // Set any print settings that might have been specified in a Print Document Apple event. We do it this way because we shouldn't be mutating the result of [self printInfo] here, and using the result of [printOperation printInfo], a copy of the original print info, means we don't have to make yet another temporary copy of [self printInfo].
    [[[printOperation printInfo] dictionary] addEntriesFromDictionary:printSettings];
    
    // We don't have to autorelease the print operation because +[NSPrintOperation printOperationWithView:printInfo:] of course already autoreleased it. Nothing in this method can fail, so we never return nil, so we don't have to worry about setting *outError.
    return printOperation;
    
}

- (void)makeWindowControllers {
    // Start off with one document window.
    SKTWindowController *windowController = [[SKTWindowController alloc] init];
    [self addWindowController:windowController];
    [windowController release];
}

- (void)startObservingGraphics:(NSArray *)graphics {

}

- (void)stopObservingGraphics:(NSArray *)graphics {

}

- (NSArray *)graphicsWithClass:(Class)theClass {
    NSArray *graphics = [self graphics];
    NSMutableArray *result = [NSMutableArray array];
    NSUInteger i, c = [graphics count];
    id curGraphic;

    for (i=0; i<c; i++) {
        curGraphic = [graphics objectAtIndex:i];
        if ([curGraphic isKindOfClass:theClass]) {
            [result addObject:curGraphic];
        }
    }
    return result;
}

- (NSArray *)rectangles {
    return [self graphicsWithClass:[SKTRectangle class]];
}

- (NSArray *)circles {
    return [self graphicsWithClass:[SKTCircle class]];
}

- (NSArray *)lines {
    return [self graphicsWithClass:[SKTLine class]];
}

- (NSArray *)textAreas {
    return [self graphicsWithClass:[SKTText class]];
}

- (NSArray *)images {
    return [self graphicsWithClass:[SKTImage class]];
}

@end
