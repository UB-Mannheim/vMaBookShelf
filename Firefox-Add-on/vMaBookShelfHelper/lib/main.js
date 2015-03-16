var tag = "ul";

var vMaBookShelfHelper = vMaBookShelfHelper || {};
vMaBookShelfHelper.settings = vMaBookShelfHelper.settings || {};

var data = require("sdk/self").data;
var pageMod = require("sdk/page-mod");
//var bookListTimer = require("sdk/timers");
var utils = require('sdk/window/utils');
var windows = require("sdk/windows");

var prefs = require("sdk/simple-prefs");

vMaBookShelfHelper.settings.HomeUrl = prefs.prefs['HomeUrl'];



// define a generic prefs change callback
function onPrefChange(prefName) {
    console.log("The " + prefName +
        " preference changed, current value is: " +
        prefs.prefs[prefName]
    );
    if (prefName == 'HomeUrl') {
        vMaBookShelfHelper.settings.HomeUrl = prefs.prefs[prefName];
    }
    console.log( vMaBookShelfHelper );
}

prefs.on("HomeUrl", onPrefChange);


var lUnterFensterAktiv  = false;

pageMod.PageMod({
    include: "*",
    contentScriptFile: [ data.url("js/jquery/jquery-2.1.0.min.js"),
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
        console.log( "\n" + "=".repeat(80) + "\njetzt in onAttach" + "\n" + "=".repeat(80));
        console.log( "tag: " + tag );
        //worker.port.emit("getElements", tag);
        worker.port.emit("getAnzahl", tag);
        worker.port.on("gotElement", function(elementContent) {
            console.log( "worker.port.on 'gotElement' " + "+".repeat(68) );
            console.log(elementContent);
        });
        worker.port.on("giveUrlBack", function(data) {
            worker.port.emit("aktURL", vMaBookShelfHelper.settings.HomeUrl);
        });
        worker.port.on("anzahlElemente", function(elementContent) {
            //console.log( "worker.port.on 'anzahlElemente' " + "+".repeat(68) );
            console.log( "\n" + "=".repeat(80) + "\n" +
                "worker.port.on 'BEGINN von anzahlElemente' " + "\n" +
                "=".repeat(80));

            console.log( "\n" + "=".repeat(80) + "\n" +
                "worker.port.on 'anzahlElemente' " + "\n" +
                "=".repeat(80) +
                "\nanzahlElemente: elementContent: " +
                elementContent + " " + "%".repeat(12) +
                "\n");
            for each (var window in windows.browserWindows) {
              console.log("Titel: (window.title):" + window.title);
            };
            console.log("Anzahl: (windows.browserWindows.length): " +
                windows.browserWindows.length);
            console.log( "\n" + "=".repeat(80) + "\n" +
                "worker.port.on 'ENDE von anzahlElemente' " + "\n" +
                "=".repeat(80));
        });
        worker.port.on("empfangeUnterfensterAktiv", function(elementContent) {
            console.log( "\n" + "=".repeat(80) + "\n" +
                "worker.port.on 'BEGINN von empfangeUnterfensterAktiv' " + "\n" +
                "=".repeat(80));

            console.log( "\n" + "=".repeat(80) + "\n" +
                "worker.port.on 'empfangeUnterfensterAktiv' " +
                "\n" + "=".repeat(80) +
                "empfangeUnterfensterAktiv: elementContent: " +
                elementContent + " " +
                "%".repeat(12) + "\n");

            if (elementContent) {
                lUnterFensterAktiv  = true;
                worker.port.emit("istUnterfensterAktiv", lUnterFensterAktiv);
                console.log("---> Unterfenster --->aktiv<---: ja");
            } else {
                lUnterFensterAktiv  = false;
                worker.port.emit("istUnterfensterAktiv", lUnterFensterAktiv);
                console.log("===>Unterfenster --->NICHT<--- aktiv");
            }
            console.log( "\n" + "=".repeat(80) + "\n" +
                "worker.port.on 'ENDE von empfangeUnterfensterAktiv' " +
                "\n" + "=".repeat(80));
        });
    }
});
