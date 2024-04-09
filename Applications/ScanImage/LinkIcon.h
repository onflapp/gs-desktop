/*

*/

#ifndef _LinkIcon_h_
#define _LinkIcon_h_

@interface LinkIcon : NSImageView
{
  IBOutlet id delegate;
  NSString* linkToDrag;
}

@end

#endif
