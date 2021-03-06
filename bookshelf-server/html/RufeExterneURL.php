<!doctype html>
<?php
    //--------------------------------------------------------------------------
    // Copyright (C) 2014 Universitätsbibliothek Mannheim
    // Name:
    //      RufeExterneURL.php
    // Author:
    //      Bernd Fallert <bernd.fallert@bib.uni-mannheim.de>
    // Projekt:
    //      booklist
    // Aufgabe:
    //      Aufruf einer externen URL, inkl. Primo aber in einem IFrame,
    //      damit links ein Close-Button dargestellt werden kann
    // Aufruf:
    //      http://aleph.bib.uni-mannheim.de/booklist/RufeExterneURL.php?url="HIER DIE AUFZURUFENDE URL EINTRAGEN"
    // Sicherheit:
    //      Das Script ueberprueft ob es einem zulässigen Kontext aufgerufen
    //      wird
    //--------------------------------------------------------------------------
    include 'RufeExterneURL.config.php';


    //------------------------------------------
    // Pruefen ob das Script aus einem zulaessigen
    // Bereich heraus aufgerufen wird
    // um missbrauch ausschliessen zu koennen
    //------------------------------------------
    $lTrust = false;

    $lTrust = CheckAllowed($_SERVER['HTTP_REFERER'],$_SERVER['REMOTE_ADDR']);

    $lTrust = true;
    //------------------------------------------
    // Wenn aus dem booklist-Kontext aufgerufen
    // oder Testzugang
    //------------------------------------------
    if ($lTrust) {
?>

<html>
<head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type">
    <link href="css/externeurls.min.css?Stand=<?php echo trim(date("Ymd_His", filemtime( dirname(__FILE__) . '/css/externeurls.min.css' ))) ?>" rel="stylesheet" type="text/css">
<script type="text/javascript">
function MaxScreen() {
    var difx, dify;
    var winx = screen.width;
    var winy = screen.height;
    window.moveTo( 0, 0 );
    window.resizeTo( winx, winy );
    // fuer Version mit Schliessen rechts
    document.getElementById("extern").width = winx-145;

    // Hoehe jetzt als Prozent, damit der Schatten des Schliessenbuttons
    // zu sehen ist
    document.getElementById("extern").height = '98%';
    return;
}
</script>
</head>

<body>
<?php

echo '<a class="schliessbutton_neu_links" href="javascript:window.close();">';
echo '</a>';


//------------------------------------------------------------------------------
// Fehler bei der URL-Uebergabe korrigieren,
//  externe URL wieder neu zusammensetzen
//------------------------------------------------------------------------------
$cURL = '';
foreach ($_GET as $key => $wert) {
    if ($key === 'url') {
        $cURL = htmlspecialchars($wert);
    } else {
        $cURL .= '&' . htmlspecialchars($key) . '=' . htmlspecialchars($wert);
    }
}

// Anker zum ueberdecken des iframes wg. prüfen auf click wg timer einbauen
//echo '<div id="iframe-extern-wrapper">';
//echo '<div id="lightbox">';
//echo 'Möchten Sie noch weiterlesen? Bitte den Bildschirm berühren!';
//echo '</div></div>';

// Iframe erzeugen
echo '<iframe   id="extern"
                name="extern"
                seamless
                width="1633px"
                height="822px"
                src="' . $cURL . '"
                allowtrancparency="yes"
                frameborder="o"
                ></iframe>';
?>
<script type="text/javascript">
// Auf maximale Bildschirmgroesse umschalten
MaxScreen();
</script>


<div id="vMaBookShelfHelper"  style="display:none;">
    <div id="vMaBookShelfHelper_scriptpath"><?php echo $vMaBookShelfHelper_scriptpath ?></div>
    <div id="vMaBookShelfHelper_type">php</div>
</div>

</body>
</html>
<?php
    //------------------------------------------
    // Ende von lTrust
    //------------------------------------------
} else {
    //-------------------------------------------
    // Im Fehlerfalle
    // Fehlerseite ausgeben, kurz und Knapp
    //-------------------------------------------
?>
<html>
<head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type">
</head>
<body>
    <h1>Unzulässiger Aufruf!</h1>
<?php
    //echo '<div>';
    //echo 'Ref: ' . $_SERVER['HTTP_REFERER'];
    //echo 'Host:' . $_SERVER['REMOTE_ADDR'];
    //echo '</div>';
?>
</body>
</html>
<?php
}
?>