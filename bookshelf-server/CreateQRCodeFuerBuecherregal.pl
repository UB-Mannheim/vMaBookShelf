#!/usr/bin/perl -w
#-------------------------------------------------------------------------------
# Copyright (C) 2014 Universitätsbibliothek Mannheim
# Name:
#       CreateQRCodeFuerBuecherregal.pl
# Author:
#       Bernd Fallert <bernd.fallert@bib.uni-mannheim.de>
# Projekt:
#       booklist
# Aufgabe:
#       erzeugen aller QR-Code-Dateien
# Aufruf:
#       perl CreateQRCodeFuerBuecherregal.pl --print=learningcenter_print.csv --ebook=ebooks.csv
#       da nach diesem Script zusätzlich CreateGesamtBuecherregal.pl
#       aufgerufen werden muss empfiehlt sich ein Shell-Script das den Aufruf
#       beider Scripte übernimmt
# Hinweis:
#       die Aufteilung in zwei Script wurde notwendig nachdem sich herausstellte
#       das sich die beiden Perl-Module
#       - Image::Resize
#       und
#       - GD::Barcode::QRcode
#       nicht vertagen, sind beide eingebunden ist es nicht mehr möglich
#       QR-Codes zu erzeugen
#-------------------------------------------------------------------------------
# Feldreihenfolge bei den CSV-Dateien
# bei ebooks
#RecordID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Fach|Signatur|URL
# bei prints
#Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Signatur|Fach


BEGIN {
    use CGI::Carp qw(carpout);
    #-----------------------------------------------
    # die Datei muss fuer OTHER schreibbar sein!
    #-----------------------------------------------
    my $log = __FILE__ . ".log";
    open( ERRORLOG, ">$log" ) or die "Kann nicht in $log schreiben $!\n";
    carpout (*ERRORLOG);
};


use lib '.';

use strict;
use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

use CGI::Carp qw(carpout);
use Encode qw(_utf8_off _utf8_on is_utf8 decode_utf8 encode_utf8 from_to);
use Getopt::Long;
use GD::Barcode::QRcode;
use Config::IniFiles qw( :all);


$|                          = 1;
my $log                     = __FILE__ . ".log";

my $wahr                    = 1;
my $falsch                  = 0;
my $debug                   = $falsch;

my $lresetlog               = $falsch;

my $lAlleNeuErzeugen        = $falsch;

my $INIFILE                 = 'config/booklist.ini';


#-------------------------------------------------------------------------------
# Normale Programmkonfiguration einlesen
#-------------------------------------------------------------------------------
my $cfg = new Config::IniFiles( -file => $INIFILE );

#-------------------------------------------------------------------------
# Konfiguration lesen
#-------------------------------------------------------------------------
$cfg->ReadConfig;

#'quelldaten';                  # ohne abschliesendes /
my $sourceDir               = TransformWinPathToPerl($cfg->val( 'PATH', 'cvs' ));
if ($sourceDir =~ m/^(.*?)\/$/) {
    $sourceDir = $1;
}


# 'learningcenter_print.csv';   # default für print-csv-Datei
my $pSourceFilePrint        = $cfg->val( 'CSV', 'print' );

# 'ebooks.csv';                 # default für ebooks-csv-Datei
my $pSourceFileEbook        = $cfg->val( 'CSV', 'ebook' );

# 'http://link.bib.uni-mannheim.de/ds/';
# wird jeweils noch ergaenzen um 'MAN_ALEPH001494969'
my $SearchLinkBase          = $cfg->val( 'URL', 'qr_base' );


# '/var/www/booklist/QRCache/'; oder lokal auf gewünschte Verzeichnis
my $PfadQRCodeBase          = TransformWinPathToPerl($cfg->val( 'PATH', 'qr_cache' ));
if ($PfadQRCodeBase =~ m/^(.*?)(?!\/)$/) {
    $PfadQRCodeBase .= '/';
}

#-------------------------------------------------------------------------------
# In Mannheim 'MAN_ALEPH'
# Kann ermittelt werden aus dem Link auf dem Reiter 'Details' und
# innerhalb dessen der Parameter 'doc'
#-------------------------------------------------------------------------------
my $cAlephIDVorspann        = $cfg->val( 'ALEPH_ID', 'vorspann' );
#-------------------------------------------------------------------------
# Konfiguration lesen Ende
#-------------------------------------------------------------------------


