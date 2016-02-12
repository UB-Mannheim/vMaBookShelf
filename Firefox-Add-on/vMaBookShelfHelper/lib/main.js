// Testvariable
//var tag = "ul";

var vMaBookShelfHelper = vMaBookShelfHelper || {};
vMaBookShelfHelper.settings = vMaBookShelfHelper.settings || {};

var data = require("sdk/self").data;
var pageMod = require("sdk/page-mod");
//var bookListTimer = require("sdk/timers");
var utils = require('sdk/window/utils');
var windows = require("sdk/windows");

var prefs = require("sdk/simple-prefs");
//var debug = false;
//var debug = true;

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
                    "div.UBMaSchliess a.schliessbutton_neu_links {" +
                    "text-decoration: none; " +
                    "}",
                    "div.UBMaSchliess a.schliessbutton_neu_links span#mitte { " +
                    "color: #ffffff;" +
                    "}",
                    "body {height: 100%; }"
                   ],
    contentScriptWhen: "ready",
    onAttach: function(worker) {
        apiLog( "\n" + "=".repeat(80) + "\njetzt in onAttach" + "\n" + "=".repeat(80));
            //console.log( "tag: " + tag );
            //worker.port.emit("getElements", tag);

        for (let window of windows.browserWindows) {
            apiLog( "title: " + window.title, "n", 0);
        }

        apiLog( "Anzahl: " + windows.browserWindows.length, "n", 0);

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
        worker.port.on("anzahlElemente", function(elementContent) {
            //console.log( "worker.port.on 'anzahlElemente' " + "+".repeat(68) );
            apiLog( "\n" + "=".repeat(80) + "\n" +
                "worker.port.on 'BEGINN von anzahlElemente' " + "\n" +
                "=".repeat(80), "n", 0);

            apiLog( "\n" + "=".repeat(80) + "\n" +
                "worker.port.on 'anzahlElemente' " + "\n" +
                "=".repeat(80) +
                "\nanzahlElemente: elementContent: " +
                elementContent + " " + "%".repeat(12) +
                "\n", "n", 0);

            for (var prop in windows.browserWindows) {
                var window = windows.browserWindows[prop];
                apiLog( "Titel: (window.title):" + window.title, "n", 0);
            };
            apiLog( "Anzahl: (windows.browserWindows.length): " +
                    windows.browserWindows.length, "n", 0);
            apiLog( "\n" + "=".repeat(80) + "\n" +
                    "worker.port.on 'ENDE von anzahlElemente' " + "\n" +
                    "=".repeat(80), "n", 0);
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
