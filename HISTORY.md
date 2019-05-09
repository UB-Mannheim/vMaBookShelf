## History
- 2019.05.09
    - add to install.md:
      - info about use of LWP::Protocol::https (Thanks to Thiemontz, Marcel <marcel.thiemontz@uni-due.de>)

- 2019.04.09 (0.9.15)
  - Error Corrected
    - remove not correct working KeineTrefferCache. Now more covers are found.
    - remove some error messages
      - no errormessage if fach is empty
  - ToDo
    - handling the error message in errorlog when sorting titles without a signature (or RVK Signature) in eboob.csv.

- 2019.04.04
  - Error Corrected
    - insert again Perl-Modul: File::Basename and Cwd (Thanks to Thiemontz, Marcel <marcel.thiemontz@uni-due.de>)
  - Check if isbn is ok, if not convert to empty isbn
  - Better messages in log if error in record

- 2019.04.01 (0.9.14)
  - if cover was not found on Open Library or Amazon further search on Google and Syndetics (Thanks to Thiemontz, Marcel)
  - add Perl-Modul: JSON
    - necessary for api for bookcover from Google
  - Error
    - set tag 0.9.13 to older version

- 2018.12.18
  - add Perl-Modul: File::Basename and Cwd
    - necessary to check if the file /template/buecherregal_header.tmpl exists and produces better error message if it does not exist
  - correct an error if html_web_path is only '/'

- 2016.04.23
  - two new parameters in bookshelf-server/config/booklist.ini_tmpl to skip subtitle, they are in alma a part of title field
  - HoleCSV_von_alma.pl gets now the last two missing parameter jahr and sprache

- 2016.04.22
  - Change one parameter in bookshelf-server/config/booklist.ini_tmpl ''[PATH] cvs='' now ''[PATH] csv=''
  - new version 0.9.4 of Firefox Add-on, fixed a problem with "primo.bib.uni-mannheim.de" and "onlinelesen.ciando.com". A smaler overlay button will shown if the wrap in a iFrame not work.
