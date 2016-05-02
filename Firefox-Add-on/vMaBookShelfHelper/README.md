# vMaBookShelfHelper - Firefox Add-on

## Überblick

vMaBookShelfHelper ist ein Add-on für Firefox.

- Das Add-on blendet links unten (mit einem kleinen Abstand zum unteren Rand)
  einen halbtransparenten Home-Button ein.
- Die URL auf die der Home-Button verweist kann mit den normalen
  Konfigurationsseite des Add-ons eingestellt werden.
- Der Home-Button wird nicht eingeblendet, wenn die HTML-Datei innerhalb
  eines iFrames dargestellt wird.
- Bei lokalen Dateien, die nur über file:// aufgerufen werden, wird der
  Home-Button nicht angezeigt.

## Konfiguration

- In Extras / Add-ons / vMaBookShelfHelper / Einstellungen gibt es ein
  Eingabefeld "HomeUrl". In diesem Feld kann die URL hinterlegt werden,
  auf die der Home-Button verlinkt werden soll.
- Gggf. muss nach dem Ändern der URL der Browser neu gestartet werden,
  damit die neue Adresse akzeptiert wird. (scheint nicht mehr der Fall zu sein, noch testen, Fallert 2015-03-16, 13:00:46)

## Notwendige Einstellung in Firefox

- aktuell funktioniert vMaBookShelfHelper nicht, wenn bei Chronik
  "niemals anlegen" ausgewählt wurde. Alternativ kann "nach
  benutzerdefinierten Einstellungen anlegen" ausgewählt und ein Haken bei
  "Die Chronik löschen, wenn Firefox geschlossen wird" gesetzt werden.
- Aktuell funktioniert das Add-on nur bis FF 42, zwischen FF 43 und 46 kann die Warnung durch ein Parameter ausgeschaltet werden, vergleiche hierzu (https://wiki.mozilla.org/Addons/Extension_Signing#Timeline) ''(xpinstall.signatures.required in about:config)''. Ich arbeite an einer vollständigen Freigabe des Add-ons.

## Licence  ![en](http://bib.uni-mannheim.de/fileadmin/scripts/flag_en.jpeg)

This is free software. You may use it under the terms of the
GNU General Public License (GPL). See [LICENSE](LICENSE) for details.

## Lizenz  ![de](http://bib.uni-mannheim.de/fileadmin/scripts/flag_de.jpeg)

Dies ist freie Software. Sie können sie unter den Bedingungen der
GNU General Public License (GPL) verwenden. Siehe [LICENSE](LICENSE) für Details.

## Historie

* 0.9.6 2016-05-02, 20:28:00
                           - console.log ausgeschaltet
* 0.9.5 2016-05-02, 14:14:00
                           - href='javascript:window.close() durch addEventListener
                             ersetzt, wg. Add-on Überprüfung
* 0.9.4 2016-04-22, 15:26:00
                           - Fehler bei Primo umgangen, Button wird jetzt als overlay angezeigt
* 0.9.3 2016-04-22, 14:47:00
                           - remove sdk/window/utils
                           - Fehler bei onlinelesen.ciando.com umgangen, Button wird jetzt als overlay angezeigt
* 0.9.2 2016-02-12, 11:49:04
                           - jQuery von 2.1.0 auf 2.2.0 (Download-Version)
                           - console.log Meldungen in Produktionsversion stillgelegt
* 0.9.1 2016-01-18, 11:17:00
                           - Add-on Erstellung von cfx auf jpm umgestellt.
                           - Icon für das Add-on hinzugefügt.
                           - Debug-Meldungen verbessert.
                           - Timer des Hauptfensters wird bei einigen Events
                             zurückgesetzt (Mousebewegungen, Touchstart, Keypressed...)
* 0.9 2015-03-16, 12:57:32 Adresse für Rück-Button wenn iFrame verlassen werden konnte
                            wird jetzt aus einem Konfigurationsdialog ausgelesen
* 0.8 2014-07-15, 10:03:45 Adresse fuer zufaelligen Sprungs auf andere Faecher
                            wird jetzt direkt aus dem Dokument erzeugt
                            es muss kein Array innerhalb des Add-ons gepflegt
                            werden
* 0.7 2014-06-25, 16:01:28 Fehlersituation umgangen beim zufälligen Laden der
                            Navigationsseiten
* 0.6 2014-06-04, 15:27:38 1. Versuch mit onlinelesen.ciando.com, Reload-Sturm
                            unterbrechen und Liste der Nummern nach Timeout
                            angepasst
* 0.5 2014-04-16, 08:31:32 jetzt mit Timer für Haupt- (30 Minuten) und
                            Unterfenster (10 Minuten)
* 0.4 2014-04-07, 15:40:50 Statt Click jetzt ontouchstart
* 0.3 2014.03.28, 12:47:26 Link auf Beschriftung und Grafiken ergänzt
