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

## Licence  ![en](http://bib.uni-mannheim.de/fileadmin/scripts/flag_en.jpeg)

This is free software. You may use it under the terms of the
GNU General Public License (GPL). See [LICENSE](LICENSE) for details.

## Lizenz  ![de](http://bib.uni-mannheim.de/fileadmin/scripts/flag_de.jpeg)

Dies ist freie Software. Sie können sie unter den Bedingungen der
GNU General Public License (GPL) verwenden. Siehe [LICENSE](LICENSE) für Details.

## Historie

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
