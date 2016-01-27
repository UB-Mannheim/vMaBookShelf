//   Name: erzeuge-close-button.js
//  Stand: 2016-01-18, 12:00:36
// Author: Bernd Fallert, UB Mannheim

// ToDo: Timer des Hauptfensters ausschalten wenn unterfenster aufgerufen wird
//          und wieder einschalten wenn unterfenster aus irgendeinem Grunde
//          geschlossen wird

if (typeof vMaBookShelfHelper === "undefined") {
    console.log( "1---------->vMaBookShelfHelper setzen" );
    var vMaBookShelfHelper          = vMaBookShelfHelper || {};
    vMaBookShelfHelper.settings     = vMaBookShelfHelper.settings || {};
} else {
    console.log( "2---------->vMaBookShelfHelper schon definiert" );
    var vMaBookShelfHelper          = vMaBookShelfHelper || {};
    vMaBookShelfHelper.settings     = vMaBookShelfHelper.settings || {};
}

var d                           = document;
var host                        = d.location.host;

var cFileType                   = $( "#vMaBookShelfHelper_type" ).text();
var lInfoBlockVorhanden         = false;
if ( $( "#vMaBookShelfHelper" ).length > 0 ) {
    lInfoBlockVorhanden = true;

    console.log( "----> Aus Webseite ausgelesen: cFileType: " + cFileType );
}
//------------------------------------------------------------------------------
// Fuer Pruefung auf RufeExterneURL.php und UB3D
//------------------------------------------------------------------------------
var ScriptName                  = d.location.pathname;

var lZeigeButton                = false;
var lIframe                     = false;
var lFlag                       = false;
var TimerID                     = 0;

var lFehlersuche                = false;
//lFehlersuche                    = true;

var nMinutenExternFenster       = 10;
var nMinutenHauptFenster        = 30;
var nZeitSchalteHauptFensterUm  = 10000;

var lHauptFenster               = false;
var lUnterFenster               = false;

console.log( "START" );

if (lFehlersuche) {
    // Fuer Fehlersuche verkuerzte Wartezeiten bis Timer zuschlaegt
    nMinutenExternFenster       = 1;
    nMinutenHauptFenster        = 1;
    nZeitSchalteHauptFensterUm  = 5000;
}


//http://stackoverflow.com/questions/812961/javascript-getters-and-setters-for-dummies
var counter = function() {
    var count = 0;

    this.inc = function() {
        count++;
    };

    this.reset = function() {
        count = 0;
    };

    this.getCount = function() {
        return count;
    };
};


//------------------------------------------------------------------------------
// Mit verschiedenen Events
// - Mouseklick
// - keydown
// - mousemove
// - touchstart
// timer für umschalten auf andere Dokument zurückgesetzt
//------------------------------------------------------------------------------
document.addEventListener('mousedown', function(event) {
    nBooklistTimerIndex.reset();
}, false);
document.addEventListener('keydown', function(event) {
    nBooklistTimerIndex.reset();
}, false);
document.addEventListener('mousemove', function(event) {
    nBooklistTimerIndex.reset();
}, false);
document.addEventListener('touchstart', function(event) {
    nBooklistTimerIndex.reset();
}, false);
//------------------------------------------------------------------------------
// Ende Timer zurückgesetzt
//------------------------------------------------------------------------------



var nBooklistTimerIndex = new counter();


console.log("\n\n\n\n\n\n" + "#".repeat(80) + "\n" +
"ScriptName: '" + ScriptName + "'\n" +
" substr 10: '" + ScriptName.substr(0, 10) + "'");


