#!/usr/bin/perl -w
#-------------------------------------------------------------------------------
# Copyright (C) 2014 Universitätsbibliothek Mannheim
# Name:
#       CreateGesamtBuecherregal.pl
# Author:
#       Bernd Fallert <bernd.fallert@bib.uni-mannheim.de>
# Projekt:
#       booklist
# Aufgabe:
#       erzeugen aller HTML-Dateien
# Aufruf:
#       perl CreateGesamtBuecherregal.pl --print=LBS_gesamt.csv --ebook=ebooks.csv
#       da vor diesem Script zusätzlich CreateQRCodeFuerBuecherregal.pl
#       aufgerufen werden muss, empfiehlt sich ein Shell-Script das den Aufruf
#       beider Scripte übernimmt
# Hinweis:
#       die Aufteilung in zwei Script wurde notwendig nachdem sich herausstellte
#       das sich die beiden Perl-Module
#       - Image::Resize
#       und
#       - GD::Barcode::QRcode
#       nicht vertragen.
#       Sind beide eingebunden ist es nicht mehr möglich QR-Codes zu erzeugen
#-------------------------------------------------------------------------------


BEGIN {
    use CGI::Carp qw(carpout);
    #-----------------------------------------------
    # die Datei muss fuer OTHER schreibbar sein!
    #-----------------------------------------------
    my $log = __FILE__ . ".log";
    open( ERRORLOG, ">$log" ) or die "Kann nicht in $log schreiben $!\n";
    binmode(ERRORLOG, ':utf8');
    carpout (*ERRORLOG);
};


use lib '.';

use strict;
use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

use CGI::Carp qw(carpout);
use Encode qw(_utf8_off _utf8_on is_utf8 decode_utf8 encode_utf8 from_to);
use Unicode::Normalize;
use Getopt::Long;

use CGI qw(:standard);
use Template;
use LWP::UserAgent;

use GD;
use Image::Resize;
use Template::Filters;
Template::Filters->use_html_entities;
use HTML::Hyphenate;
use Config::IniFiles qw( :all);
use Business::ISBN;     # Umrechnen von ISBN 13 in ISBN 10
use File::Basename;
use Cwd qw(cwd);


$|                          = 1;
my $log                     = __FILE__ . ".log";

my $wahr                    = 1;
my $falsch                  = 0;
my $debug                   = $falsch;
my $debugStart              = $falsch;
my $debug_gelesene_db       = $falsch;


my $INIFILE                 = 'config/booklist.ini';

my $dirname = dirname(__FILE__);

if ($dirname eq '.') {
    $dirname = cwd;
};

if (! -e $dirname . '/template/buecherregal_header.tmpl') {
    print $dirname . '/template/buecherregal_header.tmpl not existing, please rename ' . $dirname . '/template/buecherregal_header.tmpl_sample' . "\n";
    die ERRORLOG $dirname . '/template/buecherregal_header.tmpl not existing, please rename ' . $dirname . '/template/buecherregal_header.tmpl_sample' . "\n";
}

#--------------------------
# Templating structure
#--------------------------
my $templ_ref;
my $templCssRef;

my $lresetlog               = $falsch;



my %KeineTrefferCache       = ();
my %MedienDaten             = ();
my %PrintTitel              = ();

#-------------------------------------------------------------------------------
# Altes CSV-Fehler Protokoll leeren
#-------------------------------------------------------------------------------
my $log_csv_error = __FILE__ . ".csv_error.log";
open( CSVERRORLOG, ">$log_csv_error" ) or die "Kann nicht in $log_csv_error schreiben $!\n";
close CSVERRORLOG;



#-------------------------------------------------------------------------------
# Normale Programmkonfiguration einlesen
#-------------------------------------------------------------------------------
my $cfg                     = new Config::IniFiles( -file => $INIFILE );

#-------------------------------------------------------------------------
# Konfiguration lesen
#-------------------------------------------------------------------------
$cfg->ReadConfig;

# html-path
my $htmlpath                = TransformWinPathToPerl($cfg->val( 'PATH', 'html_path' ));
# ohne abschliessendes '/'
if ($htmlpath =~ m/^(.*?)\/$/) {
    $htmlpath = $1;
}

# "index.html"
my $html                    = $cfg->val( 'INDEX', 'html' );

#"index_g.html"
my $html_g                  = $cfg->val( 'INDEX', 'html_gestensteuerung' );

#'DatenCache/keinTreffer.dat'
my $cKeinTrefferCacheFile   = TransformWinPathToPerl($cfg->val( 'STORE', 'kein_treffer_cache_file' ));

#'quelldaten';                  # ohne abschliesendes '/'
#my $sourceDir               = TransformWinPathToPerl($cfg->val( 'PATH', 'cvs' ));
my $sourceDir               = TransformWinPathToPerl($cfg->val( 'PATH', 'csv' ));
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


if ($cfg->exits( 'URL', 'protocol' )) {
    # optional http oder https
    $protocol   = $cfg->val( 'URL', 'protocol' );
} else {
    $protocol   = 'http';
}


#http://section [URL] variable host / section [PATH] variable html_web_path
my $host_name               = $cfg->val( 'URL', 'host' );
# / am Ende von hostname entfernen
if ($host_name =~ m/^(.*?)\/$/) {
    $host_name = $1;
}
# http[s]:// am Anfang entfernen
if ($host_name =~ m/^http[s]{0,1}\:\/\/(.*?)$/) {
    $host_name = $1;
}

# $html_web_path in ini-Verschoben von [PATH] zu [URL]
my $html_web_path   = '';
if ($cfg->exists( 'PATH', 'html_web_path' )) {
    print "deprecated: [PATH] 'html_web_path', better use [URL] 'html_web_path'\n";
    print ERRORLOG "deprecated: [PATH] 'html_web_path', better use [URL] 'html_web_path'\n";
}
if ($cfg->exits( 'URL', 'html_web_path' )) {
    $html_web_path   = $cfg->val( 'URL', 'html_web_path' );

    if ($cfg->exists( 'PATH', 'html_web_path' )) {
        print "[URL] 'html_web_path' is used instead of deprecated: [PATH] 'html_web_path'\n";
    }
} else {
    if ($cfg->exists( 'PATH', 'html_web_path' )) {
        print "deprecated: [PATH] 'html_web_path', better use [URL] 'html_web_path'\n";
    }
    $html_web_path   = $cfg->val( 'PATH', 'html_web_path' );
}
#-------------------------------------------------------------------------------
# prüfen ob html_web_path mit / beginnt und endet
#-------------------------------------------------------------------------------
if ($html_web_path =~ m/^\/(.*?)\/$/) {
    $html_web_path = '/' . $1 . '/';
} elsif ($html_web_path =~ m/^\/(.*?)$/) {
    $html_web_path = '/' . $1 . '/';
} elsif ($html_web_path =~ m/^(.*?)\/$/) {
    $html_web_path = '/' . $1 . '/';
}
# prüfen ob html_web_path nur noch // enthält
if ($html_web_path =~ m/^\/\/$/) {
    $html_web_path  = '/';
}





# http://aleph.bib.uni-mannheim.de/booklist/RufeExterneURL.php?url=
my $openExterneURL_base     = $protocol . '://' . $host_name . $html_web_path . $cfg->val( 'URL', 'openExterneURL_base' );

# http://primo.bib.uni-mannheim.de/primo_library/libweb/action/dlSearch.do?institution=MAN&vid=MAN_UB&search_scope=MAN_ALEPH&query=any,exact,
my $printMedien_base        = $cfg->val( 'URL', 'printMedien_base' );

# '/var/www/booklist/QRCache/';
my $PfadQRCodeBase          = TransformWinPathToPerl($cfg->val( 'PATH', 'qr_cache' ));
if ($PfadQRCodeBase =~ m/^(.*?)(?!\/)$/) {
    $PfadQRCodeBase .= '/';
}



#4;
my $nAnzahlReihen           = $cfg->val( 'REGAL', 'regal_reihen' );

my $lMitGestensteuerung     = $cfg->val( 'GESTENSTEUERUNG', 'erzeuge' );

#15;
my $tastendruckmultiplikator= $cfg->val( 'GESTENSTEUERUNG',
                                            'tastendruckmultiplikator' );
my $AusgleichsPixel         = 20;



#-------------------------------------------------------------------------------
# $cAlephIDVorspann: In Mannheim 'MAN_ALEPH'
# Kann ermittelt werden aus dem Link auf dem Reiter 'Details' und
# innerhalb dessen der Parameter 'doc'
#-------------------------------------------------------------------------------
my $cAlephIDVorspann        = $cfg->val( 'ALEPH_ID', 'vorspann' );


#-------------------------------------------------------------------------------
# Abschnitt für [vMaBookShelfHelper]
#-------------------------------------------------------------------------------
#my $vMaBookShelfHelper_scriptpath   = $cfg->val( 'vMaBookShelfHelper', 'scriptpath' );
my $vMaBookShelfHelper_scriptpath   = $html_web_path;



#-------------------------------------------------------------------------
# Konfiguration lesen Ende
#-------------------------------------------------------------------------


# $lMitGestensteuerung in Logischen Wert umwandeln
# alle zulaessigen Ja-Varianten auffuehren
if (lc($lMitGestensteuerung) eq "ja" ||
    lc($lMitGestensteuerung) eq "yes" ||
    lc($lMitGestensteuerung) eq "j" ||
    lc($lMitGestensteuerung) eq "y") {

    $lMitGestensteuerung    = $wahr;

} else {
    $lMitGestensteuerung    = $falsch;
}

GetOptions(
            "sourceprint|quellprint|print=s"        => \$pSourceFilePrint,
            "sourceebook|quellebook|ebook=s"        => \$pSourceFileEbook,
            # Errolog beim Starten loeschen
            "resetlog"                              => \$lresetlog,
            "debug"                                 => \$debug,
          );

#--------------------------------------------------------------
# wenn gewünscht ist das das Errorlog zurückgesetzt wird
#--------------------------------------------------------------
if ($lresetlog)
{
    open( ERRORLOG, ">$log" ) or die "Kann nicht in $log schreiben $!\n";
    carpout (*ERRORLOG);
    binmode(ERRORLOG, ':utf8');
    ERRORLOG->autoflush(1);
};


$templ_ref->{index}                         = $html;
$templ_ref->{tastendruckmultiplikator}      = $tastendruckmultiplikator;
$templ_ref->{openExterneURL_base}           = $openExterneURL_base;
$templ_ref->{printMedien_base}              = $printMedien_base;

$templ_ref->{vMaBookShelfHelper_scriptpath} = $vMaBookShelfHelper_scriptpath;





my $SourceFilePrint                         = $sourceDir . '/' . $pSourceFilePrint;
my $SourceFileEbook                         = $sourceDir . '/' . $pSourceFileEbook;
my $cStatistikFile                          = 'log/' . "statistik.log";


open( SOURCEPRINT, "<$SourceFilePrint" ) or die
    "Kann SOURCE-PRINT $SourceFilePrint nicht oeffnen $!\n";
#binmode(SOURCEPRINT, ':utf8');
open( SOURCEEBOOK, "<$SourceFileEbook" ) or die
    "Kann SOURCE-EBOOK $SourceFileEbook nicht oeffnen $!\n";
#binmode(SOURCEEBOOK, ':utf8');


if (-e $cKeinTrefferCacheFile) {
    open( KEINTREFFER, "<$cKeinTrefferCacheFile" ) or die
        "Kann SOURCE $cKeinTrefferCacheFile nicht oeffnen $!\n";
    while (<KEINTREFFER>) {
        chomp;
        $KeineTrefferCache{ $_ } = $_;
    }
    close KEINTREFFER;
}

open( STATISTIK, ">$cStatistikFile" ) or die
    "Kann STATISTIK $cStatistikFile nicht zum schreiben oeffnen $!\n";
print STATISTIK "-"x60 . "\n";
print STATISTIK "\tPrint\n";
print STATISTIK "-"x60 . "\n";


############################################
# CSS-Angaben und abhängige Werte
# auslesen und berechnen
############################################

# CSS-Angaben einlesen
$templCssRef->{menu_active__background_color}           =
    $cfg->val( 'CSS', 'menu_active__background_color' );  # #ffffff
$templCssRef->{menu_active__color}                      =
    $cfg->val( 'CSS', 'menu_active__color' );             # #000000

$templCssRef->{menu__background_color}                  =
    $cfg->val( 'CSS', 'menu__background_color' );         # #990000
$templCssRef->{menu__color}                             =
    $cfg->val( 'CSS', 'menu__color' );                    # #ffffff

$templCssRef->{buchsignatur__color}                     =
    $cfg->val( 'CSS', 'buchsignatur__color' );            # #ffffff

# Trennfarbe zwischen Navigation und Buchregal
$templCssRef->{menu__border_right__color}               =
    $cfg->val( 'CSS', 'menu__border_right__color' );      # #ffffff

