PROJECT = Cynthiune

SOURCES := FormatTester.m \
	GeneralPreference.m \
	InfoDisplayController.m \
	MainController.m \
	Player.m \
	Playlist.m \
	PlaylistController.m \
	PlaylistFile.m \
	PreferencesController.m \
	Song.m \
	TableViewController.m \
	main.m \
	utils.m

RESOURCES := COPYING \
	ChangeLog \
	Cynthiune.nib \
	Preferences.nib \
	GeneralPreference.nib \
	Images/Cynthiune.icns \
	Images/cynthiune-splash-faded-fr.tiff \
	Images/cynthiune-splash-fr.tiff \
	Images/cynthiune-splash-faded.tiff \
	Images/cynthiune-splash.tiff \
	Images/eject-pushed.tiff \
	Images/eject.tiff \
	Images/nomute.tiff \
	Images/mute.tiff \
	Images/next-pushed.tiff \
	Images/next.tiff \
	Images/pause-pushed.tiff \
	Images/pause.tiff \
	Images/play-pushed.tiff \
	Images/play.tiff \
	Images/playlist-hide.tiff \
	Images/playlist-show.tiff \
	Images/previous-pushed.tiff \
	Images/previous.tiff \
	Images/repeat-off.tiff \
	Images/repeat-on.tiff \
	Images/shuffle-off.tiff \
	Images/shuffle-on.tiff \
	Images/stop-pushed.tiff \
	Images/stop.tiff

OBJECTS := $(SOURCES:.m=.o)

VORBIS_LIBS := -lvorbis -lvorbisfile -logg
MAD_LIBS := $(shell pkg-config mad --libs)
ID3TAG_LIBS := $(shell pkg-config id3tag --libs)

LIBS := -framework AppKit #  -framework AudioUnit -framework AudioToolbox # \

#	$(VORBIS_LIBS) \
#	$(MAD_LIBS) \
#	$(ID3TAG_LIBS)

CC := gcc

CFLAGS := -fconstant-string-class=NSConstantString

ifeq ($(debug), yes)
CFLAGS += -g -O0
endif

MACOSXDIRSTRUCT := $(PROJECT).app
MACOSXAPPDIRSTRUCT := $(MACOSXDIRSTRUCT)/Contents/MacOS
MACOSXRESDIRSTRUCT := $(MACOSXDIRSTRUCT)/Contents/Resources

all: $(MACOSXAPPDIRSTRUCT)/$(PROJECT)

.m.o:
	@echo "    Compiling $<..."
	@$(CC) $(CFLAGS) -c $< -o $@

$(MACOSXDIRSTRUCT): $(MACOSXAPPDIRSTRUCT) $(MACOSXRESDIRSTRUCT) $(MACOSXDIRSTRUCT)/Contents/PkgInfo $(MACOSXDIRSTRUCT)/Contents/Info.plist

$(MACOSXDIRSTRUCT)/Contents/PkgInfo: PkgInfo
	@echo "Adding $<..."
	@cp PkgInfo $(MACOSXDIRSTRUCT)/Contents/

$(MACOSXDIRSTRUCT)/Contents/Info.plist: Info.plist
	@echo "Adding $<..."
	@cp Info.plist $(MACOSXDIRSTRUCT)/Contents/

$(MACOSXRESDIRSTRUCT): $(RESOURCES)
	@echo "Creating $(MACOSXAPPDIRSTRUCT)..."
	@-rm -rf $(MACOSXRESDIRSTRUCT)/
	@mkdir -p $(MACOSXRESDIRSTRUCT)/
	@echo "Copying resources..."
	@cp -R $(RESOURCES) $(MACOSXRESDIRSTRUCT)/

$(MACOSXAPPDIRSTRUCT):
	@echo "Creating $(MACOSXAPPDIRSTRUCT)..."
	@mkdir -p $(MACOSXAPPDIRSTRUCT)/

$(MACOSXAPPDIRSTRUCT)/$(PROJECT): $(OBJECTS) $(MACOSXDIRSTRUCT)
	@echo "    Linking $(MACOSXDIRSTRUCT)"
	@$(CC) -o $(MACOSXAPPDIRSTRUCT)/$(PROJECT) $(OBJECTS) $(LIBS)

clean:
	@echo "Cleaning object files and application directory..."
	@-rm -rf $(OBJECTS) *~ $(PROJECT).app *~.*