if (lInfoBlockVorhanden) {

    console.log( "----------CHECK 1------------------" );
    console.log( "cFileType: " + cFileType );

    if (cFileType === 'html') {
        // normale html-Seiten des BookShelfs
        console.log( "normale html-Seiten des BookShelfs" );

        lZeigeButton    = false;
        lHauptFenster   = true;
        lUnterFenster   = false;
    } else {
        console.log( "seiten auf denen der Button angezeigt werden soll" );
        // seiten auf denen der Button angezeigt werden soll
        // hier ist cFileType nicht 'html'!
        lZeigeButton    = true;
        lHauptFenster   = false;
        lUnterFenster   = true;
    };

} else if (host === "localhost") {
    // Keine Aktion bei localhost
    console.log( "----------CHECK 2 else if localhost ------------------\n" );
//} else if ((host === "aleph.bib.uni-mannheim.de") &&
//    (ScriptName.substr(0, 9) != '/cgi-bin/' ) ||
//    (host === "onlinelesen.ciando.com")) {
} else if (host === "onlinelesen.ciando.com") {
    console.log( "----------CHECK 3 else if onlinelesen.ciando.com ---------------" );

    // In diesem Fall kann ich eine alternative Technik versuchen
    // die bei JumpHomeMa verwendet habe!
    // und zwar den Button nicht in einem IFrame sondern als halbtransparenter
    // Button links unten einblenden

    /*
    if ( ScriptName === '/booklist/RufeExterneURL.php') {
        lZeigeButton    = true;
        lHauptFenster   = false;
        lUnterFenster   = true;

    //-------------------------------------------------
    // prüfen ob in weiterem Kontext wie z.B.
    //-------------------------------------------------
    } else if (ScriptName.substr(0,9) === '/cgi-bin/') {
        // Sonst kann UB3D aus dem Frame ausbrechen
        lZeigeButton    = true;
        lHauptFenster   = false;
        lUnterFenster   = true;

    } else if (ScriptName.substr(0,10) === '/booklist/') {
        lZeigeButton    = false;
        lHauptFenster   = true;
        lUnterFenster   = false;
    }

    //-------------------------------------------------
    if (lZeigeButton) {
        console.log( "lZeigeButton wahr" );
    } else {
        console.log( "lZeigeButton falsch" );
    }
    if (lHauptFenster) {
        console.log( "Hauptfenster wahr" );
    } else {
        console.log( "Hauptfenster falsch" );
    }
    if (lUnterFenster) {
        console.log( "UnterFenster wahr" );
    } else {
        console.log( "UnterFenster falsch" );
    }
*/


} else {
    console.log( "----------CHECK 4 else ---------------" );

    //alert( "Kontext verlassen" + "\n" + window.location );
    var aktLocation = window.location;
    var isInIFrame  = false;
    lZeigeButton    = true;


    //---------------------------------
    // Pruefen ob im IFrame enthalten
    //---------------------------------
    var isInIFrame = (window.location != window.parent.location);
    //http://stackoverflow.com/questions/326069/how-to-identify-if-a-webpage-is-being-loaded-inside-an-iframe-or-directly-into-t
    //if (window.frameElement) {
    //    console.log( "----------in iFrame ---------------" );
    //    isInIFrame = true;
    //    isInIFrame = (window.location != window.parent.location);
    //} else {
    //    console.log( "----------NICHT in iFrame ---------------" );
    //    isInIFrame = false;
    //}

    if(isInIFrame == true){
        // iframe
        lZeigeButton    = false;
        lIframe         = true;
    } else {
        // no iframe
        // Script ist aus iframe ausgebrochen
        // nochmaliger Aufruf um es wieder einzufangen!
        lZeigeButton    = true;
        lIframe         = false;

        console.log( "kein IFrame: Kontext verlassen daher\n" +
            "rufe ich neu auf: " +
            "http://aleph.bib.uni-mannheim.de/booklist/" +
            "RufeExterneURL.php?url=" +
            aktLocation );
        //----------------------------------------------------------------------
        // Seite nochmals über das Script RufeExterneURL.php aufrufen,
        // damit Seite wieder in IFrame gefangen wird
        //----------------------------------------------------------------------
        //alert( "im IFrame" + "\n" + window.location );

        // an main.js Nachricht schicken, ich brauche die aktuelle Konfiguration für url
        self.port.emit("giveUrlBack", '');
        self.port.on("aktURL", function holeurl(cUrl) {
            vMaBookShelfHelper.settings.HomeUrl = cUrl;

            console.log( "A".repeat(50) + "\n" );
            console.log( "in aktURL cUrl: " + cUrl );
            console.log( "A".repeat(50) + "\n" );
            console.log( vMaBookShelfHelper.settings.HomeUrl + "/RufeExterneURL.php?url=" +
                                      aktLocation );

            // Setze location abhängig von Einstellungen neu
            document.location.replace( vMaBookShelfHelper.settings.HomeUrl + "/RufeExterneURL.php?url=" +
                                      aktLocation);

        });

        // Verlagert in self.port.on("aktURL"
        //document.location.replace("http://aleph.bib.uni-mannheim.de/" +
        //                          "booklist/RufeExterneURL.php?url=" +
        //                          aktLocation);
    }
}


