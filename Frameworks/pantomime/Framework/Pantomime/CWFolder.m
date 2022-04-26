/*
**  CWFolder.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**                2013-2020 Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola <rm@gnu.org>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <Pantomime/CWFolder.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWContainer.h>
#import <Pantomime/CWFlags.h>
#import <Pantomime/CWMessage.h>
#import <Pantomime/NSString+Extensions.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSMapTable.h>

//
//
//
@implementation CWFolder 

- (id) initWithName: (NSString *) theName
{
  self = [super init];

  if (self)
    {
      _properties = [[NSMutableDictionary alloc] init];
      _allVisibleMessages = nil;
  
      allMessages = [[NSMutableArray alloc] init];
  
      //
      // By default, we don't do message threading so we don't
      // initialize this ivar for no reasons
      //
      _allContainers = nil;
      _cacheManager = nil;
      _mode = PantomimeUnknownMode;

      [self setName: theName];
      [self setShowDeleted: NO];
      [self setShowRead: YES];
    }
  return self;
}


//
//
//
- (void) dealloc
{
  //NSLog(@"Folder: -dealloc");
  RELEASE(_properties);
  RELEASE(_name);
  TEST_RELEASE(_allContainers);

  //
  // To be safe, we set the value of the _folder ivar of all CWMessage
  // instances to nil value in case something is retaining them.
  //
  [allMessages makeObjectsPerformSelector: @selector(setFolder:) withObject: nil];
  RELEASE(allMessages);

  TEST_RELEASE(_allVisibleMessages);
  TEST_RELEASE(_cacheManager);

  [super dealloc];
}


//
// NSCopying protocol (FIXME)
//
- (id) copyWithZone: (NSZone *) zone
{
  return RETAIN(self);
}


//
//
//
- (NSString *) name
{
  return _name;
}


//
//
//
- (void) setName: (NSString *) theName
{
  ASSIGN(_name, theName);
}


//
//
//
- (void) appendMessage: (CWMessage *) theMessage
{
  if (theMessage)
    {
      [allMessages addObject: theMessage];
      
      if (_allVisibleMessages)
	{
	  [_allVisibleMessages addObject: theMessage];
	}

      // FIXME
      // If we've done message threading, we simply append the message
      // to the end of our containers array. We might want to place
      // it in the right thread in the future.
      if (_allContainers)
	{
	  CWContainer *aContainer;

	  aContainer = [[CWContainer alloc] init];
	  aContainer->message = theMessage;
	  [theMessage setProperty: aContainer  forKey: @"Container"];
	  [_allContainers addObject: aContainer];
	  RELEASE(aContainer);
	}
    }
}


//
//
//
- (void) appendMessageFromRawSource: (NSData *) theData
                              flags: (CWFlags *) theFlags
{
  [self subclassResponsibility: _cmd];
}


//
//
//
- (NSArray *) allContainers
{
  return _allContainers;
}


//
//
//
- (NSArray *) allMessages
{ 
  if (_allVisibleMessages == nil)
    {
      NSUInteger i, count;

      count = [allMessages count];
      _allVisibleMessages = [[NSMutableArray alloc] initWithCapacity: count];

      // quick
      if (_show_deleted && _show_read)
	{
	  [_allVisibleMessages addObjectsFromArray: allMessages];
	  return _allVisibleMessages;
	}

      for (i = 0; i < count; i++)
	{
	  CWMessage *aMessage;
	  
	  aMessage = [allMessages objectAtIndex: i];
      
	  // We show or hide deleted messages
	  if (_show_deleted)
	    {
	      [_allVisibleMessages addObject: aMessage];
	    }
	  else
	    {
	      if ([[aMessage flags] contain: PantomimeDeleted])
		{
		  // Do nothing
		  continue;
		}
	      else
		{
		  [_allVisibleMessages addObject: aMessage];
		}
	    }

	  // We show or hide read messages
	  if (_show_read)
	    {
	      if (![_allVisibleMessages containsObject: aMessage])
		{
		  [_allVisibleMessages addObject: aMessage];
		}
	    }
	  else
	    {
	      if ([[aMessage flags] contain: PantomimeSeen])
		{
		  if (![[aMessage flags] contain: PantomimeDeleted])
		    {
		      [_allVisibleMessages removeObject: aMessage];
		    }
		}
	      else if (![_allVisibleMessages containsObject: aMessage])
		{
		  [_allVisibleMessages addObject: aMessage];
		}
	    }
	}
    }

  return _allVisibleMessages;
}


//
//
//
- (void) setMessages: (NSArray *) theMessages
{
  if (theMessages)
    {
      RELEASE(allMessages);
      allMessages = [[NSMutableArray alloc] initWithArray: theMessages];

      if (_allContainers)
	{
	  [self thread];
	}
    }
  else
    {
      DESTROY(allMessages);
    }

  DESTROY(_allVisibleMessages);
}


//
//
//
- (CWMessage *) messageAtIndex: (NSUInteger) theIndex
{
  if (theIndex >= [self count])
    {
      return nil;
    }
  
  return [[self allMessages] objectAtIndex: theIndex];
}


//
//
//
- (NSUInteger) count
{
  return [[self allMessages] count];
}


//
//
//
- (void) close
{
  [self subclassResponsibility: _cmd];
  return;
}


//
//
//
- (void) expunge
{
  [self subclassResponsibility: _cmd];
}


//
//
//
- (id) store
{
  return _store;
}


//
// No need to retain the store here since our store object
// retains our folder object.
//
- (void) setStore: (id) theStore
{
  _store = theStore;
}


//
//
//
- (void) removeMessage: (CWMessage *) theMessage
{
  if (theMessage)
    {
      [allMessages removeObject: theMessage];
      
      if (_allVisibleMessages)
	{
	  [_allVisibleMessages removeObject: theMessage];
	}

      // FIXME - We must go through our _allContainers ivar in order
      //         to find the message that has just been removed from
      //         this folder. We must go through all levels.
      //         Right now, we simply do again our message threading algo
      if (_allContainers)
	{
	  [self thread];
	}
    }
}


//
//
//
- (BOOL) showDeleted
{
  return _show_deleted;
}


//
//
//
- (void) setShowDeleted: (BOOL) theBOOL
{
  if (theBOOL != _show_deleted)
    {
      _show_deleted = theBOOL;
      DESTROY(_allVisibleMessages);
    }
}


//
//
//
- (BOOL) showRead
{
  return _show_read;
}


//
//
//
- (void) setShowRead: (BOOL) theBOOL
{
  if (theBOOL != _show_read)
    {
      _show_read = theBOOL;
      DESTROY(_allVisibleMessages);
    }
}


//
//
//
- (NSUInteger) numberOfDeletedMessages
{
  NSUInteger c, i, count;
  
  c = [allMessages count];
  count = 0;

  for (i = 0; i < c; i++)
    {
      if ([[[allMessages objectAtIndex: i] flags] contain: PantomimeDeleted])
	{
	  count++;
	}
    }

  return count;
}


//
//
//
- (NSUInteger) numberOfUnreadMessages
{
  NSUInteger i, c, count;
  
  c = [allMessages count];
  count = 0;
  
  for (i = 0; i < c; i++)
    {
      if (![[[allMessages objectAtIndex: i] flags] contain: PantomimeSeen])
	{
	  count++;
	}
    }

  return count;
}


//
//
//
- (unsigned long) size;
{
  unsigned long size;
  NSUInteger c, i;

  c = [allMessages count];
  size = 0;
  
  for (i = 0; i < c; i++)
    {
      size += [(CWMessage *)[allMessages objectAtIndex: i] size];
    }

  return size;
  
}


//
//
//
- (void) updateCache
{
  DESTROY(_allVisibleMessages);
}


//
//
//
- (void) thread
{
  NSMapTable *id_table, *subject_table;
  NSAutoreleasePool *pool;
  NSUInteger i, count;

  // We clean up ...
  TEST_RELEASE(_allContainers);

  // We create our local autorelease pool
  pool = [[NSAutoreleasePool alloc] init];

  // Build id_table and our containers mutable array
  id_table = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 16);
  _allContainers = [[NSMutableArray alloc] init];

  //
  // 1. A., B. and C.
  //
  count = [allMessages count];
  for (i = 0; i < count; i++)
    {
      CWContainer *aContainer;
      CWMessage *aMessage;
      
      NSString *aReference;
      NSUInteger j;

      // So that gcc shutup
      aMessage = nil;
      aReference = nil;

      aMessage = [allMessages objectAtIndex: i];
      
      // We skip messages that don't have a valid Message-ID
      if (![aMessage messageID])
      	{
	  aContainer = [[CWContainer alloc] init];
	  aContainer->message = aMessage;
	  [aMessage setProperty: aContainer  forKey: @"Container"];
	  [_allContainers addObject: aContainer];
	  RELEASE(aContainer);
      	  continue;
      	}
      
      //
      // A.
      //
      aContainer = NSMapGet(id_table, [aMessage messageID]);
      
      if (aContainer)
	{
	  //aContainer->message = aMessage;
	  
	  if (aContainer->message != aMessage)
	    {
	      aContainer = [[CWContainer alloc] init];
	      aContainer->message = aMessage;
	      [aMessage setProperty: aContainer  forKey: @"Container"];
	      NSMapInsert(id_table, [aMessage messageID], aContainer);
	      DESTROY(aContainer);
	    }
	}
      else
	{
	  aContainer = [[CWContainer alloc] init];
	  aContainer->message = aMessage;
	  [aMessage setProperty: aContainer  forKey: @"Container"];
	  NSMapInsert(id_table, [aMessage messageID], aContainer);
	  DESTROY(aContainer);
	}
      
      //
      // B. For each element in the message's References field:
      //
      for (j = 0; j < [[aMessage allReferences] count]; j++)
	{
	  // We get a Message-ID
	  aReference = [[aMessage allReferences] objectAtIndex: j];

	  // Find a container object for the given Message-ID
	  aContainer = NSMapGet(id_table, aReference);
	  
	  if (aContainer)
	    {
	      // We found it. We use that.
	    }
	  // Otherwise, make (and index) one (new Container) with a null Message
	  else 
	    {
	      aContainer = [[CWContainer alloc] init];
	      NSMapInsert(id_table, aReference, aContainer);
	      RELEASE(aContainer);
	    }
	  
	  // NOTE:
	  // aContainer is valid here. It points to the message (could be a nil message)
	  // that has a Message-ID equals to the current aReference value.
	  
	  // If we are currently using the last References's entry of our list,
	  // we simply break the loop since we are gonna set it in C.
	  //if ( j == ([[aMessage allReferences] count] - 1) )
	  //  {
	  //    break;
	  // }

	  // Link the References field's Containers together in the order implied by the References header.
	  // The last references
	  if (j == ([[aMessage allReferences] count] - 1) &&
	      aContainer->parent == nil)
	    {
	      // We grab the container of our current message
	      [((CWContainer *)NSMapGet(id_table, [aMessage messageID])) setParent: aContainer];
	    }
	  
	  // We set the child
	  //if ( aContainer->message != aMessage &&
	  //     aContainer->child == nil )
	  //  {
	  //    [aContainer setChild: NSMapGet(id_table, [aMessage messageID])];
	  //  }	      

	} // for (j = 0; ...
      
      // NOTE: The loop is over here. It was an ascending loop so
      //       aReference points to the LAST reference in our References list

      //
      // C. Set the parent of this message to be the last element in References. 
      //
      // NOTE: Again, aReference points to the last Message-ID in the References list
      
      // We get the container for the CURRENT message
      aContainer = (CWContainer *)NSMapGet(id_table, [aMessage messageID]);
      
      // If we have no References and no In-Reply-To fields, we simply set a
      // the parent to nil since it can be the message that started the thread.
      if ([[aMessage allReferences] count] == 0 &&
	  [aMessage headerValueForName: @"In-Reply-To"] == nil)
	{
	  [aContainer setParent: nil];
	}
      // If we have no References but an In-Reply-To field, that becomes our parent.
      else if ([[aMessage allReferences] count] == 0 &&
	       [aMessage headerValueForName: @"In-Reply-To"])
	{
	  [aContainer setParent: (CWContainer *)NSMapGet(id_table, [aMessage headerValueForName: @"In-Reply-To"])];
	  // FIXME, should we really do that? or should we do it in B?
	  [(CWContainer *)NSMapGet(id_table, [aMessage headerValueForName: @"In-Reply-To"]) setChild: aContainer];
	}
      else
	{
	  [aContainer setParent: (CWContainer *)NSMapGet(id_table, aReference)];
	  [(CWContainer *)NSMapGet(id_table, aReference) setChild: aContainer];
	}
      
    } // for (i = 0; ...

  //
  // 2. Find the root set.
  //
  [_allContainers addObjectsFromArray: NSAllMapTableValues(id_table)];

  //while (NO)
  for (i = ([_allContainers count]); i > 0; i--)
    {
      CWContainer *aContainer;
      
      aContainer = [_allContainers objectAtIndex: i-1];
      
      if (aContainer->parent != nil)
	{
	  [_allContainers removeObjectAtIndex: i-1];
	}
    }

  //
  // 3. Discard id_table.
  //
  NSFreeMapTable(id_table);

  
  //
  // 4. Prune empty containers.
  //
  //while (NO)
  for (i = ([_allContainers count]); i > 0; i--)
    {
      CWContainer *aContainer;

      aContainer = [_allContainers objectAtIndex: i-1];
      
      // Recursively walk all containers under the root set.
      while (aContainer)
	{
	  // A. If it is an empty container with no children, nuke it
	  if (aContainer->message == nil &&
	      aContainer->child == nil)
	    {
	      // We nuke it
	      // FIXME: Won't work for non-root containers.
	      [_allContainers removeObject: aContainer];
	    }
	  
	  // B. If the Container has no Message, but does have children, remove this container but 
	  //    promote its children to this level (that is, splice them in to the current child list.)
	  //    Do not promote the children if doing so would promote them to the root set 
	  //    -- unless there is only one child, in which case, do. 
	  // FIXME: We promote to the root no matter what :)
	  if (aContainer->message == nil && aContainer->child)
	    {
	      CWContainer *c;
	      
	      c = aContainer;
	      RETAIN(c);
	      [c->child setParent: nil];
	      [_allContainers removeObject: c];
	      [_allContainers addObject: c->child]; // We promote the the root for now
	     
	      // We go to our child and we continue to loop
	      //aContainer = aContainer->child;
	      aContainer = [aContainer childAtIndex: ([aContainer count]-1)];
	      RELEASE(c);
	      continue;
	    }
	  
	  //aContainer = aContainer->child;
	  aContainer = [aContainer childAtIndex: ([aContainer count]-1)];
	}

    }
  
  //
  // 5. Group root set by subject.
  //
  // A. Construct a new hash table, subject_table, which associates subject 
  //    strings with Container objects.
  subject_table = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 16);

  //
  // B. For each Container in the root set:
  //
    
  //while (NO)
  for (i = 0; i < [_allContainers count]; i++)
    {
      CWContainer *aContainer;
      CWMessage *aMessage;
      NSString *aString;

      aContainer = [_allContainers objectAtIndex: i];
      aMessage = aContainer->message;
      aString = [aMessage subject];
      
      if (aString)
	{
	  aString = [aMessage baseSubject];

	  // If the subject is now "", give up on this Container.
	  if ([aString length] == 0)
	    {
	      //aContainer = aContainer->child;
	      continue;
	    }
	  
	  // We set the new subject
	  //[aMessage setSubject: aString];
	  
	  // Add this Container to the subject_table if:
	  // o There is no container in the table with this subject, or
	  // o This one is an empty container and the old one is not: 
	  //   the empty one is more interesting as a root, so put it in the table instead.
	  // o The container in the table has a ``Re:'' version of this subject, 
	  //   and this container has a non-``Re:'' version of this subject. 
	  //   The non-re version is the more interesting of the two.
	  if (!NSMapGet(subject_table, aString))
	    {
	      NSMapInsert(subject_table, aString, aContainer);
	    }
	  else
	    {
	      NSString *aSubject;
	      
	      // We obtain the subject of the message of our container.
	      aSubject = [((CWContainer *)NSMapGet(subject_table, aString))->message subject];

	      if ([aSubject hasREPrefix] && ![[aMessage subject] hasREPrefix])
		{
		  // We replace the container
		  NSMapRemove(subject_table, aString);
		  NSMapInsert(subject_table, [aMessage subject], aContainer);
		}
	    }
	  
	} // if ( aString )
    }
  
  //
  // C. Now the subject_table is populated with one entry for each subject which occurs in 
  //    the root set. Now iterate over the root set, and gather together the difference.
  //
  for (i = ([_allContainers count]); i > 0; i--)
    {
      CWContainer *aContainer, *containerFromTable;
      NSString *aSubject, *aString;

      aContainer = [_allContainers objectAtIndex: i-1];
      
      // Find the subject of this Container (as above.)
      aSubject = [aContainer->message subject];
      aString = [aContainer->message baseSubject];
      
      // Look up the Container of that subject in the table.
      // If it is null, or if it is this container, continue.
      containerFromTable = NSMapGet(subject_table, aString);
      if (!containerFromTable || containerFromTable == aContainer) 
	{
	  continue; 
	}
      
      // If that container is a non-empty, and that message's subject does 
      // not begin with ``Re:'', but this message's subject does, then make this be a child of the other.
      if (![[containerFromTable->message subject] hasREPrefix] &&
	  [aSubject hasREPrefix])
	{
	  [aContainer setParent: containerFromTable];
	  [containerFromTable setChild: aContainer]; 
	  [_allContainers removeObject: aContainer];
	}
      // If that container is a non-empty, and that message's subject begins with ``Re:'', 
      // but this  message's subject does not, then make that be a child of this one -- 
      // they were misordered. (This happens somewhat implicitly, since if there are two
      // messages, one with Re: and one without, the one without will be in the hash table,
      // regardless of the order in which they were seen.)
      else if ([[containerFromTable->message subject] hasREPrefix] &&
	       ![aSubject hasREPrefix])
	{
	  [containerFromTable setParent: aContainer];
	  [aContainer setChild: containerFromTable]; 
	  [_allContainers removeObject: containerFromTable];
	}
      // Otherwise, make a new empty container and make both msgs be a child of it. 
      // This catches the both-are-replies and neither-are-replies cases, and makes them 
      // be siblings instead of asserting a hierarchical relationship which might not be true.
      else
	{
#if 0
	  // FIXME - not so sure about that step.
	  CWContainer *aNewContainer;
	  
	  aNewContainer = [[CWContainer alloc] init];
	  
	  [aContainer setParent: aNewContainer];
	  [containerFromTable setParent: aNewContainer];
	  
	  [aNewContainer setChild: aContainer]; 
	  [aNewContainer setChild: containerFromTable];
	  [_allContainers addObject: aNewContainer];
	  RELEASE(aNewContainer);
	  
	  // We remove ..
	  [_allContainers removeObject: aContainer];
	  [_allContainers removeObject: containerFromTable];
#endif
	}
    }
  
  NSFreeMapTable(subject_table);

  //
  // 6.  Now you're done threading!
  //
  //     Specifically, you no longer need the ``parent'' slot of the Container object, 
  //     so if you wanted to flush the data out into a smaller, longer-lived structure, you 
  //     could reclaim some storage as a result. 
  //
  // GNUMail.app DOES USE the parent slot so we keep it.

  //
  // 7.  Now, sort the siblings.
  //     
  //     At this point, the parent-child relationships are set. However, the sibling ordering 
  //     has not been adjusted, so now is the time to walk the tree one last time and order the siblings 
  //     by date, sender, subject, or whatever. This step could also be merged in to the end of step 4, 
  //     above, but it's probably clearer to make it be a final pass. If you were careful, you could 
  //     also sort the messages first and take care in the above algorithm to not perturb the ordering,
  //      but that doesn't really save anything. 
  //
  // By default we at least sort everything by number.
  //[_allContainers sortUsingSelector: @selector(compareAccordingToNumber:)];

  RELEASE(pool);
}


//
//
//
- (void) unthread
{
  NSUInteger count;

  count = [allMessages count];
  
  while (count--)
    {
      [[allMessages objectAtIndex: count] setProperty: nil  forKey: @"Container"];
    }

  DESTROY(_allContainers);
}

//
//
//
- (void) search: (NSString *) theString
	   mask: (PantomimeSearchMask) theMask
	options: (PantomimeSearchOption) theOptions
{
  [self subclassResponsibility: _cmd];
}


//
//
//
- (CWCacheManager *) cacheManager
{
  return _cacheManager;
}

- (void) setCacheManager: (id) theCacheManager
{
  ASSIGN(_cacheManager, theCacheManager);
}


//
//
//
- (PantomimeFolderMode) mode
{
  return _mode;
}


//
//
//
- (void) setMode: (PantomimeFolderMode) theMode
{
  _mode = theMode;
}


//
//
//
- (void) setFlags: (CWFlags *) theFlags
         messages: (NSArray *) theMessages
{
  NSUInteger c, i;

  c = [theMessages count];
  for (i = 0; i < c; i++)
    {
      [[theMessages objectAtIndex: i] setFlags: theFlags];
    }
}


//
//
//
- (id) propertyForKey: (id) theKey
{
  return [_properties objectForKey: theKey];
}


//
//
//
- (void) setProperty: (id) theProperty
	      forKey: (id) theKey
{
  if (theProperty)
    {
      [_properties setObject: theProperty  forKey: theKey];
    }
  else
    {
      [_properties removeObjectForKey: theKey];
    }
}

@end



