# Install.md

## Server

### After download:

- Rename **bookshelf-server/config/booklist.ini_tmpl** to **bookshelf-server/config/booklist.ini**
  and adapt the configuration to your needs.
  See [bookshelf-server/config/README](bookshelf-server/config/README) for details.
- Rename **bookshelf-server/template/buecherregal_header.tmpl_sample** to
         **bookshelf-server/template/buecherregal_header.tmpl**
  and adapt the example to your normal webpage header.
- Rename **proxy-server/ds/config.php_tmpl** to
         **proxy-server/ds/config.php**
  and adapt the example to your needs.
- Rename **bookshelf-server/RufeExterneURL.config.php_tmpl** to
         **bookshelf-server/RufeExterneURL.config.php**
  and adapt the example to your needs.

- For QR codes a proxy-script is needed which redirects to Primo,
  you can use this script on another server or install it on the same server.
  You must configure the URL to the proxy script, which gets encoded in
  the QR code.
  In bookshelf-server/config/booklist.ini,
  [URL] section,
  specify variable "qr_base",
  see the example in this file.


### Java

A local version of Java is needed to minimize the js and css files.
See
  * [bookshelf-server/html/js/ErzeugeMiniVersion.sh_sample](bookshelf-server/html/js/ErzeugeMiniVersion.sh_sample) (for Linux)
  * [bookshelf-server/html/js/ErzeugeMiniVersion.cmd_sample](bookshelf-server/html/js/ErzeugeMiniVersion.cmd_sample) (for Windows)

There you have to insert the path into the variable "javaprog".

apt-get install openjdk-7-jdk


### YUICompressor
It is needed for minimizing js and css files.
See
  * bookshelf-server/html/js/ErzeugeMiniVersion.sh_sample (for Linux)
  * bookshelf-server/html/js/ErzeugeMiniVersion.cmd_sample (for Windows)

There you have to insert the path into the variable "yuicomp".

#### Download YUICompressor

https://github.com/yui/yuicompressor/releases
and download the actual jar file.

#### Install YUICompressor

See https://github.com/yui/yuicompressor/blob/master/README.md

#### Rename Scripts to use YUICompressor
Rename and adapt the example to your needs
in this file you put the path and name of the jar file to the variable "yuicomp"


##### Linux
Rename
  * bookshelf-server/html/js/ErzeugeMiniVersionen.sh_sample to
  * bookshelf-server/html/js/ErzeugeMiniVersionen.sh

make the file executable
  * chmod u+x bookshelf-server/html/js/ErzeugeMiniVersionen.sh

##### Windows
Rename
  * bookshelf-server/html/js/ErzeugeMiniVersionen.cmd_sample to
  * bookshelf-server/html/js/ErzeugeMiniVersionen.cmd


### Perl

For local tests in Windows I use http://strawberryperl.com/

The scripts used the following perl modules. You can download them from cpan.

- CGI
- CGI::Carp
- Encode
- Unicode::Normalize
- Getopt::Long
- Template
- Template::Filters
- Template::Filters->use_html_entities
- LWP::UserAgent
- GD
- Image::Resize
- HTML::Hyphenate
- Config::IniFiles
- Business::ISBN


### Create HTML-File, Download Covers ...
Now you can create the html files, with
cd bookshelf-server
- ./createFiles.sh (for Linux)
- createFiles.cmd  (for Windows)

#### Log-Files / Error-Log-Files
Infos from the perlscripts CreateQRCodeFuerBuecherregal.pl and
CreateGesamtBuecherregal.pl are stored in

- CreateQRCodeFuerBuecherregal.pl stored in
  - CreateQRCodeFuerBuecherregal.pl.log (Normal Infos and Errors)
- CreateGesamtBuecherregal.pl stored in
  - CreateGesamtBuecherregal.pl.log (Normal Infos and Errors)
  - CreateGesamtBuecherregal.pl.csv_error.log (Errors in csv-file)


### Create minimized versions of js and css files
For Linux, this step is now integrated in the
bookshelf-server/createFiles.sh (see above).

#### Manuel
with
cd bookshelf-server/html/js/
- ./ErzeugeMiniVersion.sh   (for Linux)
- ErzeugeMiniVersion.cmd    (for Windows)

### RufeExterneURL.config.php
Copy **RufeExterneURL.config.php_tmpl** to **RufeExterneURL.config.php**
and adapt the example to your needs.

### Link html path to /var/www/**YourProjectName**
create a symbolic link
  * from: /usr/local/bin/vMaBookShelf/bookshelf-server/html
  * to:   /var/www/**YourProjectName**

### Link proxy-server/ds/ path to /var/www/ds
create a symbolic link
  * from: /usr/local/bin/vMaBookShelf/proxy-server/ds
  * to:   /var/www/ds, or copy the script to a different server


## Client where you like two show the Website

### Firefox

#### Fullscreen mode:

- Enable Firefox Fullscreen mode:
  Open in Firefox
    about:config

  search:
    browser.link.open_newwindow.disabled_in_fullscreen

  change value to 'true' (you can click on the value to change)


#### Firefox Add-On "vMaBookShelfHelper"

 - in Firefox-Add-on\vMaBookShelfHelper\data\js\erzeuge-close-button.js you have to change some strings
   host: aleph.bib.uni-mannheim.de
   scriptname: /booklist/RufeExterneURL.php
   scriptpath: /booklist/
   cgi-script-path: /cgi-bin/

   if you have changed these strings you have to recreate the xpi file

   i working on that problem to make the Add-on more flexibel, with a config dialog, or something like that.

 - install the Firefox Add-On "vMaBookShelfHelper"
   from "Firefox-Add-on/vMaBookShelfHelper/vmabookshelfhelper.xpi"