console.log( "\n" + "--------------------------------------------\n" + "vor lZeigeButton: '" + lZeigeButton + "'\n--------------------------------------------\n" + "\n\n");
if (lZeigeButton) {
    var div = document.createElement("div");
    div.innerHTML = "<a href='javascript:window.close();' " +
                    "class='schliessbutton_neu_links'>" +
                    "<span id='oben' " +
                        "width='67px' " +
                        "style='width: 57px; '" +
                        "onclick='javascript:window.close();'" +
                        "ontouchstart='javascript:window.close();'" +
                        "ontouched='javascript:window.close();'" +
                        ">" +
                    "</span>" +
                    "<span id='mitte'" +
                        "onclick='javascript:window.close();'" +
                        "ontouchstart='javascript:window.close();'" +
                        "ontouched='javascript:window.close();'" +
                    ">" +
                        "Schließen<br>/<br>Close" +
                        "</span>" +
                    "<span id='unten' " +
                       "style='width: 57px; '" +
                        "onclick='javascript:window.close();'" +
                        "ontouchstart='javascript:window.close();'" +
                        "ontouched='javascript:window.close();'" +
                    "></span>" +
                    "</a>";
    div.style.color = "white";
    div.setAttribute("class", "UBMaSchliess");

    document.body.insertBefore(div, document.body.firstChild);
    console.log("Scriptname: " + ScriptName.substr(0,10));
    window.TimerID = window.setTimeout(function(){WelchesFensterIstAktiv();}, 10000);
} else {
    //--------------------------------------------------------------------------
    // Timer zum umschalten des Hauptfensters
    //--------------------------------------------------------------------------
    if (lHauptFenster) {
        // Clear Timeout, zur Sicherheit!
        //https://wiki.selfhtml.org/wiki/JavaScript/Objekte/window/setTimeout
        clearTimeout(window.TimerIDHauptFenster);

        window.TimerIDHauptFenster = window.setTimeout(function(){SchalteHauptFensterUm();},
            nZeitSchalteHauptFensterUm );
    }

    if (lFehlersuche) {
        // Jetzt testweise alle Elemente mit class fachnavi durchgehen
        console.log( "fehlersuche: alle Elemente mit class fachnavi auflisten");
        $( '.fachnavi' ).each(function(index) {
            console.log( "index: " + index + " " + $(this).data('id'));
        });
        console.log( "ENDE: fehlersuche: alle Elemente mit class fachnavi auflisten");
    };
}


function WelchesFensterIstAktiv () {
    //console.log("WelchesFensterIstAktiv");

    var d = document;
    var host = d.location.host;
    //--------------------------------------------------------------------------
    // Fuer Pruefung auf RufeExterneURL.php und UB3D
    //--------------------------------------------------------------------------
    var ScriptName = d.location.pathname;

    var lZeigeButton = false;
    var lIframe      = false;
    var lClose      = false;



    //#############################################
    //#############################################
    // Timer für Schliesen des Fensters mit Touch oder Click zurücksetzen

    console.log( "-----------------------------\n" + "Alter Timer window.TimerID: " + window.TimerID + "\n-----------------------------\n" );

    console.log( "-----------------------------\n" +
        "         Setze jetzt die Events (1)" );


    document.body.removeEventListener('click', BehandleClickUndTouch, false);
    document.body.removeEventListener('touchstart', BehandleClickUndTouch, false);


    //if (typeof( window.ClickId ) !== 'undefined' ) {
    //    document.body.detachEvent('click', window.ClickId);
    //    console.log( "detachEvent möglich, ClickId ist:" + window.ClickId);
    //} else {
    //    console.log( "detachEvent nicht möglich, ClickId ist nicht definiert!");
    //};
    //if (typeof( window.TouchId ) !== 'undefined' ) {
    //    document.body.detachEvent('touchstart', window.TouchId);
    //    console.log( "detachEvent möglich, TouchId ist:" + window.TouchId);
    //} else {
    //    console.log( "detachEvent nicht möglich, TouchId ist nicht definiert!");
    //};


    //BehandleClickUndTouch
    window.ClickId  = document.body.addEventListener('click',
        BehandleClickUndTouch, false);
    window.TouchId  = document.body.addEventListener('touchstart',
        BehandleClickUndTouch, false);

    //#############################################
    //#############################################


    if (nBooklistTimerIndex.getCount() < (6 * nMinutenExternFenster)) {
        //----------------------------------------------------------------------
        // Nr. hochzählen
        // solange kleiner als hier passiert ausser dem hochzählen nichts
        //----------------------------------------------------------------------
        nBooklistTimerIndex.inc();
        console.log(nBooklistTimerIndex.getCount());
        console.log("Scriptname (kurz): " + ScriptName.substr(0,10));
        console.log("Scriptname:(voll): " + ScriptName);
        console.log("window.TimerID: " + window.TimerID);

        self.port.emit("empfangeUnterfensterAktiv", true);

    } else if (nBooklistTimerIndex.getCount() < (1000 * nMinutenExternFenster)) {
        // wenn es groesser als das erste Zahl ist dann wird das overlay
        // angezeigt und ein zweiter Timer läuft an der nach 1 Minut
        // das Fenster beendet
        nBooklistTimerIndex.inc();
        console.log(nBooklistTimerIndex.getCount());

        // Overlay anzeigen mit der Frage ob noch jemand lebt
        overlay('display');

        console.log("2".repeat(10) + " Scriptname (kurz): " +
            ScriptName.substr(0,10));
        console.log("2".repeat(10) + " Scriptname:(voll): " + ScriptName);
        console.log("2".repeat(10) + " window.TimerID: " + window.TimerID);

    }

    if (!lClose) {
        console.log( "2-----------------------------\n" + "Alter Timer window.TimerID: " + window.TimerID + "\n2-----------------------------\n" );
        window.TimerID = window.setTimeout(WelchesFensterIstAktiv, 10000);
        console.log( "neuer Timer wurde gesetzt: " + window.TimerID);
    };
}