# Hintergrundfarbe der Regalnummern
$templCssRef->{regalnummer__background_color}           =
    $cfg->val( 'CSS', 'regalnummer__background_color' );  # #585858
$templCssRef->{regalnummer__color}                      =
    $cfg->val( 'CSS', 'regalnummer__color' );             # #ffffff

# Header
$templCssRef->{header__background_color}                =
    $cfg->val( 'CSS', 'header__background_color' );       # #990000

# Trenner zwischen Menue und verkleinerungsleiste
$templCssRef->{id_collapse_menu__border_left_color}     =
    $cfg->val( 'CSS', 'id_collapse_menu__border_left_color' );    # #CABB94




$templCssRef->{id_unilogo__padding_right} =  37 + $AusgleichsPixel;
$templCssRef->{id_trailer__left}          = 250 + $AusgleichsPixel;
$templCssRef->{ul_booklist__margin_left}  = 228 + $AusgleichsPixel;
$templCssRef->{id_navirahmen__width}      = 248 + $AusgleichsPixel;

# Position des Pfeils für Verkleinern neben Navigation
$templCssRef->{id_collapse_menu__padding_left} =
    7 + int($AusgleichsPixel/2);

# Breite des eingefalteten Navigationsrahmen
# mit Pfeil zum Vergrößern und verkleinern
$templCssRef->{gesamt_navirahmen__width} =
    34 + $AusgleichsPixel;

# Breite des eingefalteten Navigationsrahmen
# mit Pfeil zum Vergrößern und verkleinern
$templCssRef->{gesamt_navirahmen_folded__width} =
    36 + $AusgleichsPixel;

# Breite des eingefalteten Navigationsrahmen
# mit Pfeil zum Vergrößern und verkleinern
$templCssRef->{bei_fixed_und_unfolded_id_collapse_menu__width} =
    18 + int($AusgleichsPixel/2);


# Breite des eingefalteten Navigationsrahmen
# mit Pfeil zum Vergrößern und verkleinern
$templCssRef->{bei_fixed_und_folded_id_collapse_menu__width} =
    21 + int($AusgleichsPixel/2);

# Breite des eingefalteten Navigationsrahmen
# mit Pfeil zum Vergrößern und verkleinern
$templCssRef->{bei_fixed_id_collapse_menu__width} =
    21 + int($AusgleichsPixel/2);



# Breite des eingefalteten Navigationsrahmen
# mit Pfeil zum Vergrößern und verkleinern
$templCssRef->{bei_fixed_und_unfolded_ul_booklist_li_anfang__left} =
    252 + $AusgleichsPixel;


# Linke Position des Anfangs des Regals
$templCssRef->{li_anfang_folded_fixed__left} =
    40 + $AusgleichsPixel;

# Linke Position des Anfangs des Regals
$templCssRef->{li_anfang_fixed__left} =
    40 + $AusgleichsPixel;


# berechung der Regalhoehen
#my $GesamtRegalHoehe = 980;
# 980
my $GesamtRegalHoehe = $cfg->val( 'CSS', 'GesamtRegalHoehe' );
my $nHoeheRegalReihe = $GesamtRegalHoehe / $nAnzahlReihen;

# bisher 245
$templCssRef->{ul_booklist__height} = $nHoeheRegalReihe;

# Grafik für linken Abschluss des Regals
$templCssRef->{Regal_Grafik_Anfang__background} =
    $cfg->val( 'CSS', 'regal_grafik_anfang__background' );
$templCssRef->{Regal_Grafik_Abschluss__background} =
    $cfg->val( 'CSS', 'regal_grafik_abschluss__background' );
$templCssRef->{Regal_Grafik_Mitte__background} =
    $cfg->val( 'CSS', 'regal_grafik_mitte__background' );


my $Regalboden_vorderkante__height = 5;

# bisher 250
$templCssRef->{ul_booklist_li__height} =
    $templCssRef->{ul_booklist__height} +
    $Regalboden_vorderkante__height;

# bisher 240
$templCssRef->{ul_booklist_li__line_height} =
    $templCssRef->{ul_booklist__height} -
    $Regalboden_vorderkante__height;

# 41;
my $QRBreite =
    $cfg->val( 'CSS', 'QRBreite' );

# ausgangspunkt war 200;
my $MediumGesamtBreite =
    $cfg->val( 'CSS', 'MediumGesamtBreite' );


my $CoverVonUnterkante = 24;
my $CoverVonOberkante = 16;

my $nCoverHoehe =
    $templCssRef->{ul_booklist_li__line_height} -
    $CoverVonUnterkante -
    $CoverVonOberkante;

$templCssRef->{cover_hoehe} = $nCoverHoehe;



# bisher 200
$templCssRef->{ul_booklist_li__width} = $MediumGesamtBreite;

$templCssRef->{cover_breite} = int($MediumGesamtBreite - $QRBreite - 16);


$templCssRef->{qr_breite} = $QRBreite;
$templCssRef->{qr_hoehe} = $templCssRef->{qr_breite};


$templCssRef->{ohne_cover_shelf_image_title__font_size} =
    $cfg->val( 'CSS', 'ohne_cover_shelf_image_title__font_size' );
$templCssRef->{ohne_cover_shelf_image_subtitle__font_size} =
    $cfg->val( 'CSS', 'ohne_cover_shelf_image_subtitle__font_size' );
$templCssRef->{ohne_cover_shelf_image_authors__font_size} =
    $cfg->val( 'CSS', 'ohne_cover_shelf_image_authors__font_size' );

$templCssRef->{ohne_cover_shelf_image_substitute__color} =
    $cfg->val( 'CSS', 'ohne_cover_shelf_image_substitute__color' );


# Header-Breich
$templCssRef->{header_hoehe} =
    $cfg->val( 'CSS', 'header_hoehe' );



############################################
# CSS-Angaben und abhängige Werte
# auslesen und berechnen
# Ende
############################################


LeseQuellDaten( \*SOURCEPRINT,
                \%MedienDaten,
                $SearchLinkBase,
                $PfadQRCodeBase,
                \%PrintTitel,
                $nCoverHoehe,
                $htmlpath);

print STATISTIK "\n"x3;
print STATISTIK "-"x60 . "\n";
print STATISTIK "\teBooks\n";
print STATISTIK "-"x60 . "\n";
LeseQuellDaten( \*SOURCEEBOOK,
                \%MedienDaten,
                $SearchLinkBase,
                $PfadQRCodeBase,
                \%PrintTitel,
                $nCoverHoehe,
                $htmlpath);

close STATISTIK;


my @BuchObjekte;
my %FachBuchObjekte;
my @BuchObjekteOhneSubstitution;


my $AnzahlMedien            = keys(%MedienDaten);
my $hyphenator              = new HTML::Hyphenate();
$hyphenator->default_lang('de-de');
$hyphenator->min_pre(3);
$hyphenator->min_post(3);
$hyphenator->style('german');

my $nTempIndex              = 0; # nur wg. Debugabbruch gesetzt

# Für Tests
if ($debug) {
    foreach my $akt (sort {
                        $MedienDaten{$a}->{'RVK-1-buchstabe'} cmp
                            $MedienDaten{$b}->{'RVK-1-buchstabe'}||
                        $MedienDaten{$a}->{'RVK-2-feingruppe'} <=>
                            $MedienDaten{$b}->{'RVK-2-feingruppe'}||
                        $MedienDaten{$a}->{'RVK-3a-cutter1_buchstabe'} cmp
                            $MedienDaten{$b}->{'RVK-3a-cutter1_buchstabe'}||
                        $MedienDaten{$a}->{'RVK-3b-cutter1_zahl'} <=>
                            $MedienDaten{$b}->{'RVK-3b-cutter1_zahl'}||
                        length($MedienDaten{$a}->{sortSignatur}) <=>
                            length($MedienDaten{$b}->{sortSignatur}) ||
                        $MedienDaten{$a}->{sortSignatur} cmp
                            $MedienDaten{$b}->{sortSignatur} ||
                        $MedienDaten{$a}->{sortTitle} cmp
                            $MedienDaten{$b}->{sortTitle} ||
                        $MedienDaten{$a}->{aufl} cmp
                            $MedienDaten{$b}->{aufl} ||
                        $MedienDaten{$a}->{ebook} cmp
                            $MedienDaten{$b}->{ebook}
                      } (keys( %MedienDaten))) {

        print ERRORLOG __LINE__ . " " . $akt . "\t" . "'";
        print ERRORLOG $MedienDaten{$akt}->{'RVK-1-buchstabe'} . "'\t'";
        print ERRORLOG $MedienDaten{$akt}->{'RVK-2-feingruppe'} . "'\t'";
        print ERRORLOG $MedienDaten{$akt}->{'RVK-3a-cutter1_buchstabe'} . "'\t'";
        print ERRORLOG $MedienDaten{$akt}->{'RVK-3b-cutter1_zahl'} . "'\t'";
        print ERRORLOG length($MedienDaten{$akt}->{'sortSignatur'}) . "'\t'";
        print ERRORLOG $MedienDaten{$akt}->{'sortSignatur'} . "'\t'";
        print ERRORLOG $MedienDaten{$akt}->{'sortTitle'} . "'\t'";
        print ERRORLOG $MedienDaten{$akt}->{'aufl'} . "'\t'";
        print ERRORLOG $MedienDaten{$akt}->{'ebook'} . "'\n";

    };
    print ERRORLOG "-"x60, "\n";
};

