## History
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