function overlay(mode) {
    if (mode == 'display') {
        if (document.getElementById("iframe-extern-wrapper") === null) {
            div = document.createElement("div");
            div.innerHTML = '<div id="lightBox"></div>';
            div.setAttribute('id', 'iframe-extern-wrapper');
            div.setAttribute('className', 'iframe-extern-wrapper-abgelaufen');
            div.setAttribute('class', 'iframe-extern-wrapper-abgelaufen');

            divTextBox = document.createElement("div");
            //divTextBox.innerHTML = '<h1>Möchten Sie noch weiterlesen?<br />Would you like to continue reading</h1><h2>Bitte den Bildschirm an einer beliebigen Stelle berühren<br />Please touch the screen at any point</h2>';
            divTextBox.innerHTML = '<h1>Möchten Sie noch weiterlesen?<br />' +
                'Would you like to continue reading</h1>' +
                '<h2>Bitte den Bildschirm an einer beliebigen Stelle ' +
                'berühren<br />Please touch the screen at any point</h2>';
            divTextBox.setAttribute('id', 'lightBox');

            document.getElementsByTagName("body")[0].appendChild(div);
            document.getElementsByTagName("body")[0].appendChild(divTextBox);


            //------------------------------------------------------------------
            // einen Timer einsetzen der das aktive Fenster schliesst und das
            // oberlay entfernt.
            // Wird die Frage eingeblendet ob noch jemand aktiv ist
            // läuft ein Timer von 1 Minute los der unterbrochen wird
            // wenn ein Klick stattfindet das abbrechen des Timers wird von
            // dem normalen Clickbehandlung unterbrochen es wird kein eigener
            // Handler hierfür eingerichtet
            //------------------------------------------------------------------
            // einen Timer einsetzen der das aktive Fenster schliesst und das
            // oberlay entfernt
            window.LiestNochJemandTimerID = window.setTimeout(liestNochJemand,
                10000 * 6);
        }
   } else {
        // diese Reihenfolge belassen
        // bei umgedrehter Reihenfolge? werden die Elemente nicht entfernt?
        document.getElementsByTagName("body")[0].removeChild(document.
         getElementById("iframe-extern-wrapper"));
        document.getElementsByTagName("body")[0].removeChild(document.
         getElementById("lightBox"));

    }
}

function liestNochJemand() {
    self.port.emit("empfangeUnterfensterAktiv", false);
    console.log("\n\n-----------------------------\n" +
        "wurde beendet durch liestNochJemand\n\n");
    window.close();
};


