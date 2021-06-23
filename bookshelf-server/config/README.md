# README.md

copy booklist.ini_tmpl to your local file booklist.ini.


## config/booklist.ini_tmpl

### [PATH]
#### csv=csv
- csv files with book data
- relative path

#### qr_cache=/usr/local/bin/vMaBookShelf/bookshelf-server/html/QRCache/
- path for QR-Code files, the script will generate the QR-Code files
- in these path. The path should be accessible via web browser
- absolute path

or Windows:

#### qr_cache=D:\Data\listing\Perl\Primo\VirtuellesBuchregal\virtual_bookshelf\html\QRCache\


#### html_path=html/
- html-path
- absolut or relative path
- path to the directory where the script have to create the html files
- create from this path a symbolic link to /var/www/**YourProjectName**



#### ~~html_web_path=/booklist/~~               (:label: ***deprecated***)
- better use
- section '[URL]' variable 'html_web_path' +


### [CSV]
#### print=sample_print.csv
- file names without path
- print => file with the book data for printed books
- details see csv/print.readme.md


#### ebook=sample_ebooks.csv
- file names without path
- ebook => file with the book data for ebooks books
- details see csv/ebook.readme.md



### [URL]
#### qr_base=http://link.bib.uni-mannheim.de/ds/
- This URL points to a script that forwards to Primo
- This workaround is necessary because the number of characters must be encoded in the QR code, it is in this way much lower.
- This URL will be complemented by 'MAN_ALEPH001494969'. see [ALEPH_ID] vorspann


#### protocol=http
- Used protocol.
- Optional: default = http.
- Possible values are http | https
- ': //' is added by the script


#### host=aleph.bib.uni-mannheim.de
- hostname full, (servername with html files and RufeExterneURL.php)
- without "http://" !!!


#### html_web_path=/booklist/
- this is the directory that you specified as the target of the symbolic link of the 'html' subdirectory
- if Apache DocumentRoot is /var/www
- and your linked your html subdirecory to /var/www/booklist
- then you should write here only /booklist/
- This is a web path, not a unix path.
- ------------------------------------------------------------------------
- The script adds at the beginning of these variables the following:
- ------------------------------------------------------------------------
- section '[URL]' variable 'protocol' + '://' +
- section '[URL]' variable 'host' +
- section '[URL]' variable 'html_web_path' +
- section '[URL]' variable 'openExterneURL_base'
- ------------------------------------------------------------------------
- if the files are in the webroot you should write
- html_web_path=/
- moved from section '[PATH]' to '[URL]' at 18.12.2018


#### openExterneURL_base=RufeExterneURL.php?url=
- --------------------------------------------------------------------------------
- The script adds at the beginning of these variables the following:
- section '[URL]' variable 'protocol' + '://' +
- section '[URL]' variable 'host' +
- section '[URL]' variable 'html_web_path' +
- section '[URL]' variable 'openExterneURL_base'
- --------------------------------------------------------------------------------
- script result: http://aleph.bib.uni-mannheim.de/booklist/RufeExterneURL.php?url=
- --------------------------------------------------------------------------------


#### printMedien_base=http://primo.bib.uni-mannheim.de/primo_library/libweb/action/dlSearch.do?institution=MAN&vid=MAN_UB&search_scope=MAN_ALEPH&query=any,exact,
- Local Opac, in Mannheim Primo
- at the end of this url the script will add the opac id, in Mannheim the aleph id




### [ALEPH_ID]
#### vorspann=MAN_ALEPH
- Every ID in the local opac beginn with ...
- in Primo you can identify this string if you search for 'doc' within the link of 'Details'

- Kann ermittelt werden aus dem Link auf dem Reiter 'Details' und
- innerhalb dessen der Parameter 'doc'
- http://primo.bib.uni-mannheim.de/primo_library/libweb/action/display.do?ct=display&fn=search&doc=MAN_ALEPH001045794&indx=10&recIds=MAN_ALEPH001045794&recIdxs=9&elementId=0&renderMode=poppedOut&displayMode=full&fctN=facet_rtype&dscnt=1&rfnGrp=1&frbrVersion=2&fctV=books&scp.scps=scope%3A%28MAN_CIANDO%29%2Cscope%3A%28MAN_CUP%29%2Cscope%3A%28MAN_EBR%29%2Cscope%3A%28MAN_ALEPH%29%2Cscope%3A%28MAN%29%2Cscope%3A%28MAN_EB_TEST%29&tab=default_tab&dstmp=1401707388057&srt=rank&mode=Basic&gathStatTab=true&tb=t&fromLogin=true&rfnGrpCounter=1&vl(freeText0)=irland&vid=MAN_UB&vl(63144028UI0)=any&frbg=&vl(37987049UI1)=all_items&dum=true&http://primo.bib.uni-mannheim.de:80/primo_library/libweb/action/expand.do?dscnt=0&vl(1UIStartWith0)=contains&tabs=detailsTab&gathStatTab=true



### [INDEX]
#### html=index.html
- file name of the index file.


#### html_gestensteuerung=index_g.html
- if you like to use a version for gesture control you can choose here a second index file



### [STORE]
#### kein_treffer_cache_file=DatenCache/keinTreffer.dat
- cache file if you didn't find a cover for this book
- if a id is in this file the script will skip thes id if it has to check amazon
- relative path with file name and perhaps extension



### [REGAL]
#### regal_reihen=4
- shelf rows
- attention: at the moment only 4 rows!!!!


### [NAVIGATION]
- list of Subjects
- in the direction in which they should be displayed in the html files
- key is value in the csv file
- value is text for the link in the html file
- in print-csv-file: Fach
- in ebook-csv-file: Fach
#### 27=Allg. u. vergl. Sprach- und Literaturwissenschaft
#### 01=Allgemeines
#### 28=Anglistik
#### 35=Geographie, Wirtschaftsgeographie
#### 15=Geowissenschaften
#### 29=Germanistik, Niederlandistik, Skandinavistik
#### 34=Geschichte
#### 12=Informatik
#### 31=Klassische Philologie
#### 24=Kunstwissenschaften
#### 11=Mathematik
#### 17=Medizin
#### 25=Medien- und Kommunikationswissenschaften
#### 10=Naturwissenschaften
#### 05=P&auml;dagogik
#### 02=Philosophie
#### 07=Politikwissenschaft
#### 03=Psychologie
#### 09=Rechtswissenschaften
#### 30=Romanistik
#### 32=Slawistik
#### 33=Sonstige Sprachen
#### 06=Soziologie, Statistik
#### 26=Sportwissenschaft
#### 18=Technik
#### 04=Theologie
#### 23=Umweltschutz, Landschaftsgestaltung
#### 08=Wirtschaftswissenschaften



### ~~[CSS]~~               (:label: ***deprecated***)

```
The CSS files are now generated with LESS.
Therefore the file template/booklist.css.tmpl is also no longer needed
```
> All Variables are transformed to `..\app\less\local.less`

#### ~~menu_active__background_color=#ffffff~~
- Menu active background color

#### ~~menu_active__color=#000000~~
- Menu active text color

#### ~~menu__background_color=#990000~~
- Menu normal background color

#### ~~menu__color=#ffffff~~
- Menu normal text color

#### ~~menu__border_right__color=#ffffff~~
- Menu, color of the right border, used as separator between menu and bookshelf, default is #ffffff




#### ~~header__background_color=#990000~~
- Header background color


#### ~~regalnummer__background_color=#585858~~
- shelf number, background color



#### ~~regalnummer__color=#ffffff~~
- shelf number, text and border color


#### ~~buchsignatur__color=#ffffff~~
- shelf mark text color


#### ~~id_collapse_menu__border_left_color=#CABB94~~
- color of the left border, used as separator between menu and fold in icon / fold out icon


#### ~~regal_grafik_anfang__background=../images/bookshelf-bg-dunkler-geteilt-links-001.png~~
- shelf grafik left (used as background)

#### ~~regal_grafik_abschluss__background=../images/bookshelf-bg-dunkler-geteilt-rechts-001.png~~
- shelf grafik right (used as background)

#### ~~regal_grafik_mitte__background=../images/bookshelf-bg-dunkler-geteilt-mitte-001.png~~
- shelf grafik behinde each book (used as background)



#### ~~ohne_cover_shelf_image_title__font_size=12~~
- if the script didn't find a cover (at amazon), the script will used a default image
- (only color and color gradient). On top of this image the script will insert some informations
- about the book.
- the script will used random color, so each book looks a little be differnet
- if the script will find a printed book and a ebook with the same title, ed. and year it will use
- the same color for both books
- only books without a cover from amazon get this captions!

- the next tree variables are for the size of the information about the book
- all sizes are in px

- used this font size (px) for the book title


#### ~~ohne_cover_shelf_image_subtitle__font_size=9~~
- used this font size (px) for the book subtitle


#### ~~ohne_cover_shelf_image_authors__font_size=12~~
- used this font size (px) for the authors


#### ~~ohne_cover_shelf_image_substitute__color=#ffffff~~
- Text color of title, subtitle and authors for books without amazon cover




#### ~~header_hoehe=95~~
- height of header in px


#### GesamtRegalHoehe=980
- Absolut Hight of the shelf in px
- you find this value not direct in the css-file
- value used to calculate other values


#### ~~QRBreite=82~~
- width ob a QR image in px
- we start with small qr codes, but then we realised not every smartphone can read this qr codes
- so its a good idee to test the qr codes with different devices


#### MediumGesamtBreite=241
- Value correlated with the width of a QR image
- absolute width of a book
- if QRBreite is 82px


### [GESTENSTEUERUNG]
- this section is used for a second version of the html-files
- if you will use gesture control


#### erzeuge=no
- Create a second version of the html files with gesture control
- yes or no
- Options
- turned on: ja / yes / j / y
- turned off: nein / no / n


#### tastendruckmultiplikator=15
- the gesture control software will send only one key if you wipe to left or right
- with this parameter you can repeat X times this key

### [ALMA]

#### collection=99999999999999999
- you can create in ALMA a Collection, use here the Collection-Key


#### ebooks-collection=99999999999999999
- Ebooks
- for EBooks you can create in ALMA a second Collection, use here the Collection-Key


#### apiKey=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- you can create in ALMA a search api.
- with the indiducal apiKey you get the data as xml

#### skipSubtitles=yes
- in Alma subtitles a part of the title field


#### SkipStartWith=:
- pattern to separate title from subtitle

### [SET]
- used for HoleCSV_von_alma.pl

#### locationId=WEST_EG
- locationId in Alma
- 'WEST_EG' or '120' are used values in Mannheim

#### siganfang=120
- in Mannheim we used RVK call numbers
- the first 3 numbers are shown the location
- '120' is a used values in Mannheim
- a possible call number is: 120 AH 11005 E36
