app := WebBrowser.
url := app currentDocument currentURL.

(url = nil) ifFalse: [
  doc := app newDocument.
  doc loadPage:url.
].