function BehandleClickUndTouch() {
    console.log("-----------------------------\n" +
        "Es wurde geklickt: " + nBooklistTimerIndex.getCount());
    // Zähler reseten, damit ist der Counter und damit der Timer zurückgesetzt
    nBooklistTimerIndex.reset();

    console.log("in BehandleClickUndTouch: " + nBooklistTimerIndex.getCount());

    // Overlay wieder entfernen wenn es vorhanden ist
    overlay('hide');

    // Timer für Lebt noch jemand abbrechen
    if (typeof( window.LiestNochJemandTimerID ) !== 'undefined') {
        clearTimeout(window.LiestNochJemandTimerID);
        console.log( "Stopp window.LiestNochJemandTimerID: " +
            window.LiestNochJemandTimerID);
    };

}


function BehandleClickUndTouchHauptFenster() {
    console.log("-----------------------------\n" +
        "Es wurde geklickt: " + nBooklistTimerIndex.getCount());
    // Zähler reseten, damit ist der Counter und damit der Timer zurückgesetzt
    nBooklistTimerIndex.reset();

    console.log("in BehandleClickUndTouchHauptFenster: " +
        nBooklistTimerIndex.getCount());
}




function SchalteHauptFensterUm () {

    console.log("function: SchalteHauptFensterUm");
    console.log("nZeitSchalteHauptFensterUm:" + nZeitSchalteHauptFensterUm);

    // Timer für Schliesen des Fensters mit Touch oder Click zurücksetzen

    console.log( "-----------------------------\n" +
        "                                  Setze jetzt die Events (2)" );


    console.log("\n" + "=".repeat(40) + "\n(1) vor istUnterfensterAktiv\n" + "=".repeat(40));
    self.port.on("istUnterfensterAktiv", function(tag) {
        console.log( "Alt: " + nBooklistTimerIndex.getCount());
        nBooklistTimerIndex.reset();
        console.log( "neu: " + nBooklistTimerIndex.getCount());
        if (tag) {
            console.log( "\n\n" + "?".repeat(32) +
                "\n\nUnterfenster ist NOCH aktiv (in SchalteHauptFensterUm)\n");
        console.log( "Alt: " + nBooklistTimerIndex.getCount());
        nBooklistTimerIndex.reset();
        console.log( "neu: " + nBooklistTimerIndex.getCount());
        } else {
            console.log( "\n\n" + "?".repeat(32) +
                "\n\nUnterfenster ist NICHT aktiv (in SchalteHauptFensterUm)\n");
        }
    });
    console.log("\n" + "=".repeat(40) + "\n(1) nach istUnterfensterAktiv\n" + "=".repeat(40));


    //BehandleClickUndTouch
    window.ClickIdHauptFenster  = document.body.
        addEventListener('click', BehandleClickUndTouchHauptFenster, false);
    window.TouchIdHauptFenster  = document.body.
        addEventListener('touchstart', BehandleClickUndTouchHauptFenster, false);

    //#############################################
    // Aktuellen Stand Counter ausgeben
    //#############################################
    console.log("\n\n\n" + "=".repeat(60) + "\nnBooklistTimerIndex.getCount(): '" + (nBooklistTimerIndex.getCount()+1) + "'\n" + "=".repeat(60) + "\n\n");

    if (nBooklistTimerIndex.getCount() < (6 * nMinutenHauptFenster)) {
        //----------------------------------------------------------------------
        // Nr. hochzählen
        // solange kleiner als hier passiert ausser dem hochzählen nichts
        //----------------------------------------------------------------------
        console.log("Wartezeit Hauptfenster " + (nBooklistTimerIndex.getCount()+1) + " von " + (6 * nMinutenHauptFenster));
        nBooklistTimerIndex.inc();
        //console.log(nBooklistTimerIndex.getCount());
        console.log("window.TimerIDHauptFenster: " + window.TimerIDHauptFenster);

        console.log("\n" + "=".repeat(40) + "\n(2) vor istUnterfensterAktiv\n" + "=".repeat(40));
        self.port.on("istUnterfensterAktiv", function(tag) {
            nBooklistTimerIndex.reset();
            console.log( "\n\n" + "?".repeat(20) +
                "\n\nUnterfenster ist noch aktiv (in SchalteHauptFensterUm)\n");
        });
        console.log("\n" + "=".repeat(40) + "\n(2) nach istUnterfensterAktiv\n" + "=".repeat(40));

    } else if (nBooklistTimerIndex.getCount() < (1000 * nMinutenHauptFenster)) {
        //----------------------------------------------------------------------
        // Wartezeit abgelaufen
        // Umschalten auf andere URL
        //----------------------------------------------------------------------
        console.log("Wartezeit Hauptfenster abgelaufen " + (nBooklistTimerIndex.getCount() + 1) + " von " + (6 * nMinutenHauptFenster) + "\n".repeat(2));
        nBooklistTimerIndex.inc();
        //console.log(nBooklistTimerIndex.getCount());

        // umschalten auf andere url
        WaehleZufaelligesFach();

        console.log("Scriptname (kurz): " +
            ScriptName.substr(0,10));
        console.log("Scriptname:(voll): " +
            ScriptName);
        console.log("window.TimerIDHauptFenster: " +
            window.TimerIDHauptFenster);

    }

    // Clear Timeout, zur Sicherheit!
    //https://wiki.selfhtml.org/wiki/JavaScript/Objekte/window/setTimeout
    clearTimeout(window.TimerIDHauptFenster);

    window.TimerIDHauptFenster = window.setTimeout(SchalteHauptFensterUm, 10000);
    console.log( "neuer TimerHauptFenster wurde gesetzt: " +
        window.TimerIDHauptFenster);

}