GetOptions(
            "sourceprint|quellprint|print=s"    => \$pSourceFilePrint,
            "sourceebook|quellebook|ebook=s"    => \$pSourceFileEbook,
            "all|new|neu"                       => \$lAlleNeuErzeugen,
            # Errolog beim Starten loeschen
            "resetlog"                          => \$lresetlog,
          );







#--------------------------------------------------------------
# wenn gewünscht ist das das Errorlog zurückgesetzt wird
#--------------------------------------------------------------
if ($lresetlog)
{
    open( ERRORLOG, ">$log" ) or die "Kann nicht in $log schreiben $!\n";
    carpout (*ERRORLOG);
    ERRORLOG->autoflush(1);
};


#--------------------------------------------------------------
# Dateinamen für die Quelldateien um Pfad anreichern
#--------------------------------------------------------------
my $SourceFilePrint  = $sourceDir . '/' . $pSourceFilePrint;
my $SourceFileEbook  = $sourceDir . '/' . $pSourceFileEbook;


#--------------------------------------------------------------
# CSV-Dateien zum lesen oeffnen
#--------------------------------------------------------------
open( SOURCEPRINT, "<$SourceFilePrint" ) or
    die "Kann SOURCE-PRINT $SourceFilePrint nicht oeffnen $!\n";
open( SOURCEEBOOK, "<$SourceFileEbook" ) or
    die "Kann SOURCE-EBOOK $SourceFileEbook nicht oeffnen $!\n";


LeseQuellDaten(
    \*SOURCEPRINT,
    $SearchLinkBase,
    $PfadQRCodeBase,
    $lAlleNeuErzeugen,
    $cAlephIDVorspann);

LeseQuellDaten(
    \*SOURCEEBOOK,
    $SearchLinkBase,
    $PfadQRCodeBase,
    $lAlleNeuErzeugen,
    $cAlephIDVorspann);


#-------------------------------------------------------------------------------
#
# Quelldaten einlesen
#
#-------------------------------------------------------------------------------
sub LeseQuellDaten {

    my ($fh)                = shift();          # 1

    # Parameter zur Weitergabe wq QRCode
    my $urlBase             = shift();          # 2
    my $PfadQRCodeBase      = shift();          # 3
    my $lAlleNeuErzeugen    = shift();          # 4
    # Parameter zur Weitergabe wq QRCode Ende
    my $cAlephIDVorspann    = shift();          # 5

    my $nIndex              = 0;
    my $nBuchIndex          = 0;
    my %SpaltenIndex        = ();
    my %SpaltenName         = ();
    my %AlephIds            = ();
    my $lEbook              = $falsch;


    #---------------------------------------------------
    # CSV-Datei lesen
    #---------------------------------------------------
    while(<$fh>) {
        $nIndex++;
        chomp;
        my $aktZeile    = $_;

        #---------------------------------------------------
        # Überspringen von leeren Zeilen in den Quelldaten
        #---------------------------------------------------
        if (length($aktZeile) > 2 ) {

            #------------------------------------------------------------
            # in der Spalte URL ist teilweise ein | enthalten
            # diesen | wird in seinen url-Codierten Wert umgewandelt
            # Bedingung ist das die URL-Spalte die letzte Spalte in der
            # CSV-Datei ist!
            #------------------------------------------------------------
            while ($aktZeile =~ m/http\:(.*?)\|/) {
                $aktZeile =~ s/http\:(.*?)\|/http:$1%7C/;
            }

            # Felder am | aufsplitten
            my @AktFelder   = split( /\|/, $aktZeile );
            my %AktSpalten      = ();
            my $nSpalte         = 0;
            my $lPrintSatzId    = 0;

            #my $cCache          = '';
            my $aktAlephID      = '';

            #------------------------------------------------------
            # Jetzt die einzelnen Zeilen Spaltenweise bearbeiten
            #------------------------------------------------------
            foreach my $akt (@AktFelder) {
                #---------------------------------------------------
                # in erster Zeile Spaltenüberschriften einlesen
                # daran können auch Entscheidungen geknüpft werden
                #---------------------------------------------------
                if ($nIndex == 1) {
                    print $nSpalte . " " . $akt . "\n";
                    $SpaltenName{ $nSpalte }    = $akt;
                    $SpaltenIndex{ $akt }       = $nSpalte;

                    if ($akt eq "RecordID") {
                        $lEbook = $wahr;
                    };
                }


                #---------------------------------------------------------------
                # erst ab der ersten Datenzeile die Datensätze einlesen
                #---------------------------------------------------------------
                if ($nIndex > 1) {
                    #-----------------------------------------------------------
                    # erst ab der Aleph-ID oder RecordID-Spalte wird
                    # es interessant
                    #-----------------------------------------------------------
                    if (    ($SpaltenName{ $nSpalte } eq 'Aleph-ID')
                        or  ($SpaltenName{ $nSpalte } eq 'RecordID')) {
                        #-------------------------------------------------------
                        # wg. Duplikate bei der ID zählen wie oft eine ID
                        # vorkommt.
                        # Nur wenn ID noch nicht vorhanden war die Daten neu
                        # eintragen
                        # Nachtrag am 2014-03-05, 07:52:50
                        # Eine Id kann u.a. dann doppelt vorkommen wenn sie
                        # mehrere Fächerzuordnungen hat, in diesem Fall
                        # ist es ok
                        #-------------------------------------------------------
                        # in Mannheim $cAlephIDVorspann => 'MAN_ALEPH'
                        $aktAlephID = $cAlephIDVorspann . $akt;

                        $AlephIds{ $aktAlephID }++;

                        #-------------------------------------------------------
                        # von jeder AlephID nur ein Buch eintragen
                        # aber verschiedene Daten abgleichen
                        # aktuell das Fach
                        #-------------------------------------------------------
                        if ($AlephIds{ $aktAlephID } < 2)
                        {
                            # Index der Bücher hochzählen, z.B. wg. Mengentest
                            $nBuchIndex++;

                            # Rückmeldungen am Bildschirm geben
                            # Optional machen
                            # z.B. mit Silent oder gespraechig
                            if (!$lEbook) {
                                print "print: ";
                            } else {
                                print "ebook: ";
                            };
                            print $nBuchIndex . "\t";
                            print $aktAlephID;

                            #------------------------------------------
                            # Jetzt QR-Code erzeugen
                            #------------------------------------------
                            my $QrGrafikName = erzeugeQRCode(
                                                    $urlBase,
                                                    $aktAlephID,
                                                    $PfadQRCodeBase,
                                                    $lAlleNeuErzeugen);
                            # Jetzt QR-Code erzeugen Ende
                        }
                    }
                }

                $nSpalte++;
            }
        }
    }
}



