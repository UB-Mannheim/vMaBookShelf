<?php
    //--------------------------------------------------------------------------
    // Copyright (C) 2014 Universitätsbibliothek Mannheim
    // Name:
    //      deepsearch.php
    // Author:
    //      Bernd Fallert <bernd.fallert@bib.uni-mannheim.de>
    // Projekt:
    //      booklist
    // Aufgabe:
    //      Weiterleiten von Anfragen via QR-Code an 'ds'
    //      an die aktuelle Version von Primo
    // Aufruf:
    //      http://link.bib.uni-mannheim.de/ds/
    // Sicherheit:
    //
    //   Anpassen in config.php:
    //      - ggf. sollte der Pfad innerhalb der Variablen
    //          "$myFilePath" angepasst werden.
    //          In Mannheim ist dies "/var/www/ds/"
    //          In diesem Verzeichnis werden die Statistik-CSV-Dateien
    //          gespeichert
    //      - In der Variable "$url" muss der Pfad zu Primo und die Werte der
    //          Parameter:
    //              - institution
    //              - vid
    //              - search_scope
    //          angepasst werden
    //--------------------------------------------------------------------------
    include 'config.php';

    //--------------------------------------------------------------------------
    // Extrahiere recordid
    // Aufbau in Mannheim: MAN_ALEPH + '001494969'
    //--------------------------------------------------------------------------
    $recordid = ( ! empty( $_GET[ 'recordid' ] ) ) ? $_GET[ 'recordid' ] : false;

    // Prüfen / sicherstellen das $recordid nur Zahlen enthält
    if (ctype_digit($recordid)) {

    // Nur mit recordid zulaessig
    if (($recordid != false) and ctype_digit($recordid)) {

        //----------------------------------------------------------------------
        // Bilden der URL
        //----------------------------------------------------------------------
        $url = $urlbase . $recordid;

        //----------------------------------------------------------------------
        // Umschalten auf die URL
        //----------------------------------------------------------------------
        header("location: " . $url . "\n\n");

        //----------------------------------------------------------------------
        // Statistik
        //----------------------------------------------------------------------
        $timestamp       = time();
        $zugriffsdate    = getdate ( $timestamp );
        $monat           = $zugriffsdate[mon];

        if ($monat < 10) {
            $monat = "0" . $monat;
        }
        $tag             = $zugriffsdate[mday];
        if ($tag < 10) {
            $tag = "0" . $tag;
        }

        $seconds         = $zugriffsdate[seconds];
        if ($seconds < 10) {
            $seconds = "0" . $seconds;
        }

        $minutes         = $zugriffsdate[minutes];
        if ($minutes < 10) {
            $minutes = "0" . $minutes;
        }

        $hours           = $zugriffsdate[hours];
        if ($hours < 10) {
            $hours = "0" . $hours;
        }


        $zugriffsdate_klar = $zugriffsdate[year] .
                                $monat .
                                $tag .
                                "_" .
                                $hours .
                                $minutes .
                                $seconds ;
        //----------------------------------------------------------------------
        // CSV-Dateiname bilden
        //----------------------------------------------------------------------
        $myFile             = $myFilePath .
                                "qr_statistik_" .
                                $zugriffsdate[year] .
                                "_" .
                                $monat .
                                ".csv";
        //----------------------------------------------------------------------
        // CSV-Datenzeile bilden
        //----------------------------------------------------------------------
        $stringData        = $timestamp .
                                "\t" .
                                $zugriffsdate_klar .
                                "\t" .
                                $recordid .
                                "\n";
        //----------------------------------------------------------------------
        // Statistik-CSV-Datei oeffnen
        //----------------------------------------------------------------------
        $fh                = fopen($myFile, 'a') or die("can't open file");

        //----------------------------------------------------------------------
        // Daten speichern und Datei wieder schliessen
        //----------------------------------------------------------------------
        fwrite($fh, $stringData);
        fclose($fh);
    }
    else
    {
        //----------------------------------------------------------------------
        // Fehlermeldung wenn keine RecordID übergeben wurde
        //----------------------------------------------------------------------
        echo "<h1>Bitte eine g&uuml;ltige Recordid angeben</h1>";
        echo "<h1>Please enter a valid RECORDID</h1>";
    }
?>