# Install.md

## Server

### After download:

- Rename **bookshelf-server/config/booklist.ini_tmpl** to **bookshelf-server/config/booklist.ini**
  and adapt the configuration to your needs.
  See [bookshelf-server/config/README.md](bookshelf-server/config/README.md) for details.
- Rename **bookshelf-server/template/buecherregal_header.tmpl_sample** to
         **bookshelf-server/template/buecherregal_header.tmpl**
  and adapt the example to your normal webpage header.
- Rename **proxy-server/ds/config.php_tmpl** to
         **proxy-server/ds/config.php**
  and adapt the example to your needs.
- Rename **bookshelf-server/html/RufeExterneURL.config.php_tmpl** to
         **bookshelf-server/html/RufeExterneURL.config.php**
  and adapt the example to your needs.

- For QR codes a proxy-script is needed which redirects to Primo,
  you can use this script on another server or install it on the same server.
  You must configure the URL to the proxy script, which gets encoded in
  the QR code.
  In bookshelf-server/config/booklist.ini,
  [URL] section,
  specify variable "qr_base",
  see the example in this file.


### Node.js

Node.js is now used to generate and compress the css files. The js files are also compressed with it. Java and YUICompressor is no longer needed.


#### Downloading and installing Node.js and npm
    * https://docs.npmjs.com/downloading-and-installing-node-js-and-npm


##### Windows Node version managers
    * nvm-windows
        * https://github.com/coreybutler/nvm-windows


#### install environment

```bash
nvm install 14
nvm use 14.0.0
npm install -g yarn
yarn install
npm install -g grunt-cli

grunt
```



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
- LWP::Protocol::https
- GD
- GD::Barcode::QRcode
- Image::Resize
- Config::IniFiles
- Business::ISBN
- File::Basename
- Cwd
- JSON
- Text::CSV


##### is no longer needed
- CGI::Enurl (Possibly unnecessary)
- HTML::Hyphenate ()

#### Install Perl-Module as Debian Pckages

(List is just under construction)
libgd-barcode-perl      - Perl module to create barcode images
libtext-csv-perl        - comma-separated values manipulator (using XS or PurePerl)
libbusiness-isbn-perl   - Perl library to work with International Standard Book Numbers
libjson-perl            - module for manipulating JSON-formatted data

```bash
apt-get install libgd-barcode-perl libtext-csv-perl libbusiness-isbn-perl libjson-perl
```

#### Install Perl-Module with CPAN
```bash
perl -MCPAN -e shell
install <name>
```
or
```bash
perl -MCPAN -e "install <name>"
```
#### Install Perl-Module manually
- Download perl module
- extract the module in temporary directory
- change to the temporary directory
- perl Makefile.PL
- make
- make test
- make install

This procedure is described in the modules README.txt. There may be special hints for each module.

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
Das wird jetzt durch Grunt erledigt

```bash
grunt
```


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




## Client where you like to test the Website

#### Download Node.js
- https://nodejs.org/en/

#### Install Node.js
execute the downloaded version of nodeXXXXXX.msi

#### jpm
The jpm tool is a Node-based replacement for cfx.
It enables you to test, run, and package add-ons.

#### Install Node.js
After you have npm installed and node on your PATH, install jpm just as you would
any other npm package.

### Installing jpm globally
Depending on your setup, you might need to run this as an administrator!

- open a "node.js command prompt" as Administrator
- npm install jpm --global

### Documentation for jqm
- https://developer.mozilla.org/en-US/Add-ons/SDK/Tools/jpm


#### Firefox Add-On "vMaBookShelfHelper"

 - in Firefox-Add-on\vMaBookShelfHelper\data\js\erzeuge-close-button.js
   you have to change some strings:
   host: aleph.bib.uni-mannheim.de
   scriptname: /booklist/RufeExterneURL.php
   scriptpath: /booklist/
   cgi-script-path: /cgi-bin/

   i working on that problem to make the Add-on more flexibel, with a config dialog,
   or something like that.

   if you have changed these strings you have to recreate the xpi file

   - open a "node.js command prompt"
   - change the directory to the "Firefox-Add-on\vMaBookShelfHelper"-directory
   - ~~jpm run~~ (Launch an instance of Firefox with the add-on installed)
     - :warning: **IMPORTANT**: *jpm run does not work with the release version of Firefox 48, or later.
       You need to install and use a different version of Firefox*
     - The simplest thing to do is to download Firefox Nightly: https://nightly.mozilla.org/ and start jpm using:
       - > jpm run -b nightly   *(Launch an instance of Firefox with the add-on installed)*
   - jpm xpi (Package the add-on as an XPI file, which is the install file format for Firefox add-ons.)



## Client where you like to show the Website

### Firefox

#### Fullscreen mode:

- Enable Firefox Fullscreen mode:
  Open in Firefox
    about:config

  search:
    browser.link.open_newwindow.disabled_in_fullscreen

  change value to 'true' (you can click on the value to change)


#### Firefox Add-On "vMaBookShelfHelper"

 - install the Firefox Add-On "vMaBookShelfHelper"
   from "Firefox-Add-on/vMaBookShelfHelper/vMaBookShelfHelper@bib.uni-mannheim.de-X.X.X.xpi"
