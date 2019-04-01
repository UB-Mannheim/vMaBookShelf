#!/bin/bash

#script ohne parameter starten
perl HoleCSV_von_alma.pl --resetlog

#script mit parameter für ebooks starten
perl HoleCSV_von_alma.pl --ebooks

#createFiles starten
perl CreateQRCodeFuerBuecherregal.pl
perl CreateGesamtBuecherregal.pl

cd html/js

if [ -f ErzeugeMiniVersion.sh ]
then
   source ErzeugeMiniVersion.sh
fi
