include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.4
PACKAGE_NAME = HelpViewer
APP_NAME = HelpViewer

HelpViewer_OBJC_FILES = main.m mainWindowController.m Label.m \
			Controller.m FigureCell.m Legend.m\
			HistoryManager.m \
			HandlerStructureXLP.m \
			TextFormatterXLP.m \
			BrowserCell.m NoteCell.m \
			ModNSString.m BRCell.m Page.m Section.m # Parser.m # Table.m BRCell.m ViewCell.m TextViewCell.m

HelpViewer_RESOURCE_FILES = Resources/Index.tiff Resources/Back.tiff Resources/Search.tiff Resources/Bookshelf.tiff Resources/HelpViewer.tiff \
			Resources/helpviewer-200.tiff Resources/Logo.tiff \
			Resources/part.tiff Resources/chapter.tiff Resources/notloaded.tiff Resources/errorloading.tiff \
			Resources/note.png Resources/caution.png Resources/listing.png Resources/information.png \
			Resources/Point.tiff Resources/Point2.tiff Resources/Icon-hlpd.tiff\
			Resources/GSFindPanel.gorm \
			Resources/MainMenu.gorm HelpViewer.help
HelpViewer_MAIN_MODEL_FILE = MainMenu.gorm
#HelpViewer_PRINCIPAL_CLASS = NSApplication

HelpViewer_LANGUAGES = English

#HelpViewer_LOCALIZED_RESOURCE_FILES = Logo.tiff helpviewer-200.tiff $(APP_NAME).xlp

include $(GNUSTEP_MAKEFILES)/application.make
