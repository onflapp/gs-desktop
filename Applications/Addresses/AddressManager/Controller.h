/* This is -*- ObjC -*- */

#include <AppKit/AppKit.h>
#include <Addresses/Addresses.h>

@interface Controller : NSObject
{
  NSFileManager *_fm;
  NSArray *_peopleCache; ADGroup *_currentGroup;
  ADAddressBook *_book;
  
  id personView, scrollView, clipView;
  id groupsBrowser;
  id editButton, editItem, shareItem;
  id mergePersonsItem;
  id duplicatePersonItem;
  id thisIsMeItem;

  id prefsPanel;
  id prefsAutosaveButton;
  id prefsAddressLayoutPopup;
  id prefsScreenNameLayoutMatrix;

  id lastCell;

  BOOL _changed, _selfChanging;
  BOOL _selectedByDrop;

  NSDictionary *_countryCodeDict;
}

- (void) createCache;
- (NSArray *) groupNames;

- (void) selectGroup: (ADGroup*) group;
- (void) selectPerson: (ADPerson*) person;
- (void) deletePersonAndSelectNext: (ADPerson*) person;
- (void) beginEditingPerson: (ADPerson*) person;
- (void) finishEditingPerson;

- (void) doEditPerson: (id) sender;
- (void) doTogglePersonEditable: (id) sender;
- (void) doCreatePerson: (id) sender;
- (IBAction) doDeletePerson: (id) sender;
- (void) doImportPerson: (id) sender;
- (void) doExportPerson: (id) sender;
- (void) doSetMe: (id) sender;
- (void) doShowMe: (id) sender;
- (void) doSelectAllPersons: (id) sender;
- (void) doToggleShared: (id) sender;
- (void) doDuplicatePerson: (id) sender;
- (void) doMergePersons: (id) sender;

- (void) doCreateGroup: (id) sender;
- (void) doDeleteGroup: (id) sender;
- (void) doSaveDatabase: (id) sender;

- (void) initPrefsPanel;
- (void) doShowPrefsPanel: (id) sender;
- (void) prefsToggleAutosave: (id) sender;
- (void) prefsChangeAddressLayout: (id) sender;
- (void) prefsChangeScreenNameLayout: (id) sender;

- (void) handleDatabaseChanged: (NSNotification*) note;
- (void) handleDatabaseChangedExternally: (NSNotification*) note;
- (void) handleNameChanged: (NSNotification*) note;
@end
