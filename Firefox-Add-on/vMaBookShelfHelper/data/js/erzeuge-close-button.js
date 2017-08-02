//   Name: erzeuge-close-button.js
//  Stand: 2016-02-162017-07-12, 15:02:21
// Author: Bernd Fallert, UB Mannheim

// ToDo: Timer des Hauptfensters ausschalten wenn unterfenster aufgerufen wird
//          und wieder einschalten wenn unterfenster aus irgendeinem Grunde
//          geschlossen wird

var debug = false;
//var debug       = true;
var debug_level = 3;
// Wird für Fehlersuche benötigt
var lSlow       = false;
//var lSlow       = true;

if (typeof vMaBookShelfHelper === "undefined") {
    apiLog( "1---------->vMaBookShelfHelper setzen", 'n', 0 );
    var vMaBookShelfHelper          = vMaBookShelfHelper || {};
    vMaBookShelfHelper.settings     = vMaBookShelfHelper.settings || {};
} else {
    apiLog( "2---------->vMaBookShelfHelper schon definiert", 'n', 0 );
    var vMaBookShelfHelper          = vMaBookShelfHelper || {};
    vMaBookShelfHelper.settings     = vMaBookShelfHelper.settings || {};
}

var d                           = document;
var host                        = d.location.host;

var cFileType                   = $( "#vMaBookShelfHelper_type" ).text();
var lInfoBlockVorhanden         = false;
if ( $( "#vMaBookShelfHelper" ).length > 0 ) {
    lInfoBlockVorhanden = true;

    apiLog( "----> Aus Webseite ausgelesen: cFileType: " + cFileType, "n", 0 );
}
//------------------------------------------------------------------------------
// Fuer Pruefung auf RufeExterneURL.php und UB3D
//------------------------------------------------------------------------------
var ScriptName                  = d.location.pathname;

var lZeigeButton                = false;
var lZeigeOverlayButton         = false;
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

apiLog( "START", "n", 0 );

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

apiLog( "\n\n\n\n\n\n" + "#".repeat(80) + "\n" +
        "ScriptName: '" + ScriptName + "'\n" +
        " substr 10: '" + ScriptName.substr(0, 10) + "'", "n", 0);


