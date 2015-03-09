ebook.readme.md
------------------------------

Infos about csv file for ebook medias.
The coding of the file has to be utf8 (without BOM).


Which file is used for the data of the printed medias is configured in config/booklist.ini in the section

    [CSV]
    ebook=XXXXX_ebook.csv

'ebook' need not be included in the filename, it's only more clearly.


Headline:
------------------------------
The first line is a heading line. Each record has the same structure.

Field seperator is "|". 

RecordID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Fach|Signatur|URL


Field description:
------------------------------

Field seperator is "|". 

RecordID
-------------
At the moment it's a fixed string! 
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


Fach
-------------
Subject of the book. At the moment only one number per record. It's possible that a book is more then one time in the csv file, but then the Fach field has to be different.


Signatur
-------------
shelf mark of the book. It's not the real shelf mark, because ebooks has no shelf mark, but it's the systematik point where the "virtual representation" should be.


URL
-------------
This field must be the last field. The reason is that in Aleph this field can contain a '|'. Normally in this situation this field would have to be enclosed with "", but Aleph didn't do this!


Sample File:
------------------------------
in csv/sample_ebooks.csv you will find a sample file for ebook medias.