#-------------------------------------------------------------------------------
# Convert to Template-Structure
#-------------------------------------------------------------------------------
# Sortierung nach Signatur und Titel
#-------------------------------------------------------------------------------
foreach my $akt (sort {
                        $MedienDaten{$a}->{'RVK-1-buchstabe'} cmp
                            $MedienDaten{$b}->{'RVK-1-buchstabe'}||
                        $MedienDaten{$a}->{'RVK-2-feingruppe'} <=>
                            $MedienDaten{$b}->{'RVK-2-feingruppe'}||
                        $MedienDaten{$a}->{'RVK-3a-cutter1_buchstabe'} cmp
                            $MedienDaten{$b}->{'RVK-3a-cutter1_buchstabe'}||
                        $MedienDaten{$a}->{'RVK-3b-cutter1_zahl'} <=>
                            $MedienDaten{$b}->{'RVK-3b-cutter1_zahl'}||
                        length($MedienDaten{$a}->{sortSignatur}) <=>
                            length($MedienDaten{$b}->{sortSignatur}) ||
                        $MedienDaten{$a}->{sortSignatur} cmp
                            $MedienDaten{$b}->{sortSignatur} ||
                        $MedienDaten{$a}->{sortTitle} cmp
                            $MedienDaten{$b}->{sortTitle} ||
                        $MedienDaten{$a}->{aufl} cmp
                            $MedienDaten{$b}->{aufl} ||
                        $MedienDaten{$a}->{ebook} cmp
                            $MedienDaten{$b}->{ebook}
                      } (keys( %MedienDaten))) {

    $nTempIndex++;


    my $SubTitle    =  '';
    if (defined($MedienDaten{$akt}->{untertitel}) and
       ($MedienDaten{$akt}->{untertitel} ne "")) {

        $SubTitle    =  encode_utf8($MedienDaten{$akt}->{untertitel});

    } elsif (defined($MedienDaten{$akt}->{subtitle}) and
            ($MedienDaten{$akt}->{subtitle} ne "")) {

        $SubTitle    =  encode_utf8($MedienDaten{$akt}->{subtitle});

    };

    my $Authors     =  '';
    if (defined($MedienDaten{$akt}->{authors}) and
        ($MedienDaten{$akt}->{authors} ne "")) {

        $Authors    =  encode_utf8($MedienDaten{$akt}->{authors});

    } elsif (defined($MedienDaten{$akt}->{author}) and
            ($MedienDaten{$akt}->{author} ne "")) {

        $Authors    =  encode_utf8($MedienDaten{$akt}->{authors});

    };

    my $lAmazon     = $wahr;
    if (!defined($MedienDaten{$akt}->{isbn}) or
        ($MedienDaten{$akt}->{isbn} eq "")) {
        #-------------------------------------------------------
        # keine pruefung auf Cover bei Amazon wenn isbn leer
        # oder nicht definiert ist
        #-------------------------------------------------------
        $lAmazon     = $falsch;
    }

    my $lGrafik                 = $wahr;
    my $cGrafikName             = '';
    my $cGrafikNameWeb          = '';
    my $GrafikMtime             = '';
    my $lThumbnail              = $falsch;
    my $cThumbnailImageName     = '';
    my $cThumbnailImageNameWeb  = '';
    my $ThumbnailMtime          = '';


    if (!defined($MedienDaten{$akt}->{grafik}) or
        ($MedienDaten{$akt}->{grafik} eq "")) {

        $lGrafik        = $falsch;

    } else {

        $cGrafikName    = $MedienDaten{$akt}->{grafik};
        $cGrafikNameWeb = $MedienDaten{$akt}->{grafik_web};
        $GrafikMtime    = $MedienDaten{$akt}->{grafiktime};

    }

    if (!defined($MedienDaten{$akt}->{thumbnail}) or
        ($MedienDaten{$akt}->{thumbnail} eq "")) {

        $lThumbnail     = $falsch;

    } else {
        $lThumbnail     = $MedienDaten{$akt}->{thumbnail};

        if ($lThumbnail) {
            $cThumbnailImageName    = $MedienDaten{$akt}->{thumbnailgrafik};
            $cThumbnailImageNameWeb = $MedienDaten{$akt}->{thumbnailgrafik_web};
            $ThumbnailMtime         = $MedienDaten{$akt}->{thumbnailtime};
        }
    }

    my $cAlternativeURL    = "";
    if ($MedienDaten{$akt}->{ebook}){
        $cAlternativeURL     = $MedienDaten{$akt}->{URL};
    }


    #-----------------------------------------------
    # Fach für Ausgabe auf Webseite zusammensetzen
    #-----------------------------------------------
    my $aktFaecher  = '';
    foreach my $aktF (@{$MedienDaten{$akt}->{fach}}) {
        if ($aktFaecher eq '') {
            $aktFaecher = $aktF;
        } else {
            $aktFaecher .= ', ' . $aktF;
        }
    }

    #----------------------------------------------------------
    # Sprache wg. sprachspezifischen Trennzeichen speichern
    #----------------------------------------------------------
    if (defined($MedienDaten{$akt}->{sprache})
        and ($MedienDaten{$akt}->{sprache} eq 'eng')) {

        $hyphenator->default_lang('en-us');

    } elsif (defined($MedienDaten{$akt}->{sprache})
        and ($MedienDaten{$akt}->{sprache} eq 'ger')) {

        $hyphenator->default_lang('de-de');

    } else {

        $hyphenator->default_lang('de-de');

    }

    my $aktHash = {
        title               => encode_utf8($MedienDaten{$akt}->{title}),
        titleHTML           => encode_utf8($hyphenator->hyphenated($MedienDaten{$akt}->{title})),
        subtitle            => $SubTitle,
        isbn                => $MedienDaten{$akt}->{isbn},
        alephid             => $MedienDaten{$akt}->{alephid},
        jahr                => $MedienDaten{$akt}->{jahr},
        fach                => $aktFaecher,
        amazon              => $lAmazon,
        authors             => $Authors,
        color               => $MedienDaten{$akt}->{color},
        grafikname          => $cGrafikName,
        grafikname_web      => $cGrafikNameWeb,
        grafiktime          => $GrafikMtime,
        lThumbnail          => $lThumbnail,
        thumbnailgrafik     => $cThumbnailImageName,
        thumbnailgrafik_web => $cThumbnailImageNameWeb,
        thumbnailtime       => $ThumbnailMtime,
        qrcode              => $MedienDaten{$akt}->{qrcode},
        URL                 => $cAlternativeURL,
        print               => $MedienDaten{$akt}->{print},
        ebook               => $MedienDaten{$akt}->{ebook},
        signatur            => $MedienDaten{$akt}->{signatur},
        sortsignatur        => $MedienDaten{$akt}->{sortSignatur},
        dummy               => $falsch
    };

    push( @BuchObjekte, $aktHash );

    foreach my $aktFach (@{$MedienDaten{$akt}->{fach}}) {
        $templ_ref->{'fach' . $aktFach} = $wahr;
        push( @{$FachBuchObjekte{ $aktFach }->{'daten'}}, $aktHash);
        $FachBuchObjekte{ $aktFach }->{'anzahl'}++;
    }




    if ($lAmazon) {
        push( @BuchObjekteOhneSubstitution, {
                    title       => encode_utf8($MedienDaten{$akt}->{title}),
                    subtitle    => $SubTitle,
                    isbn        => $MedienDaten{$akt}->{isbn},
                    alephid     => $MedienDaten{$akt}->{alephid},
                    amazon      => $lAmazon,
                    authors     => $Authors,
                    color       => $MedienDaten{$akt}->{color},
                } );
    }
};

$templ_ref->{BuchObjekte} = \@BuchObjekte;


#-------------------------------------------------------------------------------
# Stuktur für die Navigation erzeugen
#-------------------------------------------------------------------------------
my %Navigation          = ();
my @NavigationObjekte   = ();
foreach my $aktFachKey (keys( %FachBuchObjekte )) {
    my $cFachText   = $cfg->val( 'NAVIGATION', $aktFachKey );
    $Navigation{ $aktFachKey }->{'text'} = $cFachText;
}

foreach my $Key (sort {$Navigation{$a}->{'text'} cmp $Navigation{$b}->{'text'}}
    (keys( %Navigation ))) {
    push( @NavigationObjekte, {
                        title      => $Navigation{ $Key }->{'text'},
                        fach       => $Key,
                    } );
}
$templ_ref->{NavigationsObjekte}    = \@NavigationObjekte;


call_templateHtml(  $templ_ref,
                    'index',
                    $htmlpath . '/' . $html,
                    $AnzahlMedien,
                    $wahr,
                    $nAnzahlReihen,
                    $AusgleichsPixel,
                    $templCssRef->{ul_booklist_li__width});

if ($lMitGestensteuerung) {
    $templ_ref->{gesten}                = $wahr;
    $templ_ref->{index}                 = $html_g;

    call_templateHtml(  $templ_ref,
                        'index',
                        $htmlpath . '/' . $html_g,
                        $AnzahlMedien,
                        $falsch,
                        $nAnzahlReihen,
                        $AusgleichsPixel,
                        $templCssRef->{ul_booklist_li__width});
}
$templ_ref->{gesten}                = $falsch;
$templ_ref->{index}                 = $html;

$templ_ref->{BuchObjekte}           = \@BuchObjekteOhneSubstitution;

$templ_ref->{gesten}                = $falsch;



#-------------------------------------------------------------------------------
# jetzt die weiteren Arrays abarbeiten und für diese die HTML-Dateien erzeugen
#-------------------------------------------------------------------------------
foreach my $aktFachKey (keys( %FachBuchObjekte )) {
    print "-"x40 . "\n";
    print "Erzeuge jetzt FachHTML fuer " . $aktFachKey . "\n";
    print "-"x40 . "\n";
    ErzeugeFachHtml(
                    $templ_ref,
                    $aktFachKey,
                    $htmlpath . '/' . $aktFachKey . '.html',
                    \@{$FachBuchObjekte{ $aktFachKey }->{'daten'}},
                    $wahr,
                    $FachBuchObjekte{ $aktFachKey }->{'anzahl'},
                    $nAnzahlReihen,
                    $AusgleichsPixel,
                    $templCssRef->{ul_booklist_li__width}
                   );
}


if ($lMitGestensteuerung) {
    $templ_ref->{gesten}    = $wahr;
    $templ_ref->{index}     = $html_g;

    #------------------------------------------------------------
    # Jetzt die Version für den Gestensteuerungsbildschirm
    # jetzt die weiteren Arrays abarbeiten und für diese die
    # HTML-Dateien erzeugen
    #------------------------------------------------------------
    foreach my $aktFachKey (keys( %FachBuchObjekte )) {
        print "-"x55 . "\n";
        print "Erzeuge jetzt Gestensteuerungs-FachHTML fuer " .
                $aktFachKey . "\n";
        print "-"x55 . "\n";
        ErzeugeFachHtml(
                        $templ_ref,
                        $aktFachKey,
                        $htmlpath . '/' . $aktFachKey . 'g.html',
                        \@{$FachBuchObjekte{ $aktFachKey }->{'daten'}},
                        $falsch,
                        $FachBuchObjekte{ $aktFachKey }->{'anzahl'},
                        $nAnzahlReihen,
                        $AusgleichsPixel,
                        $templCssRef->{ul_booklist_li__width}
                        );
    }
}


print "-"x40 . "\n";
print "Erzeuge jetzt CSS-Datei\n";
print "-"x40 . "\n";

$templCssRef->{index}   = $html;
my $cssFile             = "css/booklist_erz.css";

# CSS-Datei jetzt auch erzeugen, dadurch sind berechnete Werte übernehmbar
call_templateCSS(
                    $templCssRef,
                    $htmlpath . '/' . $cssFile,
                    $nAnzahlReihen);



#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
sub ErzeugeFachHtml {
    my $templ_ref       = shift();  # 1
    my $fach            = shift();  # 2
    my $html            = shift();  # 3
    my $BuchArray       = shift();  # 4
    my $lNormal         = shift();  # 5
    my $nAnzahlMedien   = shift();  # 6
    my $nAnzahlReihen   = shift();  # 7
    my $AusgleichsPixel = shift();  # 8
    my $nBreiteBuch     = shift();  # 9

    my $bodyid          = 'fach' . $fach;

    if (@{$BuchArray}) {
        $templ_ref->{BuchObjekte}   = \@{$BuchArray};
        call_templateHtml(
                            $templ_ref,
                            $bodyid,
                            $html,
                            $nAnzahlMedien,
                            $lNormal,
                            $nAnzahlReihen,
                            $AusgleichsPixel,
                            $nBreiteBuch );
    };
}

#-------------------------------------------------------------------------------
sub call_templateHtml {

    my $list_ref        = shift();  # 1
    my $bodyid          = shift();  # 2
    my $outfile         = shift();  # 3
    my $nAnzahlMedien   = shift();  # 4
    my $lNormal         = shift();  # 5
    my $nAnzahlReihen   = shift();  # 6
    my $AusgleichsPixel = shift();  # 7
    my $nBreiteBuch     = shift();  # 8


    $list_ref->{bodyid}         = $bodyid;

    $list_ref->{AnzahlMedien}   = $nAnzahlMedien;
    $list_ref->{AnzahlReihen}   = $nAnzahlReihen;

    # Diese Zahl muss noch überprüft werden
    my $AnzahlJeReihe           = int($nAnzahlMedien / $nAnzahlReihen);

    #---------------------------------------
    # Sind Bücher übrig in einer 5. Reihe
    #---------------------------------------
    my $Rest                    = $nAnzahlMedien;
    $Rest                       %= $nAnzahlReihen;

    if ($Rest > 0) {

        print ERRORLOG "\n" . __LINE__ . " \$bodyid: " .
            $bodyid . ": " . $Rest . "\n" if ($debug);
        $AnzahlJeReihe++;

        #-----------------------------------------------------------------------
        # Berechnung der Anzahl der Medien die als Dummies aufgefuellt werden
        # muessen
        #-----------------------------------------------------------------------
        my $nSollMedien = $AnzahlJeReihe * $nAnzahlReihen;
        my $nDiff       = $nSollMedien - $nAnzahlMedien;
        if ($debug) {
            print ERRORLOG __LINE__ . " \$bodyid: " . $bodyid .
                ": \$nAnzahlMedien: " . $nAnzahlMedien . "\n";
            print ERRORLOG __LINE__ . " \$bodyid: " . $bodyid .
                ": \$nSollMedien:   " . $nSollMedien . "\n";
            print ERRORLOG __LINE__ . " \$bodyid: " . $bodyid .
                ": \$AnzahlJeReihe: " . $AnzahlJeReihe . "\n";
            print ERRORLOG __LINE__ . " \$bodyid: " . $bodyid .
                ": \$nDiff:         " . $nDiff . "\n"x2;
        }

        if ($lNormal)
        {
            #--------------------------------------
            # Anzahl der Leerelemente einfuegen
            #--------------------------------------
            my $nIndexLokal = 0;
            for ($nIndexLokal = 0;
                    $nIndexLokal < $nDiff;
                    $nIndexLokal++ ) {

                if ($debug) {
                    print ERRORLOG "\t$bodyid: Durchlauf '" .
                        $nIndexLokal . "' von '" . $Rest . "'\n";
                }
                push( @{$templ_ref->{BuchObjekte}}, {
                    title           => $bodyid,
                    alephid         => 0,
                    jahr            => 0,
                    fach            => [0],
                    amazon          => $falsch,
                    authors         => "leer",
                    color           => '0, 0, 0',
                    grafikname      => "",
                    qrcode          => "",
                    dummy           => $wahr
                });
            };
            $list_ref->{AnzahlMedien}   = $nAnzahlMedien;
        };
    }
    $list_ref->{AnzahlJeReihe}  = $AnzahlJeReihe;

    #---------------------------------------------------------------------------
    # Zuschlag von + X ist wg. der Anfang und Endegrafik notwendig
    #---------------------------------------------------------------------------
    #$list_ref->{Breite} = 204 * $AnzahlJeReihe + "123";
    #$list_ref->{Breite} = 200 * $AnzahlJeReihe + "131" + $AusgleichsPixel;
    #---------------------------------------------------------------------------
    # es existiert ein Fehler bei der Breitenberechnung wenn es genau
    # 8 Bücher in einer Reihe sind
    # hier muss ein Ausgleichsfaktor zugeschlagen werden
    #---------------------------------------------------------------------------
    if ($AnzahlJeReihe == 8) {
        # Mit Zusatzfaktor
        $list_ref->{Breite}         = $nBreiteBuch * $AnzahlJeReihe +
                                        "131" + $AusgleichsPixel + 70;
        # ab hier funktioniert es nicht mehr!
        #$list_ref->{Breite}         = $nBreiteBuch * $AnzahlJeReihe
        #                               + "131" + $AusgleichsPixel + 60;
    } else {
        # Normale bisherige Berechnung
        $list_ref->{Breite}         = $nBreiteBuch * $AnzahlJeReihe +
                                        "131" + $AusgleichsPixel;
    }



    my $aktDurchlauf    = 0;
    my @TestArray       = ();
    if ($debug) {
        print __LINE__ . ": TEST \$nAnzahlReihen: " . $nAnzahlReihen . "\n";
    };

    for ($aktDurchlauf = 1; $aktDurchlauf <= $nAnzahlReihen; $aktDurchlauf++) {

        print __LINE__ . " Durchlauf: " . $aktDurchlauf . "\n";
        print __LINE__ . " Durchlauf: " . $aktDurchlauf . ":   " .
                    ($aktDurchlauf * int($nAnzahlMedien / $nAnzahlReihen)) .
                    "\n";
        my $aktNr = {
                        nr           => $aktDurchlauf * $AnzahlJeReihe,
                    };
        push( @TestArray, $aktNr );
    }
    $templ_ref->{DurchlaufObjekte} = \@TestArray;

    my $tt = Template->new({    # Template object
                                ENCODING        => 'utf8',
                                INCLUDE_PATH    => 'template',
                                STAT_TTL        => 60,
                                #STRICT          => 1,
                          }) ;


    print $tt->process('buecherregal.html.tmpl', $list_ref, $outfile) ||
        die $tt->error ;

    my $i = 1 ;
}



