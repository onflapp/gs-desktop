// ADPlugin.m (this is -*- ObjC -*-)
// 
// Author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import "ADPlugin.h"

static ADPluginManager *manager = NULL;

@implementation ADPluginManager
- init
{
    abClassPlugins = [[NSMutableArray alloc] init];
    return self;
}

- (void) dealloc
{
    [abClassPlugins release];
    [super dealloc];
}

+ (ADPluginManager*) sharedPluginManager
{
    if(!manager)
    {
	manager = [[ADPluginManager alloc] init];
	[manager checkForNewPlugins];
    }
    return manager;
}

- (NSBundle*) pluginForClassNamed: (NSString*) className
{
    NSEnumerator *e;
    NSBundle *b;

    e = [abClassPlugins objectEnumerator];
    while((b = [e nextObject]))
	if([[[b principalClass] className] 
	       isEqualToString: className])
	    return b;
    return nil;
}

- (NSBundle*) pluginLoadedFromPath: (NSString*) aPath
{
    NSEnumerator *e;
    NSBundle *b;

    e = [abClassPlugins objectEnumerator];
    while((b = [e nextObject]))
	if([[b bundlePath] isEqualToString: aPath])
	    return b;
    return nil;
}

- (BOOL) checkForNewPlugins
{
    NSArray *paths;
    NSEnumerator* pathEnum;
    NSString *curPath;
    NSFileManager *fm;

    BOOL allOk;

    allOk = YES;

    paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
						NSAllDomainsMask, YES);
    
    fm = [NSFileManager defaultManager];
    pathEnum = [paths objectEnumerator];
    while((curPath = [pathEnum nextObject]))
    {
	NSArray *contents;
	NSString *curFile;
	NSEnumerator *fileEnum;

	curPath = [curPath stringByAppendingPathComponent: @"Addresses"];

	contents = [fm directoryContentsAtPath: curPath];
	if(!contents) continue;
	
	fileEnum = [contents objectEnumerator];
	while((curFile = [fileEnum nextObject]))
	{
	    if([[curFile pathExtension] isEqualToString: @"abclass"])
	    {
		NSString *fqfn;
		NSBundle *bundle;

		fqfn = [curPath stringByAppendingPathComponent: curFile];
		if([self pluginLoadedFromPath: fqfn])
		    continue;

		bundle = [NSBundle bundleWithPath: fqfn];

		if(!bundle)
		{
		    NSLog(@"Couldn't load bundle %@\n", fqfn);
		    allOk = NO;
		    continue;
		}
		if(![[bundle principalClass] 
			isSubclassOfClass: [ADAddressBook class]])
		{
		    NSLog(@"Principal class %@ of %@ is not an "
			  @"ADPluggedInAddressBook!\n",
			  [[bundle principalClass] className], fqfn);
		    allOk = NO;
		    continue;
		}
		if(![[bundle principalClass] 
			conformsToProtocol: @protocol(ADPluggedInAddressBook)])
		{
		    NSLog(@"Principal class %@ of %@ doesn't conform to "
			  @"ADPluggedInAddressBook!\n",
			  [[bundle principalClass] className], fqfn);
		    allOk = NO;
		    continue;
		}

		if([self pluginForClassNamed: [[bundle principalClass]
						  className]])
		{
		    NSLog(@"Already have plugin for class %@\n",
			  [[bundle principalClass] className]);
		    continue;
		}

		[abClassPlugins addObject: bundle];
	    }
	}
    }

    return allOk;
}

- (ADAddressBook*) newAddressBookWithSpecification: (NSDictionary*) aSpec
{
    NSString *className;
    NSBundle *plugin;

    className = [aSpec objectForKey: @"Class"];
    if(!className)
    {
	NSLog(@"Dictionary %@ doesn't contain an entry for ClassName!\n",
	      [aSpec description]);
	return nil;
    }

    plugin = [self pluginForClassNamed: className];
    if(plugin) 
	return [[[plugin principalClass] alloc] initWithSpecification: aSpec];
    return nil;
}

@end


