//
//  main.m
//  sidebarFinagler
//
//  Created by Anton Stroganov on 3/23/13.
//  Copyright (c) 2013 Aeontech. All rights reserved.
//

#include <stdlib.h>
#include <stdio.h>
#include <sysexits.h>

#include "BDAlias.h"

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import <CoreFoundation/CoreFoundation.h>

#define		PROGRAM_STRING  	"sidebarFinagler"
#define		VERSION_STRING		"0.1"
#define		AUTHOR_STRING 		"Anton Stroganov"
#define		OPT_STRING			"vhctr"

/////////////////// Prototypes //////////////////

static void ReadSidebar (NSString *plistPath);
static CFDataRef CreateBookmarkDataWithFileSystemPath(CFAllocatorRef allocator, CFURLRef url, CFURLBookmarkCreationOptions options, CFArrayRef resourcePropertiesToInclude, CFURLRef relativeToURL, CFErrorRef* error);
static void PrintVersion (void);
static void PrintHelp (void);


///////////////// globals ////////////////////

short		noCustomIconCopy = false;
short		noCopyFileCreatorTypes = false;
short		readAlias = false;

////////////////////////////////////////////
// main program function
////////////////////////////////////////////
int main(int argc, const char * argv[])
{

    @autoreleasepool {

        int			rc;
        int			optch;
        static char	optstring[] = OPT_STRING;
        
        while ( (optch = getopt(argc, (char * const *)argv, optstring)) != -1)
        {
            switch(optch)
            {
                case 'v':
                    PrintVersion();
                    return EX_OK;
                    break;
                case 'h':
                    PrintHelp();
                    return EX_OK;
                    break;
                case 'c':
                    noCustomIconCopy = true;
                    break;
                case 't':
                    noCopyFileCreatorTypes = true;
                    break;
                case 'r':
                    readAlias = true;
                    break;
                default: // '?'
                    rc = 1;
                    PrintHelp();
                    return EX_USAGE;
            }
        }
        
        //check if a correct number of arguments was submitted
        if (argc - optind < 1)
        {
            fprintf(stderr,"Too few arguments.\n");
            PrintHelp();
            return EX_USAGE;
        }
        
        //check if sidebar plist to read exists
        if (access(argv[optind], F_OK) == -1)
        {
            perror(argv[optind]);
            return EX_NOINPUT;
        }
        
        ReadSidebar(/*source*/ [NSString stringWithUTF8String:argv[optind]]);

        // insert code here...
        NSLog(@"Hello, World!");
        
    }
    return 0;
}

#pragma mark -

////////////////////////////////////////
// Read sidebar plist file and output the alias paths
///////////////////////////////////////
static void ReadSidebar (NSString *plistPath) {
    
    NSDictionary *sidebarDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    //--get parent dictionary/Array which holds the favorites
    NSArray *favoritesList = [[sidebarDict objectForKey:@"favorites"] objectForKey:@"VolumesList"];

    //---enumerate through the dictionary objects inside the parentDictionary
	for(NSDictionary *favorite in favoritesList) {

        NSString *nameRef = [favorite valueForKey:@"Name"];

        // use CFURL stuff instead of BDAlias
        // because this lets us resolve the alias without triggering
        // user interaction/mount failure popups due to being able to use
        // kCFBookmarkResolutionWithoutUIMask | kCFBookmarkResolutionWithoutMountingMask
        CFDataRef aliasData = CFURLCreateBookmarkDataFromAliasRecord(kCFAllocatorDefault, (CFDataRef)[favorite valueForKey:@"Alias"]);
        CFURLRef aliasUrl = CFURLCreateByResolvingBookmarkData(kCFAllocatorDefault, aliasData, kCFBookmarkResolutionWithoutUIMask|kCFBookmarkResolutionWithoutMountingMask, NULL, NULL, false, NULL);
       
        if(aliasUrl != nil) {
            NSString *aliasPath = (NSString*)CFURLCopyFileSystemPath(aliasUrl, kCFURLPOSIXPathStyle);
//            if([[NSFileManager defaultManager] fileExistsAtPath:aliasPath]) {
                printf("%s\t%s\n", [nameRef UTF8String], [aliasPath UTF8String]);
//                [updatedFavorites addObject:favorite];
//            }
//
//            NSLog(@"%@ -> %@", (id)nameRef, (id)aliasPath);
        }
        /*
        BDAlias *bdAliasData = [BDAlias aliasWithData:[favorite valueForKey:@"Alias"]];

        NSString *fullPath = [bdAliasData fullPath];
        if(fullPath != nil) {            
            NSLog(@"bdalias: %@ -> %@", (id)nameRef, (id)[bdAliasData fullPath]);
        }
         */
    }
}

#pragma mark -

static CFDataRef CreateBookmarkDataWithFileSystemPath(CFAllocatorRef allocator, CFURLRef url, CFURLBookmarkCreationOptions options, CFArrayRef resourcePropertiesToInclude, CFURLRef relativeToURL, CFErrorRef* error)
{
    CFDataRef bookmark = NULL;
    CFMutableArrayRef resourceProperties = NULL;
    CFStringRef fileSystemPath;

    // get the file system path
    fileSystemPath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
    if ( fileSystemPath != NULL ) {
        // set kMyFileSystemPathKey as a temporary property on the url
    //    CFURLSetTemporaryResourcePropertyForKey(url, kMyFileSystemPathKey, fileSystemPath);
        
        // copy (we have to make sure it is mutable) or create the resourceProperties directionary
        if ( resourcePropertiesToInclude != NULL ) {
            resourceProperties = CFArrayCreateMutableCopy(allocator, 0, resourcePropertiesToInclude);
        }
        else {
            resourceProperties = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
        }
        if ( resourceProperties != NULL ) {
            // add kMyFileSystemPathKey to the properties to be stored in the bookmark
    //        CFArrayAppendValue(resourceProperties, kMyFileSystemPathKey);
            // create the bookmark data
            bookmark = CFURLCreateBookmarkData (allocator, url, options, resourceProperties, relativeToURL, error );
        }
    }
    return ( bookmark );
}

////////////////////////////////////////
// Print version and author to stdout
///////////////////////////////////////

static void PrintVersion (void)
{
    printf("%s version %s by %s\n", PROGRAM_STRING, VERSION_STRING, AUTHOR_STRING);
}

////////////////////////////////////////
// Print help string to stdout
///////////////////////////////////////

static void PrintHelp (void)
{
    printf("usage: %s [-%s] [source-file] [target-alias]\n", PROGRAM_STRING, OPT_STRING);
}