#-------------------------------------------------------------------------------
sub call_templateCSS {

    my $list_ref                = shift();  # 1
    my $outfile                 = shift();  # 3
    my $nAnzahlReihen           = shift();  # 6

    $list_ref->{AnzahlReihen}   = $nAnzahlReihen;


    my $tt = Template->new({    # Template object
                                ENCODING        => 'utf8',
                                INCLUDE_PATH    => 'template',
                                STAT_TTL        => 60,
                                #STRICT          => 1,
                          }) ;


    print $tt->process('booklist.css.tmpl', $list_ref, $outfile) ||
        die $tt->error ;

    my $i = 1 ;
}

#-------------------------------------------------------------------------------
#
# Quelldaten einlesen
#
#-------------------------------------------------------------------------------
sub LeseQuellDaten {

    my ($fh)                = shift();          # 1
    my ($MedienDaten)       = shift();          # 2

    # Parameter zur Weitergabe wq QRCode
    my $urlBase             = shift();          # 3
    my $PfadQRCodeBase      = shift();          # 4
    # Parameter zur Weitergabe wq QRCode Ende

    my ($PrintTitel)        = shift();          # 5 neu 2014-03-18, 15:37:42
    my $pCoverHeight        = shift();          # 6 2014-07-01, 09:52:28
    my $htmlpath            = shift();          # 7 2015-03-06, 14:41:10


    my $nIndex              = 0;
    my $nBuchIndex          = 0;
    my %SpaltenIndex        = ();
    my %SpaltenName         = ();
    my %AlephIds            = ();
    my $lEbook              = $falsch;  # wird in der Überschrift erkannt
                                        # daher nicht bei jeder Zeile
                                        # zurücksetzen!
    my %Statistik           = ();
    my $nEbooksUndPrint     = 0;
    my $nEbooksOhnePrint    = 0;

    # zum ermitteln ob es zu einem ebook auch eine gedruckte Ausgabe gibt
    # wenn ja dann diese Variable auf true setzen
    my $lPrintEbook         = $falsch;
    my $nAnzahlMaxSpalten   = 0;


    while(<$fh>) {
        $nIndex++;
        chomp;      # entfernt Platformspezifische CRLF
                    # wenn Datei als binaer uebertragen wurde
                    # bleibt LFCR ansonsten erhalten

        # Falls Datei binaer uebertragen wurde Zeilenende entfernen
        $_ =~ s/(\n|\r|\x0d)//g;

        my $aktZeile    = $_;
        $lPrintEbook    = $falsch;

        #---------------------------------------------------
        # Überspringen von leeren Zeilen in den Quelldaten
        #---------------------------------------------------
        if (length($aktZeile) > 2 ) {

            # Schalter hinzufügen für Alma / Aleph
            #-------------------------------------------------------------------
            # Da die Daten jetzt von Alma via API geholt werden wird dieser
            # Abscnitt nicht mehr benötigt
            #-------------------------------------------------------------------
            #in der URL ist teilweise ein "|" enthalten
            # diesen "|" wird jetzt in seine Hex-Entsprechung
            # umgewandelt (alle Treffer)
            #-------------------------------------------------------------------
            while ($aktZeile =~ m/http[s]{0,1}\:(.*?)\|/) {
                $aktZeile =~ s/http\:(.*?)\|/http:$1%7C/;
                $aktZeile =~ s/https\:(.*?)\|/https:$1%7C/;
            }

            my @AktFelder               = split( /\|/, $aktZeile );
            my %AktSpalten              = ();
            my $nSpalte                 = 0;
            my $lPrintSatzId            = 0;

            my $cCache                  = '';
            my $aktAlephID              = '';
            my $cSpalteOriginalInhalt   = '';
            my $sorttitle               = "";       # bei jedem Buch am Anfang
                                                    # zurücksetzen
            my $lWgFehlerDelete         = $falsch;
            my $lWgFehlerDeleteReport   = $wahr;
            my $cAktSigWStatistikFehler = "";
            my $cKeyPrintBook           = "";

            # wg Fehlersuche eingeschaltet
            #if ($aktZeile =~ m/^001711965(.*?)$/) {
            #    sleep( 1 );
            #};

            # Jede Spalte durchgehen
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

                    # Anzahl der Spalten ermitteln
                    $nAnzahlMaxSpalten++;
                }


                #---------------------------------------------------------------
                # erst ab der ersten Datenzeile die Datensätze einlesen
                #---------------------------------------------------------------
                if ($nIndex > 1) {

                    #-----------------------------------------------------------
                    # Prüfen ob die Anzahl der Spalten in dieser Zeile
                    # kleiner ist wie erwartet
                    #-----------------------------------------------------------
                    my $nAnzahlAktSpalten = @AktFelder;
                    if ($nAnzahlAktSpalten < $nAnzahlMaxSpalten) {
                        # wenn die Anzahl der Spalten kleiner als erwartet ist
                        # muss dieser Datensatz verworfen werden.
                        $lWgFehlerDelete    = $wahr;
                    };

                    # Unbehandelter Origianal-Inhalt der Spalte speichern
                    $cSpalteOriginalInhalt  = $akt;

                    #-----------------------------------------------------------
                    # HTML-Entities erzeugen durch umwandlung von
                    # z.B. \x{02b9} in &#x2b9;
                    # oder \x{12b9} in &#x12b9;
                    #-----------------------------------------------------------
                    while ($akt =~ m/\\x\{/) {
                        if ($akt =~ m/\\x\{0/) {
                            # wenn 0 am Anfang entfernen
                            $akt =~ s/\\x\{([0]{1})([^}]*?)\}/&#x$2\;/;
                        }
                        else  {
                            # Alle Zeichen übernehmen
                            $akt =~ s/\\x\{([^}]*?)\}/&#x$1\;/;
                        };
                    };


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
                        # mehrere Fächerzuordnungen hat, in diesem Fall ist es
                        # ok
                        #-------------------------------------------------------
                        #$aktAlephID = 'MAN_ALEPH' . $akt;
                        $aktAlephID = $cAlephIDVorspann . $akt;

                        $AlephIds{ $aktAlephID }++;
                        $Statistik{'fachgesamt'}{'medien'}++;

                        #-------------------------------------------------------
                        # von jeder AlephID nur ein Buch eintragen
                        # aber verschiedene Daten abgleichen
                        # aktuell das Fach
                        #-------------------------------------------------------
                        if ($AlephIds{ $aktAlephID } < 2) {
                            # Index der Bücher hochzählen, z.B. wg. Mengentest
                            $nBuchIndex++;
                            if (!$lEbook) {
                                print "print: ";
                            } else {
                                print "ebook: ";
                            };

                            print $nBuchIndex . "\t";
                            print $aktAlephID . "\t";
                            #if ($nBuchIndex == 323) {
                            #    sleep( 3 );
                            #};

                            # Für Testphase abbruchbedingung setzen
                            #last if $nBuchIndex > 30;

                            ${$MedienDaten}{$aktAlephID} =
                                {alephid => $aktAlephID};

                            # Typ der Resource vermerken
                            if ($lEbook) {
                                ${$MedienDaten}{$aktAlephID}->{print} = $falsch;
                                ${$MedienDaten}{$aktAlephID}->{ebook} = $wahr;
                            } else {
                                ${$MedienDaten}{$aktAlephID}->{print} = $wahr;
                                ${$MedienDaten}{$aktAlephID}->{ebook} = $falsch;
                            }


                            # Jetzt vorher erzeugten QR-Code verwenden, wg.
                            # Problme mit Modul!
                             my $QrGrafikName =
                                PruefeQRCodeFile(   $urlBase,
                                                    $aktAlephID,
                                                    $PfadQRCodeBase);
                            ${$MedienDaten}{$aktAlephID}->{qrcode} =
                                $QrGrafikName;

                            #----------------------------------------
                            # Farbberechnung für Bücher ohne  isbn
                            #----------------------------------------
                            my ($red, $green, $blue) = map int rand 255, 1 .. 3;
                            ${$MedienDaten}{$aktAlephID}->{color}   =
                                $red . ", " . $green . ", " . $blue;


                        } else {
                            print ERRORLOG "DOPPELTE ID gefunden bei " .
                                $aktAlephID . "\t" . $AlephIds{ $aktAlephID } .
                                "\n";
                            # bis 2014-03-05, 07:58:36 Abbruchbedingung
                            # ab jetzt soll weiteres Fach gespeichert werden
                            #last;
                        }
                    }
                    #-----------------------------------------------------------
                    elsif (     ($SpaltenName{ $nSpalte } eq 'Autor')
                            and ($AlephIds{ $aktAlephID } < 2)){
                        if ($akt ne '') {

                            my $authors = decode_utf8($akt);

                            #if ($authors eq 'Dahlheim, Werner'|| $authors eq 'Adams, Gabriele') {
                            #    sleep(1);
                            #};
                            my @Teile = split( /,/, $authors);
                            if ($#Teile > 0) {
                                $Teile[0] =~ s/^(.*?)\s$/$1/g;
                                $Teile[0] =~ s/^\s(.*?)$/$1/g;
                                $Teile[1] =~ s/^\s(.*?)$/$1/g;
                                $authors = $Teile[1] . ' ' . $Teile[0];
                            }

                            ${$MedienDaten}{$aktAlephID}->{authors} = $authors;
                        }
                        #else {
                        #    print "AUTHOR ist leer\n";
                        #}
                    }
                    #-----------------------------------------------------------
                    elsif (     ($SpaltenName{ $nSpalte } eq 'Titel')
                            and ($AlephIds{ $aktAlephID } < 2)){

                        my $title       = decode_utf8($akt);
                        my $untertitel  = '';
                        if ($title =~ m/:/) {
                            my @Teile = split( /:/, $title );
                            $title      = $Teile[0];
                            $untertitel = $Teile[1];

                            $title =~ s/^(.*?)\s$/$1/g;
                            $title =~ s/^\s(.*?)$/$1/g;
                            $untertitel =~ s/^\s(.*?)$/$1/g;
                        };

                        $title    =~ s/://g;
                        if ($title eq '') {
                            # wg. eines fehlers in unserem SQL mit dem wir in
                            # der UB Mannheim die Datensätze abfragen bleiben
                            # gelöschte Titel in der Ergebnismenge
                            # diese sind an dem leeren Verfasser und Titelfeld
                            # erkennbar
                            # diese Titel können kommentarlos aus der
                            # Liste entfernt werden
                            $title = '-~-';
                            $lWgFehlerDelete         = $wahr;
                            $lWgFehlerDeleteReport   = $falsch;

                        };

                        ${$MedienDaten}{$aktAlephID}->{title} = $title;

                        #-------------------------------------------------------
                        # Titel umwandeln damit er korrekt sortiert wird
                        #-------------------------------------------------------
                        $sorttitle   = $title;


                        if ($debug) {
                            if ($aktAlephID eq 'MAN_ALEPH001521227') {
                                ${$MedienDaten}{$aktAlephID}->{title}   =
                                $sorttitle;
                                sleep( 1 );
                            }
                        };
                        $sorttitle      = lc($sorttitle);
                        $sorttitle      =~ s/\"//g;
                        $sorttitle      =~ s/\(//g;
                        $sorttitle      =~ s/\)//g;
                        $sorttitle      =~ s/\[//g;
                        $sorttitle      =~ s/\]//g;
                        $sorttitle      =~ s/ö/oe/g;
                        $sorttitle      =~ s/Ö/Oe/g;
                        $sorttitle      =~ s/ä/ae/g;
                        $sorttitle      =~ s/Ä/Ae/g;
                        $sorttitle      =~ s/ü/ue/g;
                        $sorttitle      =~ s/Ü/Ue/g;
                        $sorttitle      =~ s/ß/ss/g;
                        $sorttitle      =~ s/¬//g;
                        $sorttitle      =~ s/é/e/g;
                        ${$MedienDaten}{$aktAlephID}->{sortTitle} = $sorttitle;

                        if ($untertitel) {
                            ${$MedienDaten}{$aktAlephID}->{untertitel} =
                                $untertitel;
                        }


                        # Ermitteln ob ein eBook mit einem Print-Exemplar
                        # identisch ist
                        # hierzu einige Daten speichern und vergleichen
                        # da jetzt auch das Jahr einbezogen werden soll wird
                        # dieser Teil verschoben
                    }
                    #elsif ($SpaltenName{ $nSpalte } eq 'Aufl.') {
                    #    if ($akt ne '') {
                    #        print $akt . "\n";
                    #    }
                    #    else {
                    #        print "AUFLAGE ist leer\n";
                    #    }
                    #}
                    #-----------------------------------------------------------
                    elsif (     ($SpaltenName{ $nSpalte } eq 'ISBN')
                            and ($AlephIds{ $aktAlephID } < 2)){
                        my $cIsbnOri    = $akt;
                        # ISBN - entfernen
                        $akt =~ s/-//g;
                        my $cIsbn       = $akt;
                        #${$MedienDaten}{$aktAlephID}->{isbn} = $cIsbn;

                        my $lIsbnPrint  = $falsch;
                        my $lCover;
                        my $cGrafikName;
                        my $cGrafikNameWeb;
                        my $lCache;
                        my $ImageMtime;
                        my $lThumbnail;
                        my $cThumbnailImageName;
                        my $cThumbnailImageNameWeb;
                        my $ThumbnailMtime;

                        # Länge der ISBN pruefen
                        # bei der aktuellen Amazon-Schnittstelle sind wohl
                        # nur 10-stellige ISBNs moeglich
                        # daher ggf. ISBN in 10 Stellige umwandeln

                        if (length($cIsbn) == 13) {
                            # 13 digit ISBNs
                            my $isbn13  = Business::ISBN->new($cIsbnOri);
                            my $isbn10  = $isbn13->as_isbn10;   # Convert
                            $cIsbn      = $isbn10->isbn;
                            #print ERRORLOG __LINE__ . " Konvertiere $cIsbnOri zu $cIsbn\n";
                        };


                        # bei Amazon prüfen ob ein Cover heruntergeholt
                        # werden kann
                        # 1. Liegt das Cover schon vor (gecached)
                        # 2. Wurde das Cover schon einmal geprüft
                        # 3. Ist das Cover abrufbar
                        # wenn nicht 1 oder 2 dann keine ISBN ausgeben,
                        # ev. als irgendwas damit Suche in Aleph möglich ist
                        if (!exists($KeineTrefferCache{$cIsbn})) {
                            # Prüfe auf die eigene isbn
                            ($lCover,
                                $cGrafikName,
                                $cGrafikNameWeb,
                                $lCache,
                                $ImageMtime,
                                $lThumbnail,
                                $cThumbnailImageName,
                                $cThumbnailImageNameWeb,
                                $ThumbnailMtime)  =
                                PruefeCover( $cIsbn, $pCoverHeight, $htmlpath );


                            if ($lCover) {
                                ${$MedienDaten}{$aktAlephID}->{isbn} = $cIsbn;
                                ${$MedienDaten}{$aktAlephID}->{grafik} =
                                    $cGrafikName;
                                ${$MedienDaten}{$aktAlephID}->{grafik_web} =
                                    $cGrafikNameWeb;
                                ${$MedienDaten}{$aktAlephID}->{grafiktime} =
                                    $ImageMtime;
                                if ($lCache) {
                                    print "gecached";
                                }

                                ${$MedienDaten}{$aktAlephID}->{thumbnail} =
                                    $lThumbnail;
                                if ($lThumbnail) {
                                    ${$MedienDaten}{$aktAlephID}->{thumbnailgrafik} =
                                        $cThumbnailImageName;
                                    ${$MedienDaten}{$aktAlephID}->{thumbnailgrafik_web} =
                                        $cThumbnailImageNameWeb;
                                    ${$MedienDaten}{$aktAlephID}->{thumbnailtime} =
                                        $ThumbnailMtime;
                                }
                            }
                            else
                            {
                                print ERRORLOG '  ' . 'isbn ohne Grafik ' .
                                    $cIsbn . "\n";
                                print "kein IMAGE";
                                $KeineTrefferCache{ $cIsbn } = $cIsbn;
                            };
                        }

                        # gab es ein Cover
                        # wenn nein dann auch noch prüfen ob es ev. mit dem
                        # cover des print-Mediums klappt

                        # gibt es kein Cover dann ggf. nachsehen ob beim
                        # zugehoerigen Buch
                        if (!$lCover) {
                            if ($lEbook) {

                                # pruefen ob von dem eBook auch ein Print vorliegt
                                if (exists(${$PrintTitel}{$cKeyPrintBook})) {
                                    my $PrintAlephId    =
                                        ${$PrintTitel}{$cKeyPrintBook}{'alephid'};

                                    #if (!defined($PrintAlephId)) {
                                    #    sleep(1);
                                    #}


                                    if (exists(${$MedienDaten}{$PrintAlephId})) {

                                        my $cPrintIsbn  = "";

                                        if (${$MedienDaten}{$PrintAlephId}) {
                                            if (defined(${$MedienDaten}{$PrintAlephId}->{isbn})) {
                                                $cPrintIsbn = ${$MedienDaten}{$PrintAlephId}->{isbn};
                                            } else {
                                                $cPrintIsbn = "";
                                            }
                                        }

                                        #print ERRORLOG __LINE__ . " " . $PrintAlephId . " " ;
                                        #print ERRORLOG ${$MedienDaten}{$PrintAlephId}->{'isbn'} . "\n";
                                        if ($cPrintIsbn ne "") {
                                            if (!exists($KeineTrefferCache{$cPrintIsbn})) {

                                                # Jetzt prüfen ob eine Thumbnail für
                                                # dieses Buch vorliegt
                                                # dann dieses verwenden
                                                #my $PrintColor      =
                                                #    ${$MedienDaten}{$PrintAlephId}->{color};
                                                #${$MedienDaten}{$aktAlephID}->{color} =
                                                #    $PrintColor;

                                                ($lCover,
                                                    $cGrafikName,
                                                    $cGrafikNameWeb,
                                                    $lCache,
                                                    $ImageMtime,
                                                    $lThumbnail,
                                                    $cThumbnailImageName,
                                                    $cThumbnailImageNameWeb,
                                                    $ThumbnailMtime)  =
                                                    PruefeCover( ${$MedienDaten}{$PrintAlephId}->{isbn}, $pCoverHeight, $htmlpath );
                                                if ($lCover) {
                                                    $lIsbnPrint = $wahr;
                                                    $cIsbn      = ${$MedienDaten}{$PrintAlephId}->{isbn};
                                                }

                                                if ($lCover) {
                                                    ${$MedienDaten}{$aktAlephID}->{isbn} = $cIsbn;
                                                    ${$MedienDaten}{$aktAlephID}->{grafik} =
                                                        $cGrafikName;
                                                    ${$MedienDaten}{$aktAlephID}->{grafik_web} =
                                                        $cGrafikNameWeb;
                                                    ${$MedienDaten}{$aktAlephID}->{grafiktime} =
                                                        $ImageMtime;
                                                    if ($lCache) {
                                                        print "gecached";
                                                    }

                                                    ${$MedienDaten}{$aktAlephID}->{thumbnail} =
                                                        $lThumbnail;
                                                    if ($lThumbnail) {
                                                        ${$MedienDaten}{$aktAlephID}->{thumbnailgrafik} =
                                                            $cThumbnailImageName;
                                                        ${$MedienDaten}{$aktAlephID}->{thumbnailgrafik_web} =
                                                            $cThumbnailImageNameWeb;
                                                        ${$MedienDaten}{$aktAlephID}->{thumbnailtime} =
                                                            $ThumbnailMtime;
                                                    }
                                                }
                                                else
                                                {
                                                    print ERRORLOG '  ' . 'isbn ohne Grafik ' .
                                                        $cIsbn . "\n";
                                                    print "kein IMAGE";
                                                    $KeineTrefferCache{ $cIsbn } = $cIsbn;
                                                };
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if (!$lCover) {
                            print ERRORLOG '  ' . 'isbn ohne Grafik ' .
                                $cIsbn . "\n";
                            print "kein IMAGE";
                            $KeineTrefferCache{ $cIsbn } = $cIsbn;
                        };


                        ##################################################################################
                        ##################################################################################
                        ##################################################################################
                        ##################################################################################
                        ##################################################################################
                        ##################################################################################
                        ##################################################################################
                        ##################################################################################
                        ##################################################################################
                        ##################################################################################
                        ##################################################################################
                        ##################################################################################
                        if (exists($AlephIds{ $aktAlephID })) {
                            if ($AlephIds{ $aktAlephID } < 2)
                            {
                                print "\n";
                            };
                        };
                    }
                    #-----------------------------------------------------------
                    # In diesem Fall auch die weiteren Treffer untersuchen
                    # also nicht nur wenn and ($AlephIds{ $aktAlephID } < 2)
                    #-----------------------------------------------------------
                    elsif ($SpaltenName{ $nSpalte } eq 'Fach') {
                        if ($akt ne '') {

                            my $fach = $akt;



                            #---------------------------------------------------
                            # eBooks
                            #---------------------------------------------------
                            if ($lEbook) {

                                my $lFach   = $falsch;

                                if ($fach ne '') {
                                        # bei Aleph und in den Beispielen startet dieses Feld (in Mannheim) mit "cofz , text , lb30  BSO ,"
                                        if ($fach =~ m/^cofz(.*?)/) {
                                            #-----------------------------------
                                            # Aleph
                                            #-----------------------------------
                                            my @StatistikArray = split( /\,/, $fach );

                                            foreach my $aktStat (@StatistikArray) {
                                                $aktStat =~ s/^\s//g;
                                                $aktStat =~ s/\s$//g;
                                                if ($aktStat =~ m/^lb(\d\d)/) {
                                                    $fach = $1;
                                                    $lFach   = $wahr;
                                                    if ($fach ne '') {
                                                        $Statistik{'fachgesamt'}{'mitfach'}++;
                                                        $Statistik{'fach'}{$fach}++;
                                                    };
                                                };
                                            }
                                        } else {
                                            #-----------------------------------
                                            # Alma
                                            #-----------------------------------

                                            # New Version now only number
                                            $lFach   = $wahr;

                                            $Statistik{'fachgesamt'}{'mitfach'}++;
                                            $Statistik{'fach'}{$fach}++;
                                        };
                                };

                                if (!$lFach){
                                    $fach   = "";
                                };
                            } else {
                                #-----------------------------------------------
                                # print-Medien
                                #-----------------------------------------------
                                $fach   = $akt;

                                if ($fach ne '') {
                                    $Statistik{'fachgesamt'}{'mitfach'}++;
                                    $Statistik{'fach'}{$fach}++;
                                };
                            }
                            push(@{${$MedienDaten}{$aktAlephID}->{fach}}, $fach);
                        }
                    }
                    #-----------------------------------------------------------
                    elsif (     ($SpaltenName{ $nSpalte } eq 'Jahr')
                            and ($AlephIds{ $aktAlephID } < 2)){
                        if ($akt ne '') {
                            my $aktJahr = $akt;
                            ${$MedienDaten}{$aktAlephID}->{jahr} = $aktJahr;


                            #---------------------------------------------------------------
                            #---------------------------------------------------------------
                            #---------------------------------------------------------------
                            #---------------------------------------------------------------
                            my $aktAuthor = '';
                            if (exists(${$MedienDaten}{$aktAlephID}->{authors})) {
                                $aktAuthor =
                                    lc(${$MedienDaten}{$aktAlephID}->{authors});
                            }
                            #-------------------------------------------------------
                            # untersuchen wieviele LBS-Buecher eine
                            # ebook-Entsprechung haben
                            #-------------------------------------------------------
                            if (!$lEbook) {
                                ${$PrintTitel}{ $aktAuthor . ":" . $sorttitle .
                                    ":" . $aktJahr }{'anzahl'}++;
                                ${$PrintTitel}{ $aktAuthor . ":" . $sorttitle .
                                    ":" . $aktJahr}{'alephid'} = $aktAlephID;
                            } else {
                                #sleep(1);
                                # wenn eBook
                                # Pruefen ob das Ebook ein Treffer bei den Books hat
                                # aktuell wird die Farbe des manuell berechneten
                                # covers übernommen
                                # es soll aber auch das schon geholte Cover
                                # uebernommen werden

                                $cKeyPrintBook = $aktAuthor . ":" .
                                                    $sorttitle . ":" .
                                                    $aktJahr;

                                #if (exists(${$PrintTitel}{  $aktAuthor . ":" .
                                #                            $sorttitle . ":" .
                                #                            $aktJahr })) {
                                if (exists(${$PrintTitel}{ $cKeyPrintBook })) {
                                    print ERRORLOG __LINE__ .
                                        " ebook mit print $aktAlephID " .
                                        "$aktAuthor : $sorttitle\n" if ($debug);
                                    $nEbooksUndPrint++;
                                    $lPrintEbook        = $wahr;
                                    #-------------------------------------------
                                    # In diesem Fall auch die Farbe des
                                    # Print-Exemplars übernehmen hierzu
                                    # benoetige ich die ID.
                                    # Liegt die in dem Hash vor?
                                    #-------------------------------------------
                                    my $PrintAlephId    =
                                        ${$PrintTitel}{$cKeyPrintBook}{'alephid'};
                                        #${$PrintTitel}{ $aktAuthor . ":" .
                                        #                $sorttitle . ":" .
                                        #                $aktJahr }{'alephid'};
                                    my $PrintColor      =
                                        ${$MedienDaten}{$PrintAlephId}->{color};
                                    ${$MedienDaten}{$aktAlephID}->{color} =
                                        $PrintColor;

                                    #-------------------------------------------
                                    # Jetzt die Daten fuer das Cover uebernehmen
                                    #-------------------------------------------

                                    #-------------------------------------------
                                    # Wenn das eBook eine eigene Signatur hat
                                    # werden diese Daten spaeter in der Spalte
                                    # Signatur einfach ueberschrieben
                                    # also dort ggf. auch korrigieren, wenn
                                    # weitere Felder hier manipuliert werden
                                    #-------------------------------------------
                                    ${$MedienDaten}{$aktAlephID}->{sortSignatur} =
                                        ${$MedienDaten}{$PrintAlephId}->{sortSignatur};

                                    ${$MedienDaten}{$aktAlephID}->{'RVK-1-buchstabe'} =
                                        ${$MedienDaten}{$PrintAlephId}->{'RVK-1-buchstabe'};
                                    ${$MedienDaten}{$aktAlephID}->{'RVK-2-feingruppe'} =
                                        ${$MedienDaten}{$PrintAlephId}->{'RVK-2-feingruppe'};
                                    ${$MedienDaten}{$aktAlephID}->{'RVK-3a-cutter1_buchstabe'} =
                                        ${$MedienDaten}{$PrintAlephId}->{'RVK-3a-cutter1_buchstabe'};
                                    ${$MedienDaten}{$aktAlephID}->{'RVK-3b-cutter1_zahl'} =
                                        ${$MedienDaten}{$PrintAlephId}->{'RVK-3b-cutter1_zahl'};

                                    # Fehlerpruefung
                                    if (${$MedienDaten}{$aktAlephID}->{'RVK-1-buchstabe'} eq "") {
                                        print ERRORLOG __LINE__ .
                                            " Fehler RVK-1-buchstabe ist leer\n";
                                    }
                                    if (${$MedienDaten}{$aktAlephID}->{'RVK-2-feingruppe'} eq "") {
                                        print ERRORLOG __LINE__ .
                                            " Fehler RVK-2-feingruppe ist leer\n";
                                    }
                                    if (${$MedienDaten}{$aktAlephID}->{'RVK-3a-cutter1_buchstabe'} eq "") {
                                        print ERRORLOG __LINE__ .
                                            " Fehler RVK-3a-cutter1_buchstabe ist leer\n";
                                    }
                                    if (${$MedienDaten}{$aktAlephID}->{'RVK-3b-cutter1_zahl'} eq "") {
                                        print ERRORLOG __LINE__ .
                                            " Fehler RVK-3b-cutter1_zahl ist leer\n";
                                    }
                                    if (${$MedienDaten}{$aktAlephID}->{'RVK-3b-cutter1_zahl'} =~ /^\d+?$/) {
                                        #print ERRORLOG __LINE__ .
                                        #" Fehler RVK-3b-cutter1_zahl ist leer\n";
                                    } else {
                                        print ERRORLOG __LINE__ .
                                            " Fehler RVK-3b-cutter1_zahl ist keine Zahl\n";
                                    }


                                    #sleep(1);

                                } else {
                                    print ERRORLOG __LINE__ .
                                        " ebook ohne      $aktAlephID " .
                                        "$aktAuthor : $sorttitle\n" if ($debug);
                                    $nEbooksOhnePrint++;
                                }
                            }
                            #---------------------------------------------------------------
                            #---------------------------------------------------------------
                            #---------------------------------------------------------------
                            #---------------------------------------------------------------
                        }
                    }
                    #-----------------------------------------------------------
                    elsif (     ($SpaltenName{ $nSpalte } eq 'URL')
                            and ($AlephIds{ $aktAlephID } < 2)){
                        if ($akt ne '') {
                            ${$MedienDaten}{$aktAlephID}->{URL} = $akt;
                        } else {
                            # Bei leerer URL bei eBooks
                            if ($lEbook) {
                                # Die URL darf nicht leer sein! weil sonst
                                # ein Fehler beim Verlinken passiert, deshalb
                                # muss dieser Datensatz verworfen werden.
                                $lWgFehlerDelete    = $wahr;
                            }
                        }
                    }
                    #-----------------------------------------------------------
                    elsif (     ($SpaltenName{ $nSpalte } eq 'Signatur')
                            and ($AlephIds{ $aktAlephID } < 2)){
                        if ($akt ne '') {
                            my $usersignatur            = $akt;
                            $cAktSigWStatistikFehler    = $usersignatur;
                            my $lRVK                    = $falsch;
                            my $lRVKEbook               = $falsch;

                            #---------------------------------------------------
                            # Nur nicht Ebooks dürfen eine Signatur erhalten
                            # Bei eBooks darf keine Signatur vorhanden sein
                            # sonst wird statt eine 'e'-Icon eine Signatur
                            # angezeigt!
                            #---------------------------------------------------
                            # leer lassen!
                            #${$MedienDaten}{$aktAlephID}->{signatur} =
                            #   $usersignatur;

                            ${$MedienDaten}{$aktAlephID}->{sortSignatur} =
                                $usersignatur;

                            #---------------------------------------------------
                            # wg. Ebooks
                            # (bei denen die ersten drei Zahlen fehlen)
                            # muss die sortSignatur manipuliert werden
                            # hierzu muss die ersten drei Zahlen
                            # inkl. der Leerstelle abgeschnitten werden
                            #---------------------------------------------------
                            if (!$lEbook) {
                                #-----------------------------------------------
                                # Nur nicht Ebooks dürfen eine Signatur erhalten
                                # Bei eBooks darf keine Signatur vorhanden sein
                                # sonst wird statt eine 'e'-Icon eine Signatur
                                # angezeigt!
                                #-----------------------------------------------
                                ${$MedienDaten}{$aktAlephID}->{signatur} =
                                    $usersignatur;

                                my $reduzierteSignatur  = $usersignatur;
                                $reduzierteSignatur =~
                                    m/^
                                        (\d{3})         # 1 3 Zahlen
                                        (\s+)           # 2   Leerzeichen
                                        (.*?)$          # 3   beliebige Zeichen
                                    /x;

                                #-----------------------------------------------
                                # die ersten Zahlen sind hiermit entfernt,
                                # dann können ebooks und print-Medien
                                # gleich sortiert werden
                                #-----------------------------------------------
                                ${$MedienDaten}{$aktAlephID}->{sortSignatur} =
                                    $3;
                            }


                            # die Signatur jetzt zerlegen um sie sortierbar zu
                            # machen

                            if (!$lEbook) {
                                #-----------------------------------------------
                                # Prüfen ob es eine rvk-Signatur sein kann
                                #-----------------------------------------------
                                if ($usersignatur =~
                                    m/^
                                        (\d{3})         # 1 3 Zahlen
                                        (\s+)           # 2   Leerzeichen
                                        ([a-zA-Z]{2})   # 3 2 zwei Buchstaben
                                        (\s+)           # 4   Leerzeichen
                                        (.*?)           # 5   beliebige Zeichen
                                    /x ) {

                                    $lRVK   = $wahr;
                                    print ERRORLOG __LINE__ .
                                        " \$lRVK: '" . $lRVK .
                                        "'\n" if ($debug);
                                }
                            } else {
                                #-----------------------------------------------
                                # Prüfen ob es eine rvk-Signatur eines eBooks
                                # sein kann
                                #-----------------------------------------------
                                # d.h. ohne die drei Zahlen am Anfang und das
                                # Leerzeichen!
                                if ($usersignatur =~
                                    m/^
                                        ([a-zA-Z]{2})   # 1 2 zwei Buchstaben
                                        (\s+)           # 2   Leerzeichen
                                        (.*?)           # 3   beliebige Zeichen
                                    /x ) {
                                    $lRVKEbook  = $wahr;
                                    print ERRORLOG __LINE__ .
                                        " \$lRVKEbook: '" .
                                        $lRVKEbook . "'\n" if ($debug);
                                }
                            }

                            if ($lRVK) {
                                my ($Standort,
                                    $Buchstabe,
                                    $Feingruppe,
                                    $Cutter1_buchstabe,
                                    $Cutter1_zahl,
                                    $rest) =
                                    zerlegeRVKSignatur($usersignatur, $lEbook);

                                #
                                ${$MedienDaten}{$aktAlephID}->{'RVK-1-buchstabe'} =
                                    $Buchstabe;
                                ${$MedienDaten}{$aktAlephID}->{'RVK-2-feingruppe'} =
                                    $Feingruppe;
                                ${$MedienDaten}{$aktAlephID}->{'RVK-3a-cutter1_buchstabe'} =
                                    $Cutter1_buchstabe;
                                ${$MedienDaten}{$aktAlephID}->{'RVK-3b-cutter1_zahl'} =
                                    $Cutter1_zahl;

                                if (
                                    (
                                        defined($Cutter1_buchstabe) and
                                        defined($Cutter1_zahl)
                                    )
                                    and
                                    (
                                     ($Cutter1_buchstabe ne '') and
                                     ($Cutter1_zahl ne '')
                                    )
                                   ) {

                                    if ($Cutter1_zahl =~ /^\d+?$/) {
                                        # ist eine Zahl, alles ok
                                    } else {
                                        print ERRORLOG __LINE__ . " " .
                                            $usersignatur .
                                            " Fehler RVK-3b-cutter1_zahl " .
                                            "ist keine Zahl\n";
                                    }
                                } else {
                                    #-------------------------------------------
                                    # wenn leer oder nicht definiert
                                    # prüfen ob auch RVK-3a-cutter1_buchstabe
                                    # leer ist, dann ist es ggf. ok
                                    #-------------------------------------------
                                    if (!defined($Cutter1_buchstabe)) {
                                        if (!defined($Cutter1_zahl)) {
                                            #-----------------------------------
                                            # alles ok dann wird diese Gruppe
                                            # uebersprungen, es wird aber eine
                                            # Zahl zugewiesen damit die
                                            # Sortierung unveraendert
                                            # durchgefuehrt werden kann
                                            #-----------------------------------
                                            ${$MedienDaten}{$aktAlephID}->{'RVK-3a-cutter1_buchstabe'} = '';
                                            ${$MedienDaten}{$aktAlephID}->{'RVK-3b-cutter1_zahl'} = 0;
                                        }
                                    } else {
                                        # wann komme ich hierher?
                                        print ERRORLOG __LINE__ . " " .
                                            $usersignatur . "\n";
                                    };
                                };

                                # Achtung auch in die Ebooks übernehmen
                            } elsif ($lRVKEbook) {
                                my ($Standort,
                                    $Buchstabe,
                                    $Feingruppe,
                                    $Cutter1_buchstabe,
                                    $Cutter1_zahl,
                                    $rest) =
                                    zerlegeRVKSignatur( $usersignatur, $lEbook );
                                ${$MedienDaten}{$aktAlephID}->{'RVK-1-buchstabe'} =
                                    $Buchstabe;
                                ${$MedienDaten}{$aktAlephID}->{'RVK-2-feingruppe'} =
                                    $Feingruppe;
                                ${$MedienDaten}{$aktAlephID}->{'RVK-3a-cutter1_buchstabe'} =
                                    $Cutter1_buchstabe;
                                ${$MedienDaten}{$aktAlephID}->{'RVK-3b-cutter1_zahl'} =
                                    $Cutter1_zahl;
                                if (defined($Cutter1_zahl)
                                    and
                                    ($Cutter1_zahl ne '')) {

                                    if ($Cutter1_zahl =~ /^\d+?$/) {
                                        # ist eine Zahl, alles ok
                                    } else {
                                        print ERRORLOG __LINE__ . " " .
                                            $usersignatur .
                                            " Fehler RVK-3b-cutter1_zahl " .
                                            "ist keine Zahl\n";
                                        print ERRORLOG __LINE__ .
                                            " Fehler bei Signatur: '" .
                                            $usersignatur .
                                            "' \$Cutter1_buchstabe: '" .
                                            $Cutter1_buchstabe .
                                            "' \$Cutter1_zahl ist keine Zahl: '" .
                                            $Cutter1_zahl . "'\n";
                                    }
                                } else {
                                    #-------------------------------------------
                                    # wenn leer oder nicht definiert
                                    # prüfen ob auch RVK-3a-cutter1_buchstabe
                                    # leer ist, dann ist es ggf. ok
                                    #-------------------------------------------
                                    if (defined($Cutter1_buchstabe) and
                                        ($Cutter1_buchstabe eq "")) {
                                        #---------------------------------------
                                        # alles ok dann wird diese Gruppe
                                        # uebersprungen, es wird aber eine Zahl
                                        # zugewiesen damit die Sortierung
                                        # unveraendert durchgefuehrt werden kann
                                        #---------------------------------------
                                        ${$MedienDaten}{$aktAlephID}->{'RVK-3b-cutter1_zahl'} = 0;
                                    } else {
                                        #---------------------------------------
                                        # Fehler bei Signatur festgestellt,
                                        # Cutter nicht vollstaendig
                                        # $Cutter1_buchstabe ist definiert,
                                        # aber notwendige Zahl nicht!
                                        #---------------------------------------
                                        print ERRORLOG __LINE__ .
                                            " Fehler bei Signatur: '" .
                                            $usersignatur .
                                            "' \$Cutter1_buchstabe: '" .
                                            $Cutter1_buchstabe .
                                            "' \$Cutter1_zahl ist nicht " .
                                            "definiert!\n";
                                        # damit es beim Sortieren keinen
                                        # weiteren Fehler gibt!
                                        ${$MedienDaten}{$aktAlephID}->{'RVK-3b-cutter1_zahl'} = 0;
                                    };
                                };

                                # Achtung auch in die Ebooks übernehmen

                            }

                        } else {
                            #---------------------------------------------------
                            # Die Signatur darf nicht leer sein! weil sonst
                            # ein Fehler beim Einsortieren passiert
                            # deshalb muss dieser Datensatz verworfen werden.
                            #---------------------------------------------------
                            $lWgFehlerDelete    = $wahr;
                        }
                    }
                    #-----------------------------------------------------------
                    elsif (     ($SpaltenName{ $nSpalte } eq 'SPRACHE')
                            and ($AlephIds{ $aktAlephID } < 2)){
                        if ($akt ne '') {
                            ${$MedienDaten}{$aktAlephID}->{sprache} = $akt;

                            if ($akt ne '') {
                                $Statistik{'sprachegesamt'}{'mitsprache'}++;
                                $Statistik{'sprache'}{$akt}++;
                            };

                        }
                    }
                    #-----------------------------------------------------------
                    elsif (     ($SpaltenName{ $nSpalte } eq 'Aufl.')
                            and ($AlephIds{ $aktAlephID } < 2)){
                        if ($akt ne '') {
                            ${$MedienDaten}{$aktAlephID}->{aufl} = $akt;
                        } else {
                            ${$MedienDaten}{$aktAlephID}->{aufl} = '0';
                        }
                    }


                }

                $nSpalte++;
            }

            if ($nIndex > 1) {
                # stillgelegt weil dieser Spezialfall jetzt auf die gleiche Art
                # wie andere Fehler behandelt wird
                ## wenn Titel leer ist (also -~-) dann diesen Wert aus der Liste
                ##   entfernen sonst wird die Anzahl der Gesamttitel falsch
                ##   berechnet!
                #if (${$MedienDaten}{$aktAlephID}->{title} eq '-~-') {
                #    delete(${$MedienDaten}{$aktAlephID});
                #}


                if ($lWgFehlerDelete) {

                    # bei bekannten Fehlern in der CSV-Datei soll keine
                    # Info in der Fehlerliste erscheinen
                    # Bekannte Fälle sind u.a.:
                    # - Titel leer (bei gelöschten Sätzen der Fall)
                    # - Signatur fehlt
                    # - bei ebooks: link zum ebook fehlt
                    if ($lWgFehlerDeleteReport) {
                        # Protokollieren des Fehlers damit der Datensatz korrigiert werden kann
                        open( CSVERRORLOG, ">>$log_csv_error" ) or die "Kann nicht in $log_csv_error schreiben $!\n";
                        print CSVERRORLOG "Fehler in: " . $aktZeile . "\n";
                        close CSVERRORLOG;
                    };

                    # bei bestimmten Fehlern Datensatz nicht aufnehmen!
                    delete(${$MedienDaten}{$aktAlephID});
                }

                if ($lEbook) {
                    if (!$lPrintEbook) {
                        # weitere Aktionen bei Ebooks tun
                    }
                }

            }
        }
    }

    open( KEINTREFFER, ">$cKeinTrefferCacheFile" ) or die
        "Kann SOURCE $cKeinTrefferCacheFile nicht zum schreiben oeffnen $!\n";
    foreach my $akt (sort( keys( %KeineTrefferCache ) ) ) {
        print KEINTREFFER $akt . "\n";
    }

    if ($lEbook) {
        print KEINTREFFER " \$nEbooksUndPrint: '" . $nEbooksUndPrint . "'\n";
        print KEINTREFFER "\$nEbooksOhnePrint: '" . $nEbooksOhnePrint . "'\n";
    }

    close KEINTREFFER;

    # Statistik-Daten ausgeben
    print STATISTIK "Anzahl Medien:           " .
        $Statistik{'fachgesamt'}{'medien'} . "\n";
    print STATISTIK "Anzahl Medien mit Fach:  " .
        $Statistik{'fachgesamt'}{'mitfach'} . "\n";
    print STATISTIK "Anzahl Medien ohne Fach: " .
        ($Statistik{'fachgesamt'}{'medien'} -
            $Statistik{'fachgesamt'}{'mitfach'}) . "\n";

    foreach my $akt (sort( keys( %{$Statistik{'fach'}} ) ) ) {
        print STATISTIK $akt . ":\t" . $Statistik{'fach'}{$akt} . "\n";
    }

    print STATISTIK "\n"x2;

    print STATISTIK "Anzahl Medien:              " .
        $Statistik{'fachgesamt'}{'medien'} . "\n";
    print STATISTIK "Anzahl Medien  mit Sprache: " .
        $Statistik{'sprachegesamt'}{'mitsprache'} . "\n";
    print STATISTIK "Anzahl Medien ohne Sprache: " .
        ($Statistik{'fachgesamt'}{'medien'} -
            $Statistik{'sprachegesamt'}{'mitsprache'}) . "\n";

    foreach my $akt (sort( keys( %{$Statistik{'sprache'}} ) ) ) {
        print STATISTIK $akt . ":\t" . $Statistik{'sprache'}{$akt} . "\n";
    }
    # Statistik-Daten ausgeben Ende
}


sub PruefeCover {
    my $pISBN               = shift();
    my $pHeight             = shift();
    my $htmlpath            = shift(); # neu 2015-03-06, 14:42:13

    my $URL                 = 'http://images.amazon.com/images/P/' .
                                $pISBN .
                                '.01._SCLZZZZZZZ_.jpg';
    my $lAbfrageErfolgreich = $falsch;
    my $lCover              = $falsch;
    my $lCache              = $falsch;
    my $lThumbnail          = $falsch;
    my $lAmazon             = $wahr;
    my $doc;
    my @zeilen              = ();
    my $cImageName          = $htmlpath . '/CoverCache/' . $pISBN . '.jpg';
    my $cThumbnailImageName = $htmlpath . '/CoverCache/thumbnail/' . $pISBN . '.jpg';

    my $cImageNameWeb          = 'CoverCache/' . $pISBN . '.jpg';
    my $cThumbnailImageNameWeb = 'CoverCache/thumbnail/' . $pISBN . '.jpg';


    # Prüfen ob die Datei schon im Cache liegt!
    if (-e $cImageName) {
        $lCover = $wahr;
        $lCache = $wahr;
    }
    else
    {
        # Image muss erst von Amazon abgefragt werden
        my $ua      = LWP::UserAgent->new;
        $ua->timeout( 100 );

        my $docUA   = $ua->get( $URL );

        if ($docUA->is_success)
        {
            print "Erfolgreich bei $pISBN \n"   if ($debug);
            $lAbfrageErfolgreich = $wahr;
        }
        else
        {
            $lAbfrageErfolgreich = $falsch;
            print "Holen nicht Erfolgreich bei $pISBN \n" if ($debug);
            print ERRORLOG "Holen nicht Erfolgreich bei $pISBN \n";
        };
        if ($docUA->is_success)
        {
            $doc = $docUA->content;
            # Prüfen ob es sich um die kein Cover-Image handelt
            if (substr($doc, 0, 6 ) eq 'GIF89a') {
                # Kein Cover vorhanden!
                $lAmazon    = $falsch;
            } elsif (substr($doc, 0, 6 ) eq 'GIF87a') {
                my $tempGif = "tempGif.gif";
                open( IMAGE, ">$tempGif" )
                    or die "Kann IMAGE $tempGif nicht oeffnen $!\n";
                binmode IMAGE;
                print IMAGE $doc;
                close IMAGE;
                system( `convert $tempGif $cImageName`);
                unlink $tempGif;
                $lCover = $wahr;
            } else {
                open( IMAGE, ">$cImageName" )
                    or die "Kann IMAGE $cImageName nicht oeffnen $!\n";
                binmode IMAGE;
                print IMAGE $doc;
                close IMAGE;
                $lCover = $wahr;
            }
        };

    };

    if ($lAmazon) {
        if (-e $cThumbnailImageName) {
            $lThumbnail = $wahr;
        } else {
            print ERRORLOG __LINE__ . ": " . $cImageName . "\n" if ($debug);

            my $image       = GD::Image->newFromJpeg($cImageName);
            my $width;
            my $height;
            ($width,$height) = $image->getBounds();
            if ($height > $pHeight) {
                my $IRimage = Image::Resize->new($cImageName);
                my $gd = $IRimage->resize(200, $pHeight);

                open( IMAGE, ">$cThumbnailImageName" )
                    or die "Kann IMAGE $cThumbnailImageName nicht oeffnen $!\n";
                binmode IMAGE;
                print IMAGE $gd->jpeg();
                close IMAGE;
                $lThumbnail = $wahr;
            }
        }
    }

    #---------------------------------------------------------------------------
    # Dateidatum holen um es an den Grafiknamen anzuhaengen, damit ich
    # ein Caching einschalten kann
    #---------------------------------------------------------------------------
    my $ThumbnailMtime;
    my $ImageMtime;
    if ($lThumbnail) {
        $ThumbnailMtime = (stat $cThumbnailImageName)[9];

        my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
            localtime($ThumbnailMtime);
        if ($debug) {
            print ERRORLOG __LINE__ . ": " . $ThumbnailMtime . ': ' .
                        substr('0'.$mday,-2) . '.' .
                        substr('0'.($mon+1),-2) . '.' .
                        substr($year+1900,-2) . '  ' .
                        $hour . ':' . $min . ':' . $sec . "\n";
        }
    }
    if ($lCover) {
        $ImageMtime = (stat $cImageName)[9];
    }


    return( $lCover,
            $cImageName,
            $cImageNameWeb,
            $lCache,
            $ImageMtime,
            $lThumbnail,
            $cThumbnailImageName,
            $cThumbnailImageNameWeb,
            $ThumbnailMtime);
}



#-------------------------------------------------------------------------------
sub PruefeQRCodeFile {
    my $urlBase         = shift();
    my $AlephId         = shift();
    my $PfadQRCodeBase  = shift();

    my $lError          = $falsch;
    my $url             = $urlBase . $AlephId;

    my $cGrafikKurzName = $AlephId . '.png';
    my $cGrafikName     = $PfadQRCodeBase . $cGrafikKurzName;

    if (-e $cGrafikName) {
    } else {
        $cGrafikKurzName = "";
    }

    return($cGrafikKurzName);
}


#-------------------------------------------------------------------------------
sub FarbWertLight
{
    my $lNormal = shift();
    my $farbObjekt;

    if ($lNormal)
    {
        $farbObjekt     = Imager::Color->new(255, 255, 255);
    }
    else
    {
        #$farbObjekt     = Imager::Color->new(255, 0, 0);
        $farbObjekt     = Imager::Color->new(255, 255, 0);
    }
    return( $farbObjekt );
}

#-------------------------------------------------------------------------------
sub FarbWertDark
{
    my $lNormal = shift();
    my $farbObjekt;

    if ($lNormal)
    {
        $farbObjekt     = Imager::Color->new(0, 0, 0);
    }
    else
    {
        $farbObjekt     = Imager::Color->new(255, 0, 0);
    }
    return( $farbObjekt );
}


#-----------------------------------------------------------------------
#sub zerlegeRVKSignatur
# eine RVK-Signatur in ihre Bestandteile zerlegen und diese getrennt
# zurückmelden
#   Parameter:
#       $cSig                   Die zu pruefende Signatur
#-----------------------------------------------------------------------
sub zerlegeRVKSignatur
{
    my $cSig                = shift();
    my $lEbook              = shift();

    my $wahr                = 1;
    my $falsch              = 0;


    my $Standort;
    my $Buchstabe;
    my $Feingruppe;
    my $Cutter1_buchstabe;
    my $Cutter1_zahl;
    my $cRest;


    #-----------------------------------------------------------------------
    # Beispiel: 200 QA 16230
    #-----------------------------------------------------------------------

    # Bei eBooks wird einfach ein Standort d.h. die ersten drei Zahlen ergänzt
    # dann kann die weitere Behandlung erfolgen ohne die
    # RegEx duplizieren zu müssen
    if ($lEbook) {
        $cSig = '999 ' . $cSig;
    }


    #---------------------------------------------------------------------------
    # Hinter der Zahl am Ende der Signatur folgen noch beliebige weiter Zeichen
    # diese sollen das erkennen nicht verhindern,
    # werden aber ignoriert!
    #---------------------------------------------------------------------------
    if ($cSig       =~
        m/^
            (\d{3})         # *1  100 200 300 400 500 515 520 ...
            (\s+)           #  2  Leerzeichen
            ([a-zA-Z]{2})   # *3  zwei Buchstaben
            (\s+)           #  4  Leerzeichen
            (\d*?)          # *5  nur Zahlen
            (\s*)           #  6
            ([a-zA-Z]{1})   #  7  1 Buchstabe von Cutter1
            (\d*?)          #  8  nur Zahlen  von Cutter1
            (\s*)           #  6
            ((\.)(\d*?))    #  9  ein Punkt und weitere Zahlen
            ([\D]+)         # 10  irgendwelche NICHT-Zahlen
            (.*?)           # 11  beliebige weitere Zeichen inkl. Zahlen
                            #       und Nichtzahlen
        $/x
        )
    {
        # Beispiel: 500_AZ_12_A12.2012_adsjföaföfadölkjföal
        # Beispiel: 500_AZ_12_A12_.2012_adsjföaföfadölkjföal
        $Standort           = $1;
        $Buchstabe          = $3;
        $Feingruppe         = $5;
        $Cutter1_buchstabe  = $7;
        $Cutter1_zahl       = $8;
        #print __LINE__ . " " . $cSig . "\n" if ($debug);

        print ERRORLOG __LINE__ . " \$cSig: '" . $cSig .
            "' erkennung 1:'$1' 2:'$2' 3:'$3' 4:'$4' 5:'$5' 6:'$6' " .
            "7:'$7' 8:'$8' 9:'$9' 10:'$10'\n"  if ($debug);
    }
    # 100 AF 3000 a12
    elsif ($cSig =~
        m/^
            (\d{3})         # *1  100 200 300 400 500 515 520 ...
            (\s+)           #  2  Leerzeichen
            ([a-zA-Z]{2})   # *3  zwei Buchstaben
            (\s+)           #  4  Leerzeichen
            (\d*?)          # *5  nur Zahlen
            (\s*)           #  6
            ([a-zA-Z]{1})   #  7  1 Buchstabe von Cutter1
            (\d*?)          #  8  nur Zahlen  von Cutter1
            (\s*)           #  6
            ((\.)(\d*?))    #  9  ein Punkt und weitere Zahlen
        $/x
        )
    {
        # Beispiel: 500_AZ_12_A12.2012
        # Beispiel: 500_AZ_12_A12_.2012
        $Standort           = $1;
        $Buchstabe          = $3;
        $Feingruppe         = $5;
        $Cutter1_buchstabe  = $7;
        $Cutter1_zahl       = $8;
        #print __LINE__ . " " . $cSig . "\n" if ($debug);

        print ERRORLOG __LINE__ . " \$cSig: '" . $cSig .
            "' erkennung 1:'$1' 2:'$2' 3:'$3' 4:'$4' 5:'$5' 6:'$6' " .
            "7:'$7' 8:'$8' 9:'$9' 10:'$10'\n"  if ($debug);
    }
    elsif ($cSig =~
        m/^
            (\d{3})         # *1  100 200 300 400 500 515 520 ...
            (\s+)           #  2  Leerzeichen
            ([a-zA-Z]{2})   # *3  zwei Buchstaben
            (\s+)           #  4  Leerzeichen
            (\d*?)          # *5  nur Zahlen
            (\s*)           #  6
            ((\.)(\d*?))    #  9  ein Punkt und weitere Zahlen
            ([\D]+)         # 10  irgendwelche NICHT-Zahlen
            (.*?)           # 11  beliebige weitere Zeichen inkl. Zahlen
                            #       und Nichtzahlen
        $/x
        )
    {
        # ohne Cutter1
        # Beispiel: 500_AZ_12.adfadfasdf2012_adsjföaföfadölkjföal
        # eignelich ein jahr nach dem punkt aber es könnte auch
        # beliebiger Text sein Jahr interessiert aber ev nicht
        # ansonsten ein (\d+?))
        $Standort           = $1;
        $Buchstabe          = $3;
        $Feingruppe         = $5;
        #print __LINE__ . " " . $cSig . "\n" if ($debug);

        print ERRORLOG __LINE__ . " \$cSig: '" . $cSig .
            "' erkennung 1:'$1' 2:'$2' 3:'$3' 4:'$4' 5:'$5' 6:'$6' " .
            "7:'$7' 8:'$8' 9:'$9' 10:'$10'\n"  if ($debug);
    }
    elsif ($cSig =~
        m/^
            (\d{3})         #  *1 100 200 300 400 500 515 520 ...
            (\s+)           #   2 Leerzeichen
            ([a-zA-Z]{2})   #  *3 zwei Buchstaben
            (\s+)           #   4 Leerzeichen
            (\d*?)          #  *5 nur Zahlen und ggf. ein Punkt und weitere
                            #       Zahlen
            (\s+)           #   6 Leerzeichen
            ([a-zA-Z]{1})   #  *7 1 Buchstabe
            (\d*?)          #  *8 nur Zahlen
            ([\D]+)         #   9 irgendwelche NICHT-Zahlen
            (.*?)           #  10 beliebige weitere Zeichen inkl. Zahlen
                            #       und Nichtzahlen
            $/x
        )
    {
        # Beispiel: 500_AZ_12.2012_adsjföaföfadölkjföal
        print ERRORLOG __LINE__ . " \$cSig: '" . $cSig .
            "' erkennung 1:'$1' 2:'$2' 3:'$3' 4:'$4' 5:'$5' 6:'$6' " .
            "7:'$7' 8:'$8' 9:'$9' 10:'$10'\n"  if ($debug);

        $Standort           = $1;
        $Buchstabe          = $3;
        $Feingruppe         = $5;
        $Cutter1_buchstabe  = $7;
        $Cutter1_zahl       = $8;
        #print __LINE__ . " " . $cSig . "\n" if ($debug);

    }
    elsif ($cSig =~
        m/^
            (\d{3})         # *1 100 200 300 400 500 515 520 ...
            (\s+)           # 2  Leerzeichen
            ([a-zA-Z]{2})   # *3 zwei Buchstaben
            (\s+)           # 4  Leerzeichen
            (\d*?)          # *5 nur Zahlen und ggf. ein Punkt und weitere
                            #       Zahlen
            (\s+)           #  6 Leerzeichen
            ([a-zA-Z]{1})   # *7 1 Buchstabe
            (\d*?)          # *8 nur Zahlen
        $/x
        )
    {
        # Beispiel: 500_AZ_12_A12
        print ERRORLOG __LINE__ . " \$cSig: '" . $cSig .
            "' erkennung 1:'$1' 2:'$2' 3:'$3' 4:'$4' 5:'$5' 6:'$6' " .
            "7:'$7' 8:'$8' \n"  if ($debug);
        $Standort           = $1;
        $Buchstabe          = $3;
        $Feingruppe         = $5;
        $Cutter1_buchstabe  = $7;
        $Cutter1_zahl       = $8;
        #print __LINE__ . " " . $cSig . "\n" if ($debug);
    }
    #---------------------------------------------------------------------------
    # Version mit einer Normalen Signatur (Zeitschriften)
    # mit Punkt und einer Zahl
    #---------------------------------------------------------------------------
    elsif ($cSig =~
        m/^
            (\d{3})         # *1 100 200 300 400 500 515 520 ...
            (\s*?)          # 2  optionale Leerzeichen
            ([a-zA-Z]{2})   # 3* zwei Buchstaben
            (\s*?)          # 4  optionale Leerzeichen
            (\d*?)          # *5 nur Zahlen
            ((\.)(\d*?))    # 6  ein Punkt und weitere Zahlen
        $/x
        )
    {
        $Standort           = $1;
        $Buchstabe          = $3;
        $Feingruppe         = $5;
        print ERRORLOG __LINE__ . " \$cSig: '" . $cSig .
            "' erkennung 1:'$1' 2:'$2' 3:'$3' 4:'$4' 5:'$5' 6:'$6' " .
            "7:'$7' 8:'$8' 9:'$9' 10:'$10'\n"  if ($debug);
        #print __LINE__ . " " . $cSig . "\n" if ($debug);
    }
    #---------------------------------------------------------------------------
    # Version mit einer Normalen Signatur (Zeitschriften) mit Bindestrich
    # und einer Zahl
    #---------------------------------------------------------------------------
    # Beispiele:
    # 300 PA 4030:002
    # 400 AF 08001-25
    # MAN_ALEPH000999570  300 PE 257(3)-DE-R, 1501-2266
    elsif ($cSig =~
        m/^
            (\d{3})         # *1 100 200 300 400 500 515 520 ...
            (\s*?)          # 2  optionale Leerzeichen
            ([a-zA-Z]{2})   # 3* zwei Buchstaben
            (\s*?)          # 4  optionale Leerzeichen
            (\d*?)          # *5 nur Zahlen
            (([-:\(])(.*?)) # 6  ein Bindestrich oder Doppelpunkt oder
                            #       Klammer auf und weitere beliebige Zeichen
        $/x
        )
    {
        $Standort           = $1;
        $Buchstabe          = $3;
        $Feingruppe         = $5;
        print ERRORLOG __LINE__ . " \$cSig: '" . $cSig .
            "' erkennung 1:'$1' 2:'$2' 3:'$3' 4:'$4' 5:'$5' 6:'$6' " .
            "7:'--' 8:'--' 9:'--' 10:'--'\n"  if ($debug);
        #print __LINE__ . " " . $cSig . "\n" if ($debug);
    }
    #---------------------------------------------------------------------------
    # Version mit einer Normalen Signatur (Zeitschriften)
    #---------------------------------------------------------------------------
    elsif ($cSig    =~
        m/^
            (\d{3})         # *1 100 200 300 400 500 515 520 ...
            (\s*?)          # 2  optionale Leerzeichen
            ([a-zA-Z]{2})   # 3* zwei Buchstaben
            (\s*?)          # 4  optionale Leerzeichen
            (\d*?)          # *5 nur Zahlen
        $/x
        )
    {
        $Standort           = $1;
        $Buchstabe          = $3;
        $Feingruppe         = $5;
        print ERRORLOG __LINE__ . " \$cSig: '" . $cSig .
            "' erkennung 1:'$1' 2:'$2' 3:'$3' 4:'$4' 5:'$5' 6:'$6' " .
            "7:'$7' 8:'$8' 9:'$9' 10:'$10'\n"  if ($debug);
        #print __LINE__ . " " . $cSig . "\n" if ($debug);
    }
    #---------------------------------------------------------------------------
    # Version fuer blank
    #---------------------------------------------------------------------------
    elsif ($cSig =~ m/^
                       (blank)
                       $/x
          )
    {
        $Standort    = 'blank';
        $Buchstabe   = 'blank';
        $Feingruppe  = 'blank';
        print ERRORLOG __LINE__ . " \$cSig: '" . $cSig .
            "' erkennung 1:'$1' 2:'$2' 3:'$3' 4:'$4' 5:'$5' 6:'$6' " .
            "7:'$7' 8:'$8' 9:'$9' 10:'$10'\n"  if ($debug);
        #print __LINE__ . " " . $cSig . "\n" if ($debug);
    }

    return( $Standort,
            $Buchstabe,
            $Feingruppe,
            $Cutter1_buchstabe,
            $Cutter1_zahl,
            $cRest );
};


sub TransformWinPathToPerl
{
    my $cPath   = shift();
    $cPath =~ s/\\/\//g;
    return( $cPath );
}
# eof: CreateGesamtBuecherregal.pl