Environment loadModule:'AppKit'.

fontManager := NSFontManager sharedFontManager.

body   := NSMutableString new.
html   := NSMutableString new.
styles := NSMutableDictionary new.

known_names := NSArray new + 'Helvetica' + 'Times New Roman' + 'Courier' + 'Courier New'.

current_style := ''.
current_alignment := 0.

_span_end_ := [ :clazz |
    (clazz isEqualToString:'') ifFalse: [ body += '</span>'. ].
].

_span_start_ := [ :clazz |
    body += ('<span class="' , clazz , '">').
].

_align_end_ := [ :atype |
    (atype == 0) ifTrue: [ body += '</span></div>'. ].
    (atype == 2) ifTrue: [ body += '</span></center>'. ].
].

_align_start_ := [ :atype |
    (atype == 0) ifTrue: [ body += '<div>'. ].
    (atype == 2) ifTrue: [ body += '<center>'. ].
].

_makeStyle_ := [ :attr |
    font  := attr @ 'NSFont'.
    fname := font familyName.
    fsize := font pointSize.
    ftype := fontManager traitsOfFont:font.
    align := (attr @ 'NSParagraphStyle') alignment.
    under := (attr @ 'NSUnderline').
    link  := (attr @ 'NSLink' description).
    
    known := known_names containsObject:fname.

    (link length > 0) ifTrue: [
        under := 0.
    ].

    style := (fname stringByReplacingOccurrencesOfString:' ' withString:'_') ,
             (fsize stringValue) ,
             '_' , (ftype stringValue) , '_', (under stringValue).

    (align ~= current_alignment) ifTrue: [
        _align_end_   value:current_alignment.
        _align_start_ value:align.
    ].

    (style ~= current_style) ifTrue: [
        _span_end_   value:current_style.
        _span_start_ value:style.
    ].


    css := NSMutableString new.
    css += ('.' , style , '{\n' , 
            'font-size:' , (fsize stringValue) , 'px;\n').

    (known == 1) 
    ifTrue: [
        css += ('font-family:"',fname,'";\n').
    ]
    ifFalse: [
        (ftype and:NSFixedPitchFontMask) ifTrue: [ css += 'font-family:"monospace";\n'].
    ].

    (ftype and:NSBoldFontMask)   ifTrue: [ css += 'font-weight:bold;\n'. ].
    (ftype and:NSItalicFontMask) ifTrue: [ css += 'font-style:italic;\n'. ].

    (under == 1)                 ifTrue: [ css += 'text-decoration:underline;\n'. ].

    css += '}\n'.

    styles setValue:css forKey:style.

    current_alignment := align.
    current_style := style.
].

_printLine_ := [ :attr :text |
    _makeStyle_ value:attr.

    link := (attr @ 'NSLink' description).
    atta := (attr @ 'NSAttachment').
    text := text _stringByExpandingXMLEntities.

    (atta ~= nil) ifTrue: [
        fw   := atta fileWrapper.
        data := fw regularFileContents.
        name := fw preferredFilename stringByDeletingPathExtension.
        base := pout stringByDeletingLastPathComponent.
        imgp := (base / name,'.png').

        Transcript show:('save image to ',imgp).

        rep  := NSBitmapImageRep alloc initWithData:data.
        data := rep representationUsingType:NSPNGFileType properties:nil.
        data writeToFile:imgp atomically:YES.
        rep release.

        text := ('<img src="',name,'.png">').
    ].

    (link length > 0) ifTrue: [
        text := ('<a href="',link,'">',text,'</a>').
    ].
"
    Transcript show:attr.
    Transcript show:'\n\n'.
"   
    body += (text stringByReplacingOccurrencesOfString:'\n' withString:'<br>').
].

_process_file_ := [ :path |
    Transcript showLine:('processing ',path).

    d     := NSNumber pointerForObject.
    astr  := (NSAttributedString  alloc) 
              initWithPath:path documentAttributes:d.

    dattr := d objectValue.
    title := path lastPathComponent stringByDeletingPathExtension.

    Transcript showLine:(dattr).

    i    := 0.
    sz   := astr length.
    p    := NSNumber pointerForRange.

    html += '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'.
    html += '<html>'.

    body += '<body><article>'.

    _align_start_ value:0.

    "parse the RTF file"

    [i < sz] whileTrue: [
        attr := astr attributesAtIndex:i effectiveRange:p.
        r := p rangeValue.

        text := astr string substringWithRange:r.
        i := (r location) + (r length).

        _printLine_ value:attr value:text.
    ].

    _align_end_ value:current_alignment.

    body += '</article></body>'.
    html += ('<head><title>',title,'</title>').
    html += '<style>'.

    "write page style"

    style_file := Controller currentFileScript fileName 
                    stringByDeletingPathExtension
                    stringByAppendingString:'.css'.

    Transcript showLine:('loading document style from ',style_file).

    html += (NSString stringWithContentsOfFile:style_file).

    "write all used styles"

    (styles allKeys) do: [ :key |
            html += (styles @ key).
    ].

    html += '</style></head>'.
    html += body += '</html>'.

    astr release.
].

pout := ''.
panel := NSSavePanel savePanel.
rv := panel runModal.

(rv > 0)
ifTrue: [
    path := TextEdit currentDocument documentName.
    pout := panel filename.

    _process_file_ value:path.

    "write final output"

    html writeToFile:pout atomically:NO.
    Transcript showLine:('wrote to ',pout).

    "open it in the workspace"

    NSWorkspace sharedWorkspace openFile:pout.
]
ifFalse: [
    Transcript showLine:'exit'.
].