if (lInfoBlockVorhanden) {

    apiLog( "----------CHECK 1------------------", "n", 0 );
    apiLog( "cFileType: " + cFileType, "n", 0 );

    if (cFileType === 'html') {
        // normale html-Seiten des BookShelfs
        apiLog( "normale html-Seiten des BookShelfs", "n", 0 );

        lZeigeButton    = false;
        lHauptFenster   = true;
        lUnterFenster   = false;
    } else {
        apiLog( "seiten auf denen der Button angezeigt werden soll", "n", 0 );

        // seiten auf denen der Button angezeigt werden soll
        // hier ist cFileType nicht 'html'!
        lZeigeButton    = true;
        lHauptFenster   = false;
        lUnterFenster   = true;
    };

} else if (host === "localhost") {
    // Keine Aktion bei localhost
    apiLog( "----------CHECK 2 else if localhost ------------------\n", "n", 0 );

} else if (host === "onlinelesen.ciando.com") {
    //--------------------------------------------------------------------------
    // In diesem Fall wird eine alternative Technik benutzt,
    // die bei JumpHomeMa verwendet wurde!
    // Der Button wird nicht in einem IFrame, sondern als halbtransparenter
    // Button links unten einblenden
    //--------------------------------------------------------------------------
    apiLog( "----------CHECK 3 else if onlinelesen.ciando.com ---------------", "n", 0 );

    var isInIFrame      = false;
    lZeigeButton        = false;
    // hierdurch wird Overlaybutton angezeigt
    lZeigeOverlayButton = true;

} else if (host === "elibrary.vahlen.de") {
    //--------------------------------------------------------------------------
    // In diesem Fall wird eine alternative Technik benutzt,
    // die bei JumpHomeMa verwendet wurde!
    // Der Button wird nicht in einem IFrame, sondern als halbtransparenter
    // Button links unten einblenden
    //--------------------------------------------------------------------------
    apiLog( "----------CHECK 3 else if elibrary.vahlen.de ---------------", "n", 0 );

    var isInIFrame      = false;
    lZeigeButton        = false;
    // hierdurch wird Overlaybutton angezeigt
    lZeigeOverlayButton = true;

} else if (host === "primo.bib.uni-mannheim.de") {
    //--------------------------------------------------------------------------
    // In diesem Fall wird eine alternative Technik benutzt,
    // die bei JumpHomeMa verwendet wurde!
    // Der Button wird nicht in einem IFrame, sondern als halbtransparenter
    // Button links unten einblenden
    //--------------------------------------------------------------------------
    apiLog( "----------CHECK 3 else if primo.bib.uni-mannheim.de ---------------", "n", 0 );

    var isInIFrame      = false;
    lZeigeButton        = false;
    // hierdurch wird Overlaybutton angezeigt
    lZeigeOverlayButton = true;



} else {
    apiLog( "----------CHECK 4 else ---------------", "n", 0 );

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

        apiLog( "kein IFrame: Kontext verlassen daher\n" +
                "rufe ich neu auf: " +
                "http://aleph.bib.uni-mannheim.de/booklist/" +
                "RufeExterneURL.php?url=" +
                aktLocation, "n", 0 );
        //----------------------------------------------------------------------
        // Seite nochmals über das Script RufeExterneURL.php aufrufen,
        // damit Seite wieder in IFrame gefangen wird
        //----------------------------------------------------------------------
        //alert( "im IFrame" + "\n" + window.location );

        // an main.js Nachricht schicken, ich brauche die aktuelle Konfiguration für url
        self.port.emit("giveUrlBack", '');
        self.port.on("aktURL", function holeurl(cUrl) {
            vMaBookShelfHelper.settings.HomeUrl = cUrl;

            apiLog( "A".repeat(50) + "\n", "n", 0 );
            apiLog( "in aktURL cUrl: " + cUrl, "n", 0 );
            apiLog( "A".repeat(50) + "\n", "n", 0 );
            apiLog( vMaBookShelfHelper.settings.HomeUrl + "/RufeExterneURL.php?url=" +
                                      aktLocation, "n", 0 );

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


apiLog( "\n" +
    "--------------------------------------------\n" +
    "vor lZeigeButton: '" + lZeigeButton +
    "'\n--------------------------------------------\n" + "\n\n", "n", 0);

if (lZeigeButton) {
    var div = document.createElement("div");
    div.innerHTML = "<a id='closediv' " +
                    "class='schliessbutton_neu_links'>" +
                    "<span id='oben' " +
                        "width='67px' " +
                        "style='width: 57px;' " +
                        ">" +
                    "</span>" +
                    "<span id='mitte'" +
                    ">" +
                        "Schließen<br>/<br>Close" +
                        "</span>" +
                    "<span id='unten' " +
                       "style='width: 57px;' " +
                    "></span>" +
                    "</a>";
    div.style.color = "white";
    div.setAttribute("class", "UBMaSchliess");

    document.body.insertBefore(div, document.body.firstChild);

    // Schliessen zuordnen
    var el = document.getElementById("closediv");
    el.addEventListener("click", function(){closeWin()}, false );
    el.addEventListener("touchstart", function(){closeWin()}, false );
    el.addEventListener("touched", function(){closeWin()}, false );

    apiLog( "Scriptname: " + ScriptName.substr(0,10), "n", 0);
    if (!lSlow) {
        window.TimerID = window.setTimeout(function(){WelchesFensterIstAktiv();}, 10000);
    } else {
        window.TimerID = window.setTimeout(function(){WelchesFensterIstAktiv();}, 100000);
    }

} else if (lZeigeOverlayButton) {

    apiLog( "----------CHECK 3 else if onlinelesen.ciando.com u.a. lZeigeOverlayButton", "n", 0 );

    var div = document.createElement("div");
    //var AktInfoTerminalStartseiteAufrufenWebadresse = vMaBookShelfHelper.settings.HomeUrl;
    // Der Button soll nur das aktive Fenster schliessen
    div.innerHTML = "<a id='info-terminal-home-button' " +
                    "data-ajax='false' " +
                    "class='schliessbutton_neu_links_ohne_frame' title='Home'>" +
                    "</a>";
    div.style.color = "white";
    div.setAttribute("class", "UBMaSchliess_ohne_frame");

    apiLog( "\n" +
        '------in iframe?-------------------------------------------' +
        "\n", "n", 0 );

    var isInIframe = (window.location != window.parent.location) ? true : false;

    apiLog( "----------CHECK 3 else if onlinelesen.ciando.com u.a. TEST ob in Frame", "n", 0 );
    apiLog( isInIframe, "n", 0 );

    if (!isInIframe) {
        apiLog( "----------CHECK 3a else if onlinelesen.ciando.com u.a. !isInIframe", "n", 0 );
        document.body.insertBefore(div, document.body.firstChild);

        apiLog( "----------CHECK 3 ordne addEnventListener zu", "n", 0 );
        var el = document.getElementById("info-terminal-home-button");
        el.addEventListener("click", function(){closeWin()}, false );
        el.addEventListener("touchstart", function(){closeWin()}, false );
        el.addEventListener("touched", function(){closeWin()}, false );


    } else {
        apiLog( "----------CHECK 3b else if onlinelesen.ciando.com u.a. isInIframe", "n", 0 );
    }

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
        if (debug) {
            // Jetzt testweise alle Elemente mit class fachnavi durchgehen
            apiLog( "fehlersuche: alle Elemente mit class fachnavi auflisten", "n", 0);
            $( '.fachnavi' ).each(function(index) {
                apiLog( "index: " + index + " " + $(this).data('id'), "n", 0);
            });
            apiLog( "ENDE: fehlersuche: alle Elemente mit class fachnavi auflisten", "n", 0);
        };
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

    apiLog( "-----------------------------\n" +
        "Alter Timer window.TimerID: " +
        window.TimerID + "\n-----------------------------\n", "n", 0 );

    apiLog( "-----------------------------\n" +
            "         Setze jetzt die Events (1)", "n", 0 );

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
        apiLog( nBooklistTimerIndex.getCount(), "n", 0);
        apiLog( "Scriptname (kurz): " + ScriptName.substr(0,10), "n", 0);
        apiLog( "Scriptname:(voll): " + ScriptName, "n", 0);
        apiLog( "window.TimerID: " + window.TimerID, "n", 0);

        self.port.emit("empfangeUnterfensterAktiv", true);

    } else if (nBooklistTimerIndex.getCount() < (1000 * nMinutenExternFenster)) {
        // wenn es groesser als das erste Zahl ist dann wird das overlay
        // angezeigt und ein zweiter Timer läuft an der nach 1 Minut
        // das Fenster beendet
        nBooklistTimerIndex.inc();
        apiLog( nBooklistTimerIndex.getCount(), "n", 0);

        // Overlay anzeigen mit der Frage ob noch jemand lebt
        overlay('display');

        apiLog( "2".repeat(10) + " Scriptname (kurz): " +
            ScriptName.substr(0,10), "n", 0);
        apiLog( "2".repeat(10) + " Scriptname:(voll): " + ScriptName, "n", 0);
        apiLog( "2".repeat(10) + " window.TimerID: " + window.TimerID, "n", 0);
    }

    if (!lClose) {
        apiLog( "2-----------------------------\n" +
            "Alter Timer window.TimerID: " +
            window.TimerID + "\n2-----------------------------\n", "n", 0 );
        if (!lSlow) {
            window.TimerID = window.setTimeout(WelchesFensterIstAktiv, 10000);
        } else {
            window.TimerID = window.setTimeout(WelchesFensterIstAktiv, 100000);
        }
        apiLog( "neuer Timer wurde gesetzt: " + window.TimerID, "n", 0);
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
    apiLog( "\n\n-----------------------------\n" +
            "wurde beendet durch liestNochJemand\n\n", "n", 0);
    window.close();
};


function BehandleClickUndTouch() {
    apiLog( "-----------------------------\n" +
            "Es wurde geklickt: " + nBooklistTimerIndex.getCount(), "n", 0);
    // Zähler reseten, damit ist der Counter und damit der Timer zurückgesetzt
    nBooklistTimerIndex.reset();

    apiLog( "in BehandleClickUndTouch: " + nBooklistTimerIndex.getCount(), "n", 0);

    // Overlay wieder entfernen wenn es vorhanden ist
    overlay('hide');

    // Timer für Lebt noch jemand abbrechen
    if (typeof( window.LiestNochJemandTimerID ) !== 'undefined') {
        clearTimeout(window.LiestNochJemandTimerID);
        apiLog( "Stopp window.LiestNochJemandTimerID: " +
                window.LiestNochJemandTimerID, "n", 0);
    };

}


function BehandleClickUndTouchHauptFenster() {
    apiLog( "-----------------------------\n" +
            "Es wurde geklickt: " + nBooklistTimerIndex.getCount(), "n", 0);
    // Zähler reseten, damit ist der Counter und damit der Timer zurückgesetzt
    nBooklistTimerIndex.reset();

    apiLog( "in BehandleClickUndTouchHauptFenster: " +
            nBooklistTimerIndex.getCount(), "n", 0);
}




function SchalteHauptFensterUm () {

    apiLog( "function: SchalteHauptFensterUm");
    apiLog( "nZeitSchalteHauptFensterUm:" + nZeitSchalteHauptFensterUm, "n", 0);

    // Timer für Schliesen des Fensters mit Touch oder Click zurücksetzen

    apiLog( "-----------------------------\n" +
            "                                  Setze jetzt die Events (2)", "n", 0);


    apiLog( "\n" + "=".repeat(40) + "\n(1) vor istUnterfensterAktiv\n" + "=".repeat(40), "n", 0);

    self.port.on("istUnterfensterAktiv", function(tag) {
        apiLog( "Alt: " + nBooklistTimerIndex.getCount(), "n", 0);
        nBooklistTimerIndex.reset();
        apiLog( "neu: " + nBooklistTimerIndex.getCount(), "n", 0);

        if (tag) {
            apiLog( "\n\n" + "?".repeat(32) +
                    "\n\nUnterfenster ist NOCH aktiv (in SchalteHauptFensterUm)\n", "n", 0);
            apiLog( "Alt: " + nBooklistTimerIndex.getCount(), "n", 0);

            nBooklistTimerIndex.reset();
            apiLog( "neu: " + nBooklistTimerIndex.getCount(), "n", 0);
        } else {
            apiLog( "\n\n" + "?".repeat(32) +
                    "\n\nUnterfenster ist NICHT aktiv (in SchalteHauptFensterUm)\n", "n", 0);
        };
    });
    apiLog( "\n" + "=".repeat(40) +
        "\n(1) nach istUnterfensterAktiv\n" + "=".repeat(40), "n", 0);


    //BehandleClickUndTouch
    window.ClickIdHauptFenster  = document.body.
        addEventListener('click', BehandleClickUndTouchHauptFenster, false);
    window.TouchIdHauptFenster  = document.body.
        addEventListener('touchstart', BehandleClickUndTouchHauptFenster, false);

    //#############################################
    // Aktuellen Stand Counter ausgeben
    //#############################################
    apiLog( "\n\n\n" + "=".repeat(60) + "\nnBooklistTimerIndex.getCount(): '" +
        (nBooklistTimerIndex.getCount()+1) + "'\n" + "=".repeat(60) + "\n\n", "n", 0);

    if (nBooklistTimerIndex.getCount() < (6 * nMinutenHauptFenster)) {
        //----------------------------------------------------------------------
        // Nr. hochzählen
        // solange kleiner als hier passiert ausser dem hochzählen nichts
        //----------------------------------------------------------------------
        apiLog( "Wartezeit Hauptfenster " +
            (nBooklistTimerIndex.getCount()+1) +
            " von " + (6 * nMinutenHauptFenster), "n", 0);

        nBooklistTimerIndex.inc();
        //apiLog( nBooklistTimerIndex.getCount(), "n", 0);
        apiLog( "window.TimerIDHauptFenster: " + window.TimerIDHauptFenster, "n", 0);

        apiLog( "\n" + "=".repeat(40) + "\n(2) vor istUnterfensterAktiv\n" + "=".repeat(40), "n", 0);

        self.port.on("istUnterfensterAktiv", function(tag) {
            nBooklistTimerIndex.reset();
            apiLog( "\n\n" + "?".repeat(20) +
                "\n\nUnterfenster ist noch aktiv (in SchalteHauptFensterUm)\n", "n", 0);
        });
        apiLog( "\n" + "=".repeat(40) + "\n(2) nach istUnterfensterAktiv\n" + "=".repeat(40), "n", 0);

    } else if (nBooklistTimerIndex.getCount() < (1000 * nMinutenHauptFenster)) {
        //----------------------------------------------------------------------
        // Wartezeit abgelaufen
        // Umschalten auf andere URL
        //----------------------------------------------------------------------
        apiLog( "Wartezeit Hauptfenster abgelaufen " +
            (nBooklistTimerIndex.getCount() + 1) +
            " von " + (6 * nMinutenHauptFenster) + "\n".repeat(2), "n", 0);

        nBooklistTimerIndex.inc();
        //console.log(nBooklistTimerIndex.getCount());

        // umschalten auf andere url
        WaehleZufaelligesFach();

        apiLog( "Scriptname (kurz): " +
            ScriptName.substr(0,10), "n", 0);
        apiLog( "Scriptname:(voll): " +
            ScriptName, "n", 0);
        apiLog( "window.TimerIDHauptFenster: " +
            window.TimerIDHauptFenster, "n", 0);
    }

    // Clear Timeout, zur Sicherheit!
    //https://wiki.selfhtml.org/wiki/JavaScript/Objekte/window/setTimeout
    clearTimeout(window.TimerIDHauptFenster);
    if (!lSlow) {
        window.TimerIDHauptFenster = window.setTimeout(SchalteHauptFensterUm, 10000);
    } else {
        window.TimerIDHauptFenster = window.setTimeout(SchalteHauptFensterUm, 100000);
    }
    apiLog( "neuer TimerHauptFenster wurde gesetzt: " +
            window.TimerIDHauptFenster, "n", 0);
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
    apiLog( "\nlese Elemente mit Class 'fachnavi' zur Ermittlung des "+
            "nächsten zufälligen Fachs\n", "n", 0);

    $( '.fachnavi' ).each(function(index) {
        var nID = $(this).data('id');
        apiLog( "index: '" + index + "' nID: '" + nID + "'", "n", 0);
        aHtmlFaecherListe.push(nID);
    });

    //--------------------------------------------------------------------------
    // Zufaellige Sprungadresse ermitteln
    //--------------------------------------------------------------------------
    var aktIndex = getRandomInt( 1, aHtmlFaecherListe.length );
    apiLog( "\n".repeat(2) + "=".repeat(30) +
            "\nWaehleZufaelligesFach\nElement=>aktIndex: " +
            (aktIndex - 1) + "\nFach: " + aHtmlFaecherListe[ aktIndex - 1 ] +
            "\nAnzahl Fächer (aHtmlFaecherListe.length): " +
            aHtmlFaecherListe.length, "n", 0);

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
    apiLog( "\n\n\n===================================" +
            "\nhost: " + host + "\ncScriptPath: " + cScriptPath +
            "\n===================================\n", "n", 0);


    // An die URL wird random angehaengt, damit koennen diese Aufrufe separat
    // gezaehlt werden
    document.location.replace("http://" + host +
                              cScriptPath +
                              aHtmlFaecherListe[ aktIndex - 1 ] +
                              cOptGesten + ".html?random");
}


function closeWin() {
    apiLog( "closeWin", "n", 0);
    window.close();   // Closes the new window
}

//==============================================================================
//      Name: apiLog
//   Aufgabe: Debugging-Meldungen in der Firebug-Konsole oder auf einem
//              anderen Weg ausgeben
// Parameter: pText
//                  => der auszugebende Text
//            pType
//                  => Typ der Ausgabe
//                      n  / normal
//                      i / info
//                      g / group / gruppiere
//                      ge / groupEnd / gruppiereEnde
//                      e / /error / f / fehler
//            pDebugLevel
//                  =>  0 am wenigsten Meldungen
//                      1
//                      2
//==============================================================================
function apiLog( pText, pType, pDebugLevel ) {
    // Ausnahmsweise nicht ausgeben, sonst wird alles etwas unuebersichtlich!
    //        apiLog( " ---------------------------------------------------------------------", 'info', 0);
    //        apiLog( " this.apiLog", 'info', 0);
    //        apiLog( " ---------------------------------------------------------------------", 'info', 0);

    if (debug) {
        if ( pDebugLevel <= debug_level ) {
            if (pType == '' || pType == 'n' || pType == 'normal') {
                console.log( pText );
            } else if (pType == 'info' || pType == 'i' ) {
                console.info( pText );
            } else if (pType == 'group' || pType == 'g' || pType == 'gruppiere'  ) {
                if ($.browser.msie) {
                    console.log( "=========GROUP===============================================================" );
                    console.log( pText );
                    console.log( "=========GROUP===============================================================" );
                } else {
                    console.group( pText );
                }

            } else if (pType == 'groupEnd' || pType == 'ge' || pType == 'gruppiereEnde'  ) {
                //console.groupEnd();
                if ($.browser.msie) {
                    console.log( "=========GROUP END============================================================" );
                } else {
                    console.groupEnd();
                }
            } else if (pType == 'error' || pType == 'e' || pType == 'f'  || pType == 'fehler'  ) {
                console.error( pText );
            }
        }
    }
}
