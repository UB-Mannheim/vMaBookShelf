# vMaBookShelf

Copyright (C) 2014–2016 Universitätsbibliothek Mannheim

Authors: Bernd Fallert (UB Mannheim)

This is free software. You may use it under the terms of the
GNU General Public License (GPL). See [LICENSE](LICENSE) for details.


## Summary

vMaBookShelf creates a virtual bookshelf:

- creates static websites
- download covers from Amazon
- creates qr-codes with link to a proxy-server
  (reason: shorten the links in the qr-code), this proxy-server can call
  your local Primo / Opac
- includes a proxy script for connections to other web pages (eBooks ...)
- includes a Firefox Add-on "vMaBookShelfHelper" for these tasks:
  - wrap the content of other web pages in an iframe
  - create two timers:
    - timer one shows a random part of the subjects-html-files and
    - timer two closes all web pages (ebook or opac) and shows the
      virtual bookshelf again


## Installation

Mannheim University Library develops and installs the vMaBookShelf web
application on a virtual server with Debian GNU Linux.

See [INSTALL.md](INSTALL.md) for details.


## Bug reports

Please send your bug reports to https://github.com/UB-Mannheim/vMaBookShelf/issues.
Make sure that you are using the latest version of the software
before sending a report.


## Contributing

Bug fixes, new functions, suggestions for new features and
other user feedback are appreciated.

The source code is available from https://github.com/UB-Mannheim/vMaBookShelf.
Please prepare your code contributions also on GitHub.


## Acknowledgments

This project uses other free software:

* Font Awesome by Dave Gandy – http://fontawesome.io/ (SIL OFL 1.1, MIT License)
* Java, OpenJDK – http://openjdk.java.net/ (GNU General Public License (GPL))
* YUICompressor – https://github.com/yui/yuicompressor/ (BSD (revised) open source license)
