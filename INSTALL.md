# Install.md

## Server

### After download:

- Rename bookshelf-server/config/booklist.ini_tmpl to bookshelf-server/config/booklist.ini
  and adapt the configuration to your needs. See bookshelf-server/config/readme.md for details.
- Rename bookshelf-server/template/buecherregal_header.tmpl_sample to
         bookshelf-server/template/buecherregal_header.tmpl
  and adapt the example to your normal webpage header
- Rename proxy-server/ds/config.php_tmpl to
         proxy-server/ds/config.php
  and adapt the example to your needs
- Rename bookshelf-server/RufeExterneURL.config.php_tmpl to
         bookshelf-server/RufeExterneURL.config.php
  and adapt the example to your needs

- for QR codes is a proxy-script needed which redirects to primo,
  you can use this script on another server or install on the same server.
  You must configure the URL to the proxy script, which is encoded in
  the QR code.
  In bookshelf-server/config/booklist.ini,
  [URL] section,
  specify variable qr_base,
  see the example in this file.

### Java

a local Version of java is needed to minimize the js and css files.
See
  * bookshelf-server/html/js/ErzeugeMiniVersion.sh_sample (for Linux)
  * bookshelf-server/html/js/ErzeugeMiniVersion.cmd_sample (for Windows)

there you have to insert the path into the variable "javaprog"

apt-get install openjdk-7-jdk


### YUICompressor
need for minimizing js and css files.
see
  * bookshelf-server/html/js/ErzeugeMiniVersion.sh_sample (for Linux)
  * bookshelf-server/html/js/ErzeugeMiniVersion.cmd_sample (for Windows)

there you have to insert the path into the variable "yuicomp"

#### Download YUICompressor

https://github.com/yui/yuicompressor/releases
and download the actual jar file.


rename
  * bookshelf-server/html/js/ErzeugeMiniVersionen.sh_sample to
  * bookshelf-server/html/js/ErzeugeMiniVersionen.sh

or

rename
  * bookshelf-server/html/js/ErzeugeMiniVersionen.cmd_sample to
  * bookshelf-server/html/js/ErzeugeMiniVersionen.sh

and adapt the example to your needs
here you put the path and name of the jar file to the variable "yuicomp"




### Perl

For lokal tests in Windows i use http://strawberryperl.com/

The scripts used the folowing perl modules. You can download them from cpan.

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


### Create minimized versions of js and css files
with
cd bookshelf-server/html/js/
- ./ErzeugeMiniVersion.sh   (for Linux)
- ErzeugeMiniVersion.cmd    (for Windows)



### RufeExterneURL.php

At the moment, there is a block in the script

    //------------------------------------------
    // Pruefen ob das Script aus einem zulaessigen
    // Bereich heraus aufgerufen wird
    // um missbrauch ausschliessen zu koennen
    //------------------------------------------
    $lTrust = false;
    if (substr($_SERVER['HTTP_REFERER'],0,42) ===
        'http://aleph.bib.uni-mannheim.de/booklist/') {
        $lTrust = true;
    } else if ($_SERVER['REMOTE_ADDR'] === '134.155.36.67') {
        // Testzugang
        $lTrust = true;
    } else if (substr($_SERVER['REMOTE_ADDR'],0,11) === '134.155.36.') {
        // Testzugang
        $lTrust = true;
    } else if ($_SERVER['REMOTE_ADDR'] === '134.155.62.209') {
        // Testzugang
        $lTrust = true;
    } else if ($_SERVER['REMOTE_ADDR'] === '134.155.62.217') {
        // Testzugang
        $lTrust = true;
    } else if ($_SERVER['REMOTE_ADDR'] === '134.155.62.219') {
        // Testzugang
        $lTrust = true;
    }

here you have to change the adresses to your needs.

I will work on a simple configuration for that problem.




## Client where you like two show the Webside

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

 - install the Firefox Add-On "vMaBookShelfHelper" from "Firefox-Add-on/vMaBookShelfHelper/vmabookshelfhelper.xpi"


### Link html path to /var/www/<YourProjectName>
create from /usr/local/bin/vMaBookShelf/bookshelf-server/html a symbolic link to /var/www/<YourProjectName>

### Link proxy-server/ds/ path to /var/www/ds
create from /usr/local/bin/vMaBookShelf/proxy-server/ds a symbolic link to /var/www/ds, or copy the script to a diffrent server