/**
 * Returns a random integer between min and max
 * Using Math.round() will give you a non-uniform distribution!
 */
function getRandomInt (min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

//----------------------------------------------------------------------
// Zufaelliges Fach aus der Liste aufrufen
//
// Die Liste wird ueber die Abfrage der Class "fachnavi" und dem
// "data-id"-Element abgefragt
// Aus dem daraus aufgebauten Array wird dann ein Element zufaellig
// ausgewaehlt
//----------------------------------------------------------------------
function WaehleZufaelligesFach() {
    var aHtmlFaecherListe = new Array();

    //--------------------------------------------------------------------------
    // Jetzt alle Elemente mit class fachnavi durchgehen
    // und id extrahieren zur Ermittlung der zufaelligen
    // Sprungadresse
    //--------------------------------------------------------------------------
    console.log("\nlese Elemente mit Class 'fachnavi' zur Ermittlung des nächsten zufälligen Fachs\n");
    $( '.fachnavi' ).each(function(index) {
        var nID = $(this).data('id');
        console.log( "index: '" + index + "' nID: '" + nID + "'");
        aHtmlFaecherListe.push(nID);
    });

    //--------------------------------------------------------------------------
    // Zufaellige Sprungadresse ermitteln
    //--------------------------------------------------------------------------
    var aktIndex = getRandomInt( 1, aHtmlFaecherListe.length );
    console.log("\n".repeat(2) + "=".repeat(30) + "\nWaehleZufaelligesFach\nElement=>aktIndex: " +
        (aktIndex - 1) + "\nFach: " + aHtmlFaecherListe[ aktIndex - 1 ] + "\nAnzahl Fächer (aHtmlFaecherListe.length): " + aHtmlFaecherListe.length);

    //--------------------------------------------------------------------------
    // Feststellen welche Version, d.h. Normal oder g dann Gestensteuerungs-PC
    //--------------------------------------------------------------------------
    var aktPath     = document.location.pathname;
    var nPathL      = aktPath.length;
    var cVersion    = aktPath.substr( nPathL - 6, 1 );
    var cOptGesten  = ""

    // Optionen fuer Gestenversion setzten
    if (cVersion === "g") {
        cOptGesten = "g";
    }

    var d                       = document;
    var host                    = d.location.host;
    var cScriptPath             = $( "#vMaBookShelfHelper_scriptpath" ).text();
    var cFileType               = $( "#vMaBookShelfHelper_type" ).text();
    var lInfoBlockVorhanden     = false;

    if ( $( "#vMaBookShelfHelper" ).length > 0 ) {
        lInfoBlockVorhanden = true;
    }
    console.log( "\n\n\n===================================\nhost: " + host + "\ncScriptPath: " + cScriptPath + "\n===================================\n" );


    // An die URL wird random angehaengt, damit koennen diese Aufrufe separat
    // gezaehlt werden
    document.location.replace("http://" + host +
                              cScriptPath +
                              aHtmlFaecherListe[ aktIndex - 1 ] +
                              cOptGesten + ".html?random");
}
