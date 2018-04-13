// Testvariable
//var tag = "ul";

var vMaBookShelfHelper = vMaBookShelfHelper || {};
vMaBookShelfHelper.settings = vMaBookShelfHelper.settings || {};

var data = require("sdk/self").data; // High
var pageMod = require("sdk/page-mod"); // High

var prefs = require("sdk/simple-prefs"); // High
var debug = false;
//var debug = true;
var debug_level = 3;

vMaBookShelfHelper.settings.HomeUrl = prefs.prefs['HomeUrl'];



// define a generic prefs change callback
function onPrefChange(prefName) {
    apiLog( "'" + prefName +
            "' preference geaendert, current value is: " +
            prefs.prefs[prefName], "n", 0
        );

    if (prefName == 'HomeUrl') {
        vMaBookShelfHelper.settings.HomeUrl = prefs.prefs[prefName];
    }
    apiLog( vMaBookShelfHelper, "n", 0 );
}

prefs.on("HomeUrl", onPrefChange);


var lUnterFensterAktiv  = false;

pageMod.PageMod({
    include: "*",
    contentScriptFile: [ data.url("js/jquery/jquery-2.2.0.min.js"),
                         data.url("js/element-getter.js"),
                         data.url("js/erzeuge-close-button.js")],
    contentStyleFile: data.url("css/externe.css"),
    // contentStyle is built dynamically here to include an absolute URL
    // for the file referenced by this CSS rule.
    // This workaround is needed because we can't use relative URLs
    // in contentStyleFile or contentStyle.
    contentStyle: [
                    "#oben,#unten { background-image: url(" +
                    data.url("images/android_back_weiss.gif") + ");" +
                    "background-repeat: no-repeat; " +
                    "background-size: 50px; " +
                    "height: 23px; " +
                    "width: 57px; " +
                    "}",
                    "div.UBMaSchliess a.schliessbutton_neu_links," +
                    "div.UBMaSchliess_ohne_frame a.schliessbutton_neu_links_ohne_frame {" +
                    "text-decoration: none; " +
                    "}",
                    "div.UBMaSchliess a.schliessbutton_neu_links span#mitte { " +
                    "color: #ffffff;" +
                    "}",
                    "body {height: 100%; } " +
                    ".schliessbutton_neu_links_ohne_frame { " +
                    "background-image: url(" +
                    data.url("images/android_back_weiss.gif") + ");" +
                    "background-repeat: no-repeat; " +
                    "background-size: 40%; " +
                    "background-position: center; " +
                    "height: 30px; " +
                    "width: 57px; " +
                    "}",
                   ],
    contentScriptWhen: "ready",
    onAttach: function(worker) {
        apiLog( "\n" + "=".repeat(80) + "\njetzt in onAttach" + "\n" + "=".repeat(80));

        // Hiermit kann eine Funktion aufgerufen werden
        //worker.port.emit("getAnzahl", tag);

        // Hiermit werden funktionen definiert
        worker.port.on("gotElement", function(elementContent) {
            apiLog( "worker.port.on 'gotElement' " + "+".repeat(68, "n", 0) );
            apiLog( elementContent, "n", 0);
        });
        worker.port.on("giveUrlBack", function(data) {
            apiLog( "\n" + "=".repeat(80) + "\n" +
                    "worker.port.on 'giveURLBack rufe aktURL' " +
                    vMaBookShelfHelper.settings.HomeUrl + "\n" +
                    "=".repeat(80), "n", 0);
            worker.port.emit("aktURL", vMaBookShelfHelper.settings.HomeUrl);
        });
        worker.port.on("empfangeUnterfensterAktiv", function(elementContent) {
            apiLog( "\n" + "=".repeat(80) + "\n" +
                    "worker.port.on 'BEGINN von empfangeUnterfensterAktiv' " + "\n" +
                    "=".repeat(80), "n", 0);

            apiLog( "\n" + "=".repeat(80) + "\n" +
                    "worker.port.on 'empfangeUnterfensterAktiv' " +
                    "\n" + "=".repeat(80) +
                    "empfangeUnterfensterAktiv: elementContent: " +
                    elementContent + " " +
                    "%".repeat(12) + "\n", "n", 0);

            if (elementContent) {
                lUnterFensterAktiv  = true;
                worker.port.emit("istUnterfensterAktiv", lUnterFensterAktiv);
                apiLog( "---> Unterfenster --->aktiv<---: ja", "n", 0);
            } else {
                lUnterFensterAktiv  = false;
                worker.port.emit("istUnterfensterAktiv", lUnterFensterAktiv);
                apiLog( "===>Unterfenster --->NICHT<--- aktiv", "n", 0);
            }
            apiLog( "\n" + "=".repeat(80) + "\n" +
                    "worker.port.on 'ENDE von empfangeUnterfensterAktiv' " +
                    "\n" + "=".repeat(80), "n", 0);
        });
        apiLog( "\n" + "=".repeat(80) + "\njetzt ENDE von onAttach" + "\n" + "=".repeat(80), "n", 0);
    }
});


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