############## funktionen fuer QRErzeugung
sub erzeugeQRCode {
    my $urlBase             = shift();
    my $AlephId             = shift();
    my $PfadQRCodeBase      = shift();
    my $lAlleNeuErzeugen    = shift();

    my $url                 = $urlBase . $AlephId;
    my $cGrafikKurzName     = $AlephId . '.png';
    my $cGrafikName         = $PfadQRCodeBase . $cGrafikKurzName;

    if ($lAlleNeuErzeugen) {
        if (-e $cGrafikName)
        {
            unlink $cGrafikName;
        }
    }

    if (-e $cGrafikName) {
        print "\texistiert\n";
    } else {
        #                        1         2         3         4         5
        #               1234567890123456789012345678901234567890123456789012345
        # Kodiert wird: http://link.bib.uni-mannheim.de/ds/MAN_ALEPH000841902
        # also 53 Zeichen
        print "\terzeuge\n";
        #                       { Ecc => 'M', Version=>4, ModuleSize => 2}

        # so klein wie moeglich
        my $oGdBar  = GD::Barcode::QRcode->new($url,
                                {   Ecc         => 'M',
                                    Version     => 4,
                                    ModuleSize  => 1
                                }
                                              );
        # doppelt so viele pixel, besser lesbar, aber mehr platz am Bildschirm
        #my $oGdBar  = GD::Barcode::QRcode->new($url,
        #                        {   Ecc         => 'Q',
        #                            Version     => 5,
        #                            ModuleSize  => 2
        #                        }
        #                                      );
        my $oGD     = $oGdBar->plot();

        open(IMG, '>' . $cGrafikName) or die $!;
        binmode IMG;
        print IMG $oGD->png;
        close IMG;
    };

    return($cGrafikKurzName);
}


sub TransformWinPathToPerl
{
    my $cPath   = shift();
    $cPath =~ s/\\/\//g;
    return( $cPath );
}
# eof: CreateQRCodeFuerBuecherregal.pl