======
Sketch
======
Sketch showcases some of the main AppKit features including:  the document architecture, AppleScript support, NSUndoManager, and NSBezierPath.  In addition, and perhaps more importantly, Sketch is a good example of the Model-View-Controller (MVC) pattern which many of the new features of the AppKit are designed to work best with.  While it is possible to use the new features such as NSDocument, NSUndoManager, and scripting support without an underlying MVC design, it is much easier and better if your application does use the MVC pattern.

Sketch is not a commercial graphics application.  There are some things about the architecture that are intentionally simpler than they would be if it were a commercial application.  For example, there is no architecture for dynamically loading graphic types, drawing effects, or custom inspectors. 


Things of note
==============

Model-View-Controller Design
----------------------------
The Model layer of Sketch is mainly the SKTGraphic class and its subclasses.  A Sketch Document is made up of a list of SKTGraphics.  SKTGraphics are mainly data-bearing classes.  Each graphic keeps all the information required to represent whatever kind of graphic it is.  The SKTGraphic class defines a set of primitive methods for modifying a graphic and some of the subclasses add new primitives of their own.  The SKTGraphic class also defines some extended methods for modifying a graphic which are implemented in terms of the primitives.

The SKTGraphic class defines a set of methods that allow it to draw itself.  While this may not strictly seem like it should be part of the model, keep in mind that what we are modeling is a collection of visual objects.  Even though a SKTGraphic knows how to render itself within a view, it is not a view itself.

The Controller layer consists of the Model-Controller class SKTDocument and the View-Controller class SKTWindowController as well as other NSWindowController subclasses which control the app's auxiliary panels.  The notion of splitting the control layer into two tiers is sometimes useful when considering the new document architecture.  The NSDocument class is most closely tied to the model.  It "owns" the model and is intimately concerned with controlling the model's persistence.  The NSWindowController class is most closely tied to the view.  It "owns" the UI and controls it.  NSDocument and NSWindowController cooperate together to bridge the gap between the model and the view of an application.

The View layer consists mainly of the SKTGraphicView class.  (Technically, it also includes the window, and all the app's panels and menus, but these are almost entirely made up of standard AppKit classes.)  SKTGraphicView manages the presentation of the SKTGraphics in a document to the user and allows the user to manipulate those graphics directly and through menu commands and auxiliary panels.

AppKit Document Architecture
----------------------------
Sketch uses AppKit's document architecture which is comprised mainly of the three classes NSDocument, NSDocumentController, and NSWindowController.  SKTDocument is a subclass of NSDocument.  SKTWindowController is a subclass of NSWindowController.

Sketch merely implements the subclass responsibilities and inherits almost all of the standard behavior of a multi-document app.

SKTDocument adds storage and management of the list of SKTGraphics that makes up a document.  It also implements the methods for saving and loading the graphics.

AppleScript Support
-------------------
Sketch is scriptable.  It contains a scriptSuite and scriptTerminology that define its scripting terminology (building on the Core suite and Text suite defined by the scripting frameworks).  It also contains code in the SKTDocument and SKTGraphic classes to support scripting.

Most of the code is pretty simple stuff that defines keys for scripting, but Sketch does have some examples of more advanced Scripting support.  

In particular the SKTDocument class defines several keys (circles, rectangles, lines, images, textAreas) that are really just subsets of the graphics key.  It includes special NSScriptObjectSpecifier evaluation code to allow scripts to refer to things like "the rectangle after the first circle" or "the graphics from circle 1 to line 5".  These types of specifiers can not be directly evaluated by the default scripting machinery, but they make sense, so Sketch handles them specially.

Another area of interest is the SKTGraphic class' objectSpecifier() implementation.  This method allows a SKTGraphic object to construct an NSScriptObjectSpecifier that identifies it.  When a script command's result cannot  be translated into a native AppleScript type, the result will be sent back to ScriptEditor as an object specifier if the object can provide one.  SKTGraphic's implementation of objectSpecifier() allows this to work for SKTGraphic objects.

AppKit Undo
-----------
Sketch uses the NSUndoManager to implement full Undo.  It is interesting to note that there is really very little Undo-related code.

Basically, all the primitives in SKTGraphic (and its subclasses) which alter the graphic are in charge of registering undo invocations for the changes they perform.  SKTDocument is in charge of registering undo invocations for changes such as the addition, removal, and reordering of SKTGraphics.  This is the bulk of the undo support and it is the only essential part.

SKTGraphicView (and some of the panel controllers) also do a little undo-related stuff.  They register reasonable names for undo groups.  Because SKTGraphicView and the panel controllers are the entry points for user actions, they know the semantic details of what's happening.  They are in a position to name undo groups in ways that make sense.

Finally, because SKTGraphicView keeps track of the selection, and changes in selection should be undone along with actual changes to the document, SKTGraphicView adds some extra undo support to register undo invocations for selection changes.  These are purely cosmetic undo invocations since they have no effect on the persistent state of the document, but they make the experience of undoing stuff much more visually sensible.

All in all, there are about 20 lines of code that actually register undo invocations and about 35 lines that register an action name.

NSBezierPath
------------
Sketch uses NSBezierPath to draw most of its simple graphic types.

The base SKTGraphic class defines a method which returns a NSBezierPath.  If a subclass overrides this to return a path, then the SKTGraphic base class can handle all the drawing itself.  Some more complex subclasses such as SKTText and SKTImage do not use the bezierPath API.  They override drawInView:isSelected: instead to do their own drawing.

Use of NSWindowController for panels
------------------------------------
The NSWindowController class was added mainly to support the new document architecture, but it is actually quite useful on its own.  An NSWindowController owns and manages a nib file.  Among other things, it will assume ownership and responsibility for releasing all the top-level objects in a nib file (something that was fairly tedious before).

NSWindowController is therefore quite useful as a controller for the non-document panels in your application as well as for the document windows.  All the panels in Sketch have an NSWindowController subclass to manage them.
