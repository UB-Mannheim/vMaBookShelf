print.readme.md
------------------------------

Infos about csv file for printed medias.
The coding of the file has to be utf8 (without BOM).


Which file is used for the data of the printed medias is configured in config/booklist.ini in the section

    [CSV]
    print=XXXXX_print.csv

'print' need not be included in the filename, it's only more clearly.


Headline:
------------------------------
The first line is a heading line. Each record has the same structure.

Field seperator is "|".

Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Signatur|Fach


Field description:
------------------------------

Field seperator is "|".

Aleph-ID
-------------
In Mannheim we used Aleph, so i used this string for heading. At the moment it's a fixed string!
Printed medias has in the first row 'Aleph-ID'.
Ebooks has in the first row 'RecordID'.
The script use this two markers to know with which version of file it runs.


Autor
-------------
Name of the Author


Titel
-------------
Title of the book


Aufl.
-------------
edition of the book


Jahr
-------------
Year


ISBN
-------------
isbn


SPRACHE
-------------
Language


Signatur
-------------
shelf mark of the book


Fach
-------------
Subject of the book. At the moment only one number per record. It's possible that a book is more then one time in the csv file, but then the Fach field has to be different.



Sample File:
------------------------------
In csv/sample_print.csv you will find a sample file for printed medias.

If only ebooks are desired in the Virtual Bookshelf, only the headline should be included in this file
In csv/sample_print_if_only_ebooks.csv you will find a sample file for this case.