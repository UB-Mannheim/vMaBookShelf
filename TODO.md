# TODO

## Firefox Add-on vMaBookShelfHelper

At the moment everythin is for Mannheim. I have to flexibel the urls
in Firefox-Add-on\vMaBookShelfHelper\data\js\erzeuge-close-button.js


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

here you have to I have to flexibel this

