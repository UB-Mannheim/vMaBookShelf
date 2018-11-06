#!/usr/bin/perl -w
#-------------------------------------------------------------------------------
# Copyright (C) 2018 Universitätsbibliothek Mannheim
# Name:
#       HoleCSV_von_alma.pl
# Author:
#       Bernd Fallert <bernd.fallert@bib.uni-mannheim.de>
# Projekt:
#       booklist
# Aufgabe:
#       holt via api Daten von Alma
# Aufruf:
#       perl HoleCSV_von_alma.pl
#       perl HoleCSV_von_alma.pl --ebooks
# Hinweis:
# 	- Funktioniert aktuell nur bei books für die vorher in Alma eine Sammlung eingetragen wurden
#   - Bei eBooks wird die csv-Datei der Bücher zusätzlich eingelesen um die Signatur oder
#     Statistikgruppe übernehmen zu können
# History:
#   2016-06-08, 12:03:25
#       verschiedene location_id abfragbar, bisher nur 110
#       neu auch für WEST_EG
#       zweiter Parameter dann zwingend $SigAnfang
#       bei 110 ist das Deckungsgleich bei WEST_EG ist das 120
#   2018-10-18
#	Publisher ergänzt damit Erwerbung überprüfung der Sammlungen machen kann
#	es soll auch noch eine Liste ergänzt werden in der die Prints ohne zugehöriges eBook stehen
#
# Doku: https://developers.exlibrisgroup.com/alma/apis/bibs
#
#-------------------------------------------------------------------------------
# Feldreihenfolge bei den CSV-Dateien
# bei ebooks
#RecordID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Fach|Signatur|URL
# bei prints
# bis 17.10.2018 Ft
#Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Signatur|Fach
# ab 18.10.2018 Ft
#Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Publisher|Signatur|Fach

use strict;
use warnings;
our $log;

BEGIN {
    use CGI::Carp qw(carpout);
    #-----------------------------------------------
    # die Datei muss fuer OTHER schreibbar sein!
    #-----------------------------------------------
    $log = __FILE__ . ".log";
    open( ERRORLOG, ">>$log" ) or die "Kann nicht in $log schreiben $!\n";
    carpout (*ERRORLOG);
};


use lib '.';

use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

use CGI::Carp qw(carpout);
use Encode qw(_utf8_off _utf8_on is_utf8 decode_utf8 encode_utf8 from_to);
use Unicode::Normalize;
use Getopt::Long;
#use Text::CSV::Simple;
use Text::CSV;
use Text::CSV_XS;
use XML::Simple;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Response;
use CGI::Enurl;
use URI::Escape;
use Encode;
use Config::IniFiles qw( :all);


$|                          = 1;
my $wahr                    = 1;
my $falsch                  = 0;
my $debug                   = $falsch;
my $pDestinationFile        = '';
my $lresetlog               = $falsch;
my $INIFILE                 = 'config/booklist.ini';
my $lEbooks                 = $falsch;

#-------------------------------------------------------------------------------
# Altes CSV-Fehler Protokoll leeren
#-------------------------------------------------------------------------------
my $log_csv_error       = __FILE__ . ".csv_error.log";
my $log_csv_ohne_ebook  = __FILE__ . ".csv_ohne_ebook.log";
open( my $CSVERRORLOG, ">$log_csv_error" ) or die "Kann nicht in $log_csv_error schreiben $!\n";
open( my $CSVOHNEEBOOK, ">$log_csv_ohne_ebook" ) or die "Kann nicht in $log_csv_ohne_ebook schreiben $!\n";

my $Frage_location_id       = '';   # default siehe History: 2016-06-08, 12:03:25
my $Frage_SigAnfang         = '';   # default siehe History: 2016-06-08, 12:03:25


GetOptions(
    "location_Id=s"                         	=> \$Frage_location_id,
    "siganfang=s"                           	=> \$Frage_SigAnfang,
    "ebooks"			            	=> \$lEbooks,
        # Errolog beim Starten loeschen
    "resetlog"                              	=> \$lresetlog,
);


#--------------------------------------------------------------
# wenn gewünscht ist das das Errorlog zurückgesetzt wird
#--------------------------------------------------------------
if ($lresetlog) {
    open( ERRORLOG, ">", $log ) or die "Kann nicht in $log schreiben $!\n";
    carpout (*ERRORLOG);
    ERRORLOG->autoflush(1);
};



#-------------------------------------------------------------------------------
# Normale Programmkonfiguration einlesen
#-------------------------------------------------------------------------------
my $cfg                     = new Config::IniFiles( -file => $INIFILE );

#-------------------------------------------------------------------------
# Konfiguration lesen
#-------------------------------------------------------------------------
$cfg->ReadConfig;

my $collection = $cfg->val( 'ALMA', 'collection' );
my $ebookCollection = $cfg->val( 'ALMA', 'ebooks-collection' );
my $apiKey  = $cfg->val( 'ALMA', 'apiKey' );
my $cSkipSubTitle = $cfg->val( 'ALMA', 'skipSubtitles' );
my $lSkipSubTitle = 0;
my $cStartSkipWith = ':';

if (lc($cSkipSubTitle) eq 'yes' || lc($cSkipSubTitle) eq 'ja') {
    $lSkipSubTitle = 1;
    $cStartSkipWith = $cfg->val( 'ALMA', 'SkipStartWith' );
}

if (($Frage_location_id eq '') or ($Frage_SigAnfang eq '')) {
    $Frage_location_id  = $cfg->val( 'SET', 'locationId' );
    $Frage_SigAnfang    = $cfg->val( 'SET', 'siganfang' );
}

my $sourceDir = TransformWinPathToPerl($cfg->val( 'PATH', 'csv' ));
if ($sourceDir =~ m/^(.*?)\/$/) {
    $sourceDir = $1;
}


# 'learningcenter_print.csv';   # default für print-csv-Datei
my $pSourceFilePrint        = $cfg->val( 'CSV', 'print' );
my $pSourceEBook            = $cfg->val( 'CSV', 'ebook' );

my $SourceFilePrint          = $sourceDir . '/' . $pSourceFilePrint;
my $SourceFileEBook          = $sourceDir . '/' . $pSourceEBook;

my $parser;
my @BookData;
my %hBookData = ();


my $out;
if (!$lEbooks) {
    open($out, ">:utf8", $SourceFilePrint) or die
    "Kann OUT File $SourceFilePrint nicht oeffnen ($!)\n";

    print $out 'Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Publisher|Signatur|Fach' . "\n";

} else {
    open($out, ">:utf8", $SourceFileEBook) or die
    "Kann OUT File $SourceFileEBook nicht oeffnen ($!)\n";

    print $out 'RecordID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Fach|Signatur|URL' . "\n";

    # damit gleiche Variable benutzt werden kann
    $collection    = $ebookCollection;

    #---------------------------------------------------------------
    # bei ebooks wird die csv-Datei der bücher eingelesen um das 
    # Fach (Statistikkennzahl) und die Signatur übernehmen zu können
    #---------------------------------------------------------------

    #my @BookData;
    # Read/parse CSV
    my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1, sep_char=> "|", allow_loose_quotes => 1 });
    open my $fh, "<:encoding(utf8)", $SourceFilePrint or die "$SourceFilePrint: $!";
    
    my $nIndex = 0;
    while (my $row = $csv->getline($fh)) {

        my @fields = @$row;
        $nIndex++;
        
        #if ($nIndex == '662') {
        #    sleep(1);
        #};

        if ($fields[0] =~ m/^Aleph-ID/) {
        } else {
            #   0       1     2     3     4   5     6       7         8        9
            #Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Publisher|Signatur|Fach
            push @BookData, {'Aleph-ID'     => $fields[0]
                             ,'Autor'       => $fields[1]
                             ,'Titel'       => $fields[2]
                             ,'Auflage'     => $fields[3]
                             ,'Jahr'        => $fields[4]
                             ,'ISBN'        => $fields[5]
                             ,'Sprache'     => $fields[6]
                             ,'Publisher'   => $fields[7]
                             ,'Signatur'    => $fields[8]
                             ,'Fach'        => $fields[9]
                            };
                            
            # last index of array
            my $nBookIndex = $#BookData;
            
            # Daten des Buches speichern
            # Index ist Signatur damit geprüft werden
            # kann für welche Bücher es ein eBook gibt
            $hBookData{$fields[8]} = {
                              'nIndex'      => $nBookIndex
                             ,'alsEBook'    => $falsch
                            };
        }
        print $nIndex . ': ' . $fields[0] . "\n";
    }
    close $fh;
};


my $ua                      = LWP::UserAgent->new;
my $ua2                     = LWP::UserAgent->new;
my $ua3                     = LWP::UserAgent->new;
my $ua4                     = LWP::UserAgent->new;
my $uabestpost              = LWP::UserAgent->new;

#'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/collections/' . $collection . '/bibs?apikey=' . $apiKey
my $nOffset                 = 0;
my $nLimit                  = 100;

my $nBookAnzahl             = 1000;
my $nAktBookAnzahl          = 0;
my $nBookNr                 = 0;
my $nBooksWithoutMatch      = 0;
my %AddInfos                = ();


do {

    $nAktBookAnzahl += $nLimit;

    # 1. Anfrage
    my $cRequest1 = 'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/collections/' .
            $collection . '/bibs?apikey=' . $apiKey .
            '&offset=' . $nOffset .
            '&limit=' . $nLimit;

    print ERRORLOG "------------- ANFRAGE 1 -----------------\n";
    print ERRORLOG $cRequest1 . "\n";
    print ERRORLOG "-----------------------------------------\n";

    my $response = $ua->request(
    HTTP::Request->new(
    GET => $cRequest1));

    if ($response->is_error()) {
        printf "%s\n(1) " . $response->status_line;
        printf ERRORLOG "%s\n(1) " . $response->status_line . "\n";
        print ERRORLOG "\t" . $cRequest1 . "\n";
    } else {


        my $xml = $response->content;


        my $bibBooks = XMLin($xml, ForceArray => 1);

        print ERRORLOG "------------- STUFE 1 -----------------\n";
        print ERRORLOG Dumper($bibBooks);


        $nBookAnzahl = $bibBooks->{'total_record_count'};

        # Vor die Schleife verschoben
        #my %AddInfos = ();

        foreach my $aktRecord (@{$bibBooks->{'bib'}}) {
            my $thisRecord = readRecordStufe1($aktRecord, $lSkipSubTitle, $cStartSkipWith);

            # Debuging
            if ($thisRecord->{'mms_id'} == '9917858664402561') {
                sleep(1);
            } elsif ($thisRecord->{'mms_id'} == '990014945720402561') {
                sleep(1);
            } elsif ($thisRecord->{'mms_id'} == '990005935980402561') {
                # Buch mit mehreren Statisikgruppen
                sleep(1);
            } elsif ($thisRecord->{'mms_id'} == '990008916000402561') {
                # problem bei Sprache
                sleep(1);
            } elsif ($thisRecord->{'mms_id'} == '990013955620402561') {
                # ebook mit falscher Signaturzuordnung "101 Fragen ..."
                sleep(1);
            } elsif ($thisRecord->{'mms_id'} == '990016841780402561') {
                # ebook ohne exakte Titelzuordnung, titel ist länger, aber eine Zuordnung über die ISBN sollte erfolgen können
                sleep(1);
            } elsif ($thisRecord->{'mms_id'} == '9918376553402561') {
                # ebook unklar warum Zuordnungsproblem
                sleep(1);
            } elsif ($thisRecord->{'mms_id'} == '990014998040402561') {
                # ebook sollte match mit isbn möglich sein
                sleep(1);
            } elsif ($thisRecord->{'mms_id'} == '9918387045502561') {
                # ebook mit zuordnung zu falscher Signatur
                sleep(1);
            } elsif ($thisRecord->{'mms_id'} == '9918449038002561') {
                # ebook mit nicht verfügbarem Portfolios
                sleep(1);
            } elsif ($thisRecord->{'mms_id'} == '9918455258002561') {
                # ebook mit nicht verfügbarem Portfolios
                sleep(1);
            } elsif ($thisRecord->{'mms_id'} == '9918376552802561') {
                # ebook mit verfügbarem Portfolios
                sleep(1);
            } elsif ($thisRecord->{'mms_id'} == '9918379768602561') {
                # ebook ohne Zuordnung zu Titel
                sleep(1);
            };

            # hier unterscheiden ob es schon daten gibt oder ob es der erste Titel ist
            if (!exists($AddInfos{ $thisRecord->{'mms_id'} })) {
                $AddInfos{ $thisRecord->{'mms_id'} } = $thisRecord;
            } else {
                sleep(1);
            };
            
            #print $nBookNr . ": " . $thisRecord->{'mms_id'} . "\n";

            #------------------------------------------------------------------------------
            # hier unterscheiden sich ebooks und normale Medien
            #------------------------------------------------------------------------------
            # für ebooks
            #------------------------------------------------------------------------------
            #https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/{mms_id}/portfolios
            if (!$lEbooks) {

                #------------------------------------------------------------------------------
                # jetzt mit den Daten Weiterarbeiten und die Zweite Stufe holen
                # 2. Anfrage
                # Holding_id ermitteln
                #------------------------------------------------------------------------------
                my $cAnfrage2 = 'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/' .
                        $thisRecord->{'mms_id'} .
                        '/holdings?apikey=' . $apiKey;
                print ERRORLOG "------------- ANFRAGE 2 -----------------\n";
                print ERRORLOG $cAnfrage2 . "\n";
                print ERRORLOG "-----------------------------------------\n";

                my $response2 = $ua2->request(
                HTTP::Request->new(
                GET => $cAnfrage2 ));

                if ($response2->is_error()) {
                    printf "%s\n(2) " . $response2->status_line . "\n";
                    #printf ERRORLOG "%s\n" . $response2->status_line ;
                    printf ERRORLOG "%s\n(2) " . $response2->status_line . "\n";
                    print ERRORLOG "\t" . $cAnfrage2 . "\n";

                } else {


                    my $xml2 = $response2->content;


                    my $holdings = XMLin($xml2, ForceArray => 1);
                    print ERRORLOG "------------- STUFE 2 -----------------\n";
                    print ERRORLOG Dumper($holdings);

                    #if (($thisRecord->{'mms_id'} eq "990015538210402561") or ($thisRecord->{'mms_id'} eq "990011530170402561")) {
                    #    sleep(1);
                    #}

                    foreach my $aktRecord (@{$holdings->{'holding'}}) {
                        my $thisRecordHolding = readRecordStufe2($aktRecord);
                        if ($thisRecordHolding->{'location_id'} eq $Frage_location_id ) {
                            
                            # bisher diese Infos in das Hash eingefügt
                            # zukünftig muss das in ein Array innerhalb des Hashes eingefügt werden
                            # damit verschiedene Auflagen behandelt werden können
                                                        
                            # kann später wegfallen 24.10.2018 Ft
                            $AddInfos{ $thisRecord->{'mms_id'} }->{'call_number'}   = $thisRecordHolding->{'call_number'};
                            # diese Feld ist notwendig, da es sich zwischen den Auflagen nicht unterscheidet
                            $AddInfos{ $thisRecord->{'mms_id'} }->{'holding_id'}    = $thisRecordHolding->{'holding_id'};
                            $AddInfos{ $thisRecord->{'mms_id'} }->{'auflage'}       = $holdings->{'bib_data'}[0]->{'complete_edition'}[0];

                            if ($thisRecordHolding->{'call_number'} eq '120 PD 3006 B734(3)') {
                                sleep(1);
                            }
                            

                            # neu 24.10.2018 Ft
                            push(@{$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}, {
                                    'call_number'   => $thisRecordHolding->{'call_number'},
                                    'holding_id'    => $thisRecordHolding->{'holding_id'},
                                    'auflage'       => $holdings->{'bib_data'}[0]->{'complete_edition'}[0]
                                                                                     });
                            
                            
                            last;
                        }
                    }
                    
                    # kann später wegfallen 24.10.2018 Ft
                    # Weitere Daten holen
                    $AddInfos{ $thisRecord->{'mms_id'} }->{'auflage'} = $holdings->{'bib_data'}[0]->{'complete_edition'}[0];


                    # wenn keine holding_id ermittelt werden konnte dann gibt es fuer dieses Medium
                    # keine Daten, daher muss hierfür nichts angefragt werden
                    if ($AddInfos{ $thisRecord->{'mms_id'} }->{'holding_id'}  ne '') {

                        #########################################
                        # Jetzt 3. Stufe anfangen
                        #########################################
                        #wie 2. Stufe nur andere Daten
                            # jetzt mit den Daten Weiterarbeiten und die dritte Stufe holen
                            # 3. Anfrage
                            # weitere Daten ermitteln
                        my $cAnfrage3 = 'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/' .
                            $thisRecord->{'mms_id'} .
                            '/holdings/' .
                            $AddInfos{ $thisRecord->{'mms_id'} }->{'holding_id'} .
                            '/items/' .
                            '?apikey=' . $apiKey;

                        print ERRORLOG "------------- ANFRAGE 3 -----------------\n";
                        print ERRORLOG $cAnfrage3 . "\n";
                        print ERRORLOG "-----------------------------------------\n";
                        my $response3 = $ua3->request(
                            HTTP::Request->new(
                            GET => $cAnfrage3 ));

                        if ($response3->is_error()) {
                            printf "%s\n(3) " . $response3->status_line . "\n\tanfrage2: " .  $cAnfrage2 . "\n\tanfrage3: " . $cAnfrage3 . "\n";
                            printf ERRORLOG "%s\n(3) " . $response3->status_line . "\n";
                            print ERRORLOG "\tAnfrage2: " . $cAnfrage2 . "\n";
                            print ERRORLOG "\tAnfrage3: " . $cAnfrage3 . "\n";

                        } else {

                            #printf "%s\n(3ok) " . $response3->status_line . "\n\tanfrage2: " .  $cAnfrage2 . "\n\tanfrage3: " . $cAnfrage3 . "\n";
                            #https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/
                            #990011110250402561
                            #/holdings/
                            #22143340580002561
                            #/items/?apikey=

                            my $xml3 = $response3->content;


                            my $bookDetails = XMLin($xml3, ForceArray => 1);
                            print ERRORLOG "------------- STUFE 3 -----------------\n";
                            print ERRORLOG Dumper($bookDetails);

                            # Checken ob es einen Fehler gegeben hat
                            if (exists($bookDetails->{'errorsExist'}) and ($bookDetails->{'errorsExist'}[0] eq 'true')) {
                                print ERRORLOG __LINE__ . " Fehler in Anfrage\n";
                            } else {

                                my $thisRecordBookDetails = readRecordStufe3($bookDetails->{'item'}[0]->{'item_data'}[0]);

                                $AddInfos{ $thisRecord->{'mms_id'} }->{'type'} 		    = $thisRecordBookDetails->{'type'};
                                $AddInfos{ $thisRecord->{'mms_id'} }->{'statistik'} 	= $thisRecordBookDetails->{'statistik'};
                                $AddInfos{ $thisRecord->{'mms_id'} }->{'pid'} 		    = $thisRecordBookDetails->{'pid'};
                                $AddInfos{ $thisRecord->{'mms_id'} }->{'barcode'} 	    = $thisRecordBookDetails->{'barcode'};
                                
                                
                                # Daten jetzt an ausgabe Array ergänzen
                                #${$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}[$#${$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgabe'}}->{'type'} = $thisRecordBookDetails->{'type'};
                                ${$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}[$#{$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}]->{'type'}         = $thisRecordBookDetails->{'type'};
                                ${$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}[$#{$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}]->{'statistik'}    = $thisRecordBookDetails->{'statistik'};
                                ${$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}[$#{$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}]->{'pid'}          = $thisRecordBookDetails->{'pid'};
                                ${$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}[$#{$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}]->{'barcode'}      = $thisRecordBookDetails->{'barcode'};
                                
                                # Wenn Statisik leer ist handelt es sich um eine neue Bestellung
                                # hier muss die Statistik-Gruppe aus den Bestellposten abgefragt werden
                                # Mail von Bettina 29.10.2018 16:54
                                # https://api-eu.hosted.exlibrisgroup.com/almaws/v1/acq/po-lines/161837?apikey=l7xx47fa07838bfc483fa026b01adace59d4
                                # Die Statistikgruppe steht im Feld "secondary_reporting_code":
                                # Quelle für Verknüpungsid In der 3. Anfrage taucht das Feld
                                #'po_line' => [
                                #        '161837'
                                #      ], 
                                
                                if ($thisRecordBookDetails->{'statistik'} eq "") {
                                    
                                    if ($thisRecordBookDetails->{'po_line'} ne '') {
                                    
                                        #########################################
                                        # Jetzt Bestellposten anfangen
                                        #########################################
                                        my $cAnfrageBestellposten = 'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/acq/po-lines/' .
                                            $thisRecordBookDetails->{'po_line'} .
                                            '?apikey=' . $apiKey;

                                        print ERRORLOG "------------- ANFRAGE Bestellposten -----------------\n";
                                        print ERRORLOG $cAnfrageBestellposten . "\n";
                                        print ERRORLOG "-----------------------------------------\n";
                                        my $responsebestpost = $uabestpost->request(
                                            HTTP::Request->new(
                                            GET => $cAnfrageBestellposten ));

                                        if ($responsebestpost->is_error()) {
                                            printf "%s\n(3) " . $responsebestpost->status_line . "\n\tanfrageBestellposten: " .  $cAnfrageBestellposten . "\n";
                                            printf ERRORLOG "%s\n(3) " . $responsebestpost->status_line . "\n";
                                            print ERRORLOG "\tAnfrageBestellposten: " . $cAnfrageBestellposten . "\n";

                                        } else {
                                            
                                            my $xmlBestellposten = $responsebestpost->content;


                                            my $BestellDetails = XMLin($xmlBestellposten, ForceArray => 1);
                                            print ERRORLOG "------------- BestellDetails -----------------\n";
                                            print ERRORLOG Dumper($BestellDetails);

                                            # aus Bestellposten ermittelte Statistik speichern
                                            if (ref($BestellDetails->{'secondary_reporting_code'}[0]) eq 'HASH') {
                                                # Fehler wenn Hash Ursache klären! Tritt z.B. bei 
                                                #} elsif ($thisRecord->{'mms_id'} == '990005935980402561') { auf

                                            } else {
                                            
                                                $thisRecordBookDetails->{'statistik'} = $BestellDetails->{'secondary_reporting_code'}[0];
                                                $AddInfos{ $thisRecord->{'mms_id'} }->{'statistik'} 	= $thisRecordBookDetails->{'statistik'};
                                                ${$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}[$#{$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}]->{'statistik'}    = $thisRecordBookDetails->{'statistik'};
                                            }
                                            
                                        };
                                        #########################################
                                        # Jetzt Bestellposten ende
                                        #########################################
                                    } else {
                                        # Fehler keine po_line ermittelbar
                                    }
                                };
                            }

                            #########################################
                            # Jetzt 3. Stufe enden
                            #########################################


                            #------------------------------
                            # Stufe 4
                            # Wie Stufe 3 aber mit angabe der pid des titel und mit angabe view=label
                            #########################################
                            # Jetzt 3. Stufe anfangen
                            #########################################
                            #wie 2. Stufe nur andere Daten
                            # jetzt mit den Daten Weiterarbeiten und die dritte Stufe holen
                            # 3. Anfrage
                            # weitere Daten ermitteln
                            my $cAnfrage4 = 'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/' .
                                $thisRecord->{'mms_id'} .
                                '/holdings/' .
                                $AddInfos{ $thisRecord->{'mms_id'} }->{'holding_id'} .
                                '/items/' .
                                $AddInfos{ $thisRecord->{'mms_id'} }->{'pid'} .
                                '?apikey=' . $apiKey .
                                '&view=label';

                            print ERRORLOG "------------- ANFRAGE 4 -----------------\n";
                            print ERRORLOG $cAnfrage4 . "\n";
                            print ERRORLOG "-----------------------------------------\n";
                            my $response4 = $ua4->request(
                                HTTP::Request->new(
                                GET => $cAnfrage4 ));

                            if ($response4->is_error()) {
                                printf "%s\n(4) " . $response4->status_line . "\n";
                                printf ERRORLOG "%s\n(4) " . $response4->status_line . "\n";
                                print ERRORLOG "\t" . $cAnfrage4 . "\n";

                            } else {

                                #https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/
                                #990011110250402561
                                #/holdings/
                                #22143340580002561
                                #/items/
                                #23143340540002561
                                #?apikey=
                                #&view=label

                                my $xml4 = $response4->content;


                                my $bookDetails2 = XMLin($xml4, ForceArray => 1);
                                print ERRORLOG "------------- STUFE 4 -----------------\n";
                                print ERRORLOG Dumper($bookDetails2);

                                # Checken ob es einen Fehler gegeben hat
                                if (exists($bookDetails2->{'errorsExist'}) and ($bookDetails2->{'errorsExist'}[0] eq 'true')) {
                                    print ERRORLOG __LINE__ . " Fehler in Anfrage\n";
                                } else {

                                    my $thisRecordBookDetails = readRecordStufe4($bookDetails2->{'item_data'}[0]);

                                    $AddInfos{ $thisRecord->{'mms_id'} }->{'jahr'} = $thisRecordBookDetails->{'year'};
                                    $AddInfos{ $thisRecord->{'mms_id'} }->{'sprache'} = $thisRecordBookDetails->{'language'};
                                    
                                    ${$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}[$#{$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}]->{'jahr'} = $thisRecordBookDetails->{'year'};
                                    ${$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}[$#{$AddInfos{ $thisRecord->{'mms_id'} }->{'ausgaben'}}]->{'sprache'} = $thisRecordBookDetails->{'language'};
                                }

                                #########################################
                                # Jetzt 4. Stufe enden
                                #########################################





                                #-----------------------------------------------------------------------
                                # ermittelte Daten schreiben
                                #-----------------------------------------------------------------------
                                my $aktId = $thisRecord->{'mms_id'};

                                if ($AddInfos{$aktId}->{'type'} eq 'BOOK') {
                                    # Bei bestimmten Kriterien nicht in Datei schreiben sondern
                                    # in Fehlerdatei schreiben
                                    #CSVERRORLOG
                                    my $cTempSig = $AddInfos{$aktId}->{'call_number'};
                                    my $lSigOk  = $falsch;
                                    if ($cTempSig ne "") {
                                        if ($cTempSig =~ m/^$Frage_SigAnfang (.*?)$/) {
                                            $lSigOk = $wahr;
                                        }
                                    }

close $CSVERRORLOG;
open( $CSVERRORLOG, ">>$log_csv_error" ) or die "Kann nicht in $log_csv_error schreiben $!\n";

                                    if ($AddInfos{$aktId}->{'call_number'} eq '') {
                                        print_CSV( $CSVERRORLOG, \%AddInfos, $aktId, $falsch, $wahr );
                                    } elsif (!$lSigOk) {
                                        print_CSV( $CSVERRORLOG, \%AddInfos, $aktId, $falsch, $wahr );
                                    } elsif ($AddInfos{$aktId}->{'statistik'} eq '') {
                                        print_CSV( $CSVERRORLOG, \%AddInfos, $aktId, $falsch, $wahr );
                                    } elsif ($AddInfos{$aktId}->{'sprache'} eq '') {
                                        print_CSV( $CSVERRORLOG, \%AddInfos, $aktId, $falsch, $wahr );
                                    } else {


                                        #print $out 'Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Signatur|Fach' . "\n";

                                        print_CSV( $out, \%AddInfos, $aktId, $falsch, $falsch );

                                    }
                                }
                                print $nBookNr . ": " . $aktId . " " . $AddInfos{$aktId}->{'type'} . " " . $AddInfos{$aktId}->{'holding_id'} . "\n";
                                $nBookNr++;
                            }
                        }
                    }
                }
                
            #ende if (!$lEbooks)
            } else {

        #================================================
        # für ebooks
        #================================================
                # ---------------------------------------------------------------------
                # Prüfen ob es für diese mms_id ein portfolios gibt
                # um die Verfügbarkeit für den Benutzer festzustellen
                # wenn es <availability desc="Not Available">10</availability> dann
                # braucht der folgende Schritt nicht ausgeführt werden
                # ---------------------------------------------------------------------

                #<portfolios total_record_count="1">
                #<portfolio link="https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/9918449038002561/portfolios/53212785660002561">
                #   <id>53212785660002561</id>
                #   <is_local>true</is_local>
                #   <is_standalone>false</is_standalone>
                #   <resource_metadata>...</resource_metadata>
                #   <electronic_collection>...</electronic_collection>
                #   <availability desc="Not Available">10</availability>    <== 
                # or
                #   <availability desc="Available">11</availability>        <==
                #</portfolio>
                #</portfolios>
                
                my $lAvailability   = $falsch;

                my $cAnfragePortfolios = 'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/' .
                        $thisRecord->{'mms_id'} .
                        '/portfolios?apikey=' . $apiKey;

                print ERRORLOG "============ ANFRAGE Portfolios -----------------\n";
                print $cAnfragePortfolios . "\n";
                print ERRORLOG $cAnfragePortfolios . "\n";
                print ERRORLOG "--------------------------------------------------\n";
                
                my $responsePortfolios = $ua2->request(
                    HTTP::Request->new(
                    GET => $cAnfragePortfolios ));

                if ($responsePortfolios->is_error()) {
                    printf "%s\n(2) " . $responsePortfolios->status_line . "\n";
                    printf ERRORLOG "%s\n(2) " . $responsePortfolios->status_line . "\n";
                    print ERRORLOG "\t" . $cAnfragePortfolios . "\n";

                } else {

                    my $xmlPortfolios = $responsePortfolios->content;


                    my $portfolios = XMLin($xmlPortfolios, ForceArray => 1);

                    # <availability desc="Available">11</availability>
                    #$portfolios->{'portfolio'}[0]->{'availability'}[0]->{'desc'}   Not Available / Available
                    #$portfolios->{'portfolio'}[0]->{'availability'}[0]->{'content'}    10/11
                    if ($portfolios->{'portfolio'}[0]->{'availability'}[0]->{'content'} == 11) {
                        $lAvailability  = $wahr;
                    #<availability desc="Not Available">10</availability>
                    } elsif ($portfolios->{'portfolio'}[0]->{'availability'}[0]->{'content'} == 10) {
                        $lAvailability  = $falsch;
                    } else {
                        print ERRORLOG "Unbekannter Status: \n";
                        print ERRORLOG Dumper($portfolios);
                    }
                }




                if ($lAvailability) {
                    #--------------------------------------------------------------------------------
                    # jetzt mit den Daten Weiterarbeiten und die Zweite Stufe holen
                    # 2. Anfrage
                    # Daten bibs ermitteln
                    #--------------------------------------------------------------------------------                
                    my $cAnfrage2 = 'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/' .
                            $thisRecord->{'mms_id'} .
                            '?apikey=' . $apiKey;


                    print ERRORLOG "------------- ANFRAGE 2 -----------------\n";
                    print $cAnfrage2 . "\n";
                    print ERRORLOG $cAnfrage2 . "\n";
                    print ERRORLOG "-----------------------------------------\n";

                    my $response2 = $ua2->request(
                        HTTP::Request->new(
                        GET => $cAnfrage2 ));

                    if ($response2->is_error()) {
                        printf "%s\n(2) " . $response2->status_line . "\n";
                        #printf ERRORLOG "%s\n" . $response2->status_line ;
                        printf ERRORLOG "%s\n(2) " . $response2->status_line . "\n";
                        print ERRORLOG "\t" . $cAnfrage2 . "\n";

                    } else {



                        my $xml2 = $response2->content;


                        my $bibliograph = XMLin($xml2, ForceArray => 1);

                        print ERRORLOG "------------- STUFE 2 -ebooks----------------\n";

                        # Auflage
                        $AddInfos{ $thisRecord->{'mms_id'} }->{'auflage'} = $bibliograph->{'complete_edition'}[0];
                        
                    

                        # Jahr
                        # Sprache
                        # müssen aus subfeldern extrahiert werden

                        my $year            = '';
                        my $lang            = '';
                        #                                                            12345678901234567
                        my $isbn_13         = '';   # Langform der ISBN 13    z.B.: '978-3-7910-3705-9'
                        my $isbn_13_kompakt = '';   # Kompaktform der ISBN 13 ohne '-'
                        #                                                        1234567890123
                        my $isbn_10         = '';   # Langform der ISBN 10 z.B. '3-7910-3705-6'
                        my $isbn_10_kompakt = '';   # Kompaktform der ISBN 10 ohne '-'
                        
                        my %PrintParent     = ();
                        my $lPrintParent    = $falsch;

                        foreach my $akt (sort( keys($bibliograph->{'record'}[0]->{'datafield'}))) {
                            print $akt . ': ' . $bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'tag'} . "\n" if ($debug);
                            # Sprache
                            if ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'tag'} eq '041') {
                                if ($lang eq '') {
                                    $lang  = $bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[0]->{'content'};
                                };
                            }

                            # Year
                            if ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'tag'} eq '264') {
                                #$year = $bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[0]->{'content'};

                                foreach my $aktSub (sort( keys($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}))) {
                                    print $bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'code'} . "\n" if ($debug);
                                    if ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'code'} eq 'c') {
                                        if ($year eq '') {
                                            # year bereinigen
                                            my $tempYear = $bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'content'};
                                            $tempYear =~ s/^©\s//;
                                            $year = $tempYear;

                                        };
                                    }
                                }
                            }

                            #---------------------------------
                            # auch erschienen unter 776 ev. aber auch 775?? 101 Fragen und Antworten im Vorstellung
                            # 776 muss nur durchsucht werden wenn in 775 noch nichts gefunden wurde 
                            #---------------------------------
                            if (($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'tag'} eq '775') || ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'tag'} eq '776') and !$lPrintParent ) {


                                foreach my $aktSub (sort( keys($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}))) {
                                    print $bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'code'} . "\n" if ($debug);

                                    # prüfen einiger Daten da bisher keinen Überblick
                                    # Erscheint auch als Druckausgabe prüfen
                                    if ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'code'} eq 'n') {
                                        if ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'content'} eq 'Druck-Ausgabe') {
                                            $lPrintParent = $wahr;
                                        }
                                    } elsif ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'code'} eq 'i') {
                                        if (($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'content'} eq 'Buchausg. u.d.T.') || 
                                            ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'content'} eq 'Erscheint auch als') ||
                                            ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'content'} eq 'Druckausg.')) {
                                            $lPrintParent = $wahr;
                                        }
                                    # Author
                                    } elsif ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'code'} eq 'a') {
                                        my $tempAutor = $bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'content'};

                                        # 'Haratsch, Andreas, 1963 - '
                                        # entferne , Jahr -
                                        if ($tempAutor =~ m/(.*?)[,](.*?)[,](.*?)/) {
                                            $PrintParent{'author'} = $1 . ',' . $2;
                                        } else {
                                            $PrintParent{'author'} = $tempAutor;
                                        };
                                        $lPrintParent = $wahr;
                                        

                                    # Titel
                                    } elsif ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'code'} eq 't') {
                                        $PrintParent{'title'} = $bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'content'};
                                        # ev. auch eine um Sonderzeichen wie punkt komma doppelpunkt bindestriche bereinigte Titelversion
                                        # ggf. damit einen Treffer versuchen. Ev. auch nicht die volle Länge!
                                        $PrintParent{'title_ohne_satzzeichen'}  = $bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'content'};
                                        $PrintParent{'title_ohne_satzzeichen'} =~ s/[\.\;\:]//g;
                                        
                                        $lPrintParent = $wahr;

                                    # ISBN 10/13
                                    } elsif ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'code'} eq 'z') {
                                        $lPrintParent = $wahr;
                                            
                                        # ggf. sind mehr als eine ISBN abfragbar
                                        # isbn 13 mit '-'
                                        if (length($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'content'}) == 17) {
                                            $PrintParent{'isbn_13'} = $bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'content'};
                                            $PrintParent{'isbn_13_kompakt'} =  $PrintParent{'isbn_13'};
                                            $PrintParent{'isbn_13_kompakt'} =~ s/-//g;
                                        }
                                        # isbn 10 mit '-'
                                        if (length($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'content'}) == 13) {
                                            $PrintParent{'isbn_10'} = $bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'subfield'}[$aktSub]->{'content'};
                                            $PrintParent{'isbn_10_kompakt'} =  $PrintParent{'isbn_10'};
                                            $PrintParent{'isbn_10_kompakt'} =~ s/-//g;
                                        }
                                    }
                                }


                                # macht nur Sinn wenn ein PrintParent entdeckt wurde
                                if ($lPrintParent) {
                                    #-------------------------------------------------------
                                    # @BookData enthält die Datein der BookCSV-Datei
                                    #-------------------------------------------------------
                                    
                                    my $lTreffer = $falsch;

                                    # prüfen ob die Daten in %PrintParent in @BookData gefunden werden können
                                    #Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Signatur|Fach
                                    #Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Publisher|Signatur|Fach
                                    foreach my $aktBookData (@BookData) {
                                        #print $aktBookData . "\n";
                                        if ((exists($PrintParent{'title'}) && lc($aktBookData->{'Titel'}) eq lc($PrintParent{'title'}))) {
                                            if (exists($PrintParent{'author'}) && ($aktBookData->{'Autor'} eq $PrintParent{'author'}) || $aktBookData->{'Autor'} eq '' ) {

                                                $AddInfos{ $thisRecord->{'mms_id'} }->{'statistik'}     = $aktBookData->{'Fach'};
                                                
                                                # Achtung die Signatur wird etwas bearbeitet und zwar wird die "120 " ==> LKZ abgeschnitten
                                                my $tempSig   = $aktBookData->{'Signatur'};
                                                $tempSig  =~ m/^
                                                    (\d{3})         # 1 3 Zahlen
                                                    (\s+)           # 2   Leerzeichen
                                                    ([a-zA-Z]{2})   # 3 2 zwei Buchstaben
                                                    (\s+)           # 4   Leerzeichen
                                                    (.*?)           # 5   beliebige Zeichen
                                                    $
                                                /x;

                                                $tempSig = $3 . $4 . $5;

                                                # Match / Treffer
                                                $AddInfos{ $thisRecord->{'mms_id'} }->{'call_number'}   = $tempSig;
                                                
                                                # für dieses Buch gibt es ein eBook
                                                $hBookData{$aktBookData->{'Signatur'}}->{'alsEBook'}    = $wahr;
                                                $hBookData{$aktBookData->{'Signatur'}}->{'data'}        = $AddInfos{ $thisRecord->{'mms_id'} };
                                                $hBookData{$aktBookData->{'Signatur'}}->{'dataLink'}    = $thisRecord->{'mms_id'};
                                                
                                                $lTreffer = $wahr;
                                                last;
                                            }
                                        }
                                    }
                                    
                                    # Wenn kein Treffer
                                    # Jetzt mit der isbn_10/13 oder isbn_10/13_kompakt versuchen
                                    if (!$lTreffer){
                                        foreach my $aktBookData (@BookData) {
                                            my $lTrefferIsbn = $falsch;
                                            if (exists($PrintParent{'isbn_13'}) && exists($PrintParent{'isbn_10'})) {
                                                if (
                                                    (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_13'})) || 
                                                    (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_13_kompakt'})) || 
                                                    (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_10'})) || 
                                                    (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_10_kompakt'})) ) {
                                                    $lTrefferIsbn   = $wahr;
                                                }
                                            } elsif (exists($PrintParent{'isbn_13'})) {
                                                if (
                                                    (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_13'})) || 
                                                    (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_13_kompakt'}))) {
                                                    $lTrefferIsbn   = $wahr;
                                                }
                                            } elsif (exists($PrintParent{'isbn_10'})) {
                                                if (
                                                    (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_10'})) || 
                                                    (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_10_kompakt'}))) {
                                                    $lTrefferIsbn   = $wahr;
                                                }
                                            }
                                            
                                            if ($lTrefferIsbn) {
                                                $AddInfos{ $thisRecord->{'mms_id'} }->{'statistik'}     = $aktBookData->{'Fach'};
                                                
                                                # Achtung die Signatur wird etwas bearbeitet und zwar wird die "120 " => LKZ abgeschnitten
                                                my $tempSig   = $aktBookData->{'Signatur'};
                                                $tempSig  =~ m/^
                                                    (\d{3})         # 1 3 Zahlen
                                                    (\s+)           # 2   Leerzeichen
                                                    ([a-zA-Z]{2})   # 3 2 zwei Buchstaben
                                                    (\s+)           # 4   Leerzeichen
                                                    (.*?)           # 5   beliebige Zeichen
                                                    $
                                                /x;

                                                $tempSig = $3 . $4 . $5;

                                                # Match / Treffer
                                                $AddInfos{ $thisRecord->{'mms_id'} }->{'call_number'}   = $tempSig;
                                                
                                                # für dieses Buch gibt es ein eBook
                                                $hBookData{$aktBookData->{'Signatur'}}->{'alsEBook'}    = $wahr;
                                                $hBookData{$aktBookData->{'Signatur'}}->{'data'}        = $AddInfos{ $thisRecord->{'mms_id'} };
                                                $hBookData{$aktBookData->{'Signatur'}}->{'dataLink'}    = $thisRecord->{'mms_id'};
                                                
                                                $lTreffer = $wahr;
                                                last;

                                            };
                                        };
                                    }; # if (!$lTreffer)
                                };   # if ($lPrintParent) {
                            }; #if (($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'tag'} eq '775') || ($bibliograph->{'record'}[0]->{'datafield'}[$akt]->{'tag'} eq '776') and !$lPrintParent ) {
                        };  #foreach my $akt (sort( keys($bibliograph->{'record'}[0]->{'datafield'}))) {
                        
                        



                        # Prüfen ob Daten nachgetragen werden können, 
                        # das müsste ev. noch verschoben werden!
                        if ($AddInfos{ $thisRecord->{'mms_id'} }->{'call_number'} eq '') {
                            
                            # macht nur Sinn wenn ein PrintParent entdeckt wurde
                            if ($lPrintParent) {
                                #-----------------------------------------------------------------------------------
                                # noch prüfen ob über die isbn_10/13 oder isbn_10/13_kompakt ein match durchgeführt werden kann
                                #-----------------------------------------------------------------------------------
                                #
                                # @BookData enthält die Datein der BookCSV-Datei
                                #
                                # prüfen ob die Daten in %PrintParent in @BookData gefunden werden können
                                #Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Signatur|Fach
                                foreach my $aktBookData (@BookData) {

                                    my $lTrefferIsbn = $falsch;
                                    if (exists($PrintParent{'isbn_13'}) && exists($PrintParent{'isbn_10'})) {
                                        if (
                                            (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_13'})) || 
                                            (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_13_kompakt'})) || 
                                            (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_10'})) || 
                                            (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_10_kompakt'})) ) {
                                            $lTrefferIsbn   = $wahr;
                                        }
                                    } elsif (exists($PrintParent{'isbn_13'})) {
                                        if (
                                            (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_13'})) || 
                                            (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_13_kompakt'}))) {
                                            $lTrefferIsbn   = $wahr;
                                        }
                                    } elsif (exists($PrintParent{'isbn_10'})) {
                                        if (
                                            (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_10'})) || 
                                            (lc($aktBookData->{'ISBN'}) eq lc($PrintParent{'isbn_10_kompakt'}))) {
                                            $lTrefferIsbn   = $wahr;
                                        }
                                    }
                                    
                                    if ($lTrefferIsbn) {

                                        $AddInfos{ $thisRecord->{'mms_id'} }->{'statistik'}     = $aktBookData->{'Fach'};
                                        
                                        # Achtung die Signatur wird etwas bearbeitet und zwar wird die "120 " ==> LKZ abgeschnitten
                                        my $tempSig   = $aktBookData->{'Signatur'};
                                        $tempSig  =~ m/^
                                            (\d{3})         # 1 3 Zahlen
                                            (\s+)           # 2   Leerzeichen
                                            ([a-zA-Z]{2})   # 3 2 zwei Buchstaben
                                            (\s+)           # 4   Leerzeichen
                                            (.*?)           # 5   beliebige Zeichen
                                            $
                                        /x;

                                        $tempSig = $3 . $4 . $5;

                                        # Match / Treffer
                                        $AddInfos{ $thisRecord->{'mms_id'} }->{'call_number'}   = $tempSig;

                                        # für dieses Buch gibt es ein eBook
                                        $hBookData{$aktBookData->{'Signatur'}}->{'alsEBook'}    = $wahr;
                                        $hBookData{$aktBookData->{'Signatur'}}->{'data'}        = $AddInfos{ $thisRecord->{'mms_id'} };
                                        $hBookData{$aktBookData->{'Signatur'}}->{'dataLink'}    = $thisRecord->{'mms_id'};
                                    }
                                }
                                # noch prüfen ob über die isbn oder kurzisbn ein match durchgeführt werden kann ENDE
                            } else {
                                #--------------------------------------------------------------------
                                # trotdem mit der isbn suchen, manchmal liefert das einen Treffer
                                #--------------------------------------------------------------------
                                
                                foreach my $aktBookData (@BookData) {
                                    #print $aktBookData . "\n";

                                    if (lc($aktBookData->{'ISBN'}) eq lc($AddInfos{ $thisRecord->{'mms_id'} }->{'isbn'})) {

                                        $AddInfos{ $thisRecord->{'mms_id'} }->{'statistik'}     = $aktBookData->{'Fach'};
                                        # Achtung die Signatur wird etwas bearbeitet und zwar wird die "120 " abgeschnitten
                                        my $tempSig   = $aktBookData->{'Signatur'};
                                        $tempSig  =~ m/^
                                            (\d{3})         # 1 3 Zahlen
                                            (\s+)           # 2   Leerzeichen
                                            ([a-zA-Z]{2})   # 3 2 zwei Buchstaben
                                            (\s+)           # 4   Leerzeichen
                                            (.*?)           # 5   beliebige Zeichen
                                            $
                                        /x;

                                        $tempSig = $3 . $4 . $5;

                                        # Match / Treffer
                                        $AddInfos{ $thisRecord->{'mms_id'} }->{'call_number'}   = $tempSig;

                                        # für dieses Buch gibt es ein eBook
                                        $hBookData{$aktBookData->{'Signatur'}}->{'alsEBook'}    = $wahr;
                                        $hBookData{$aktBookData->{'Signatur'}}->{'data'}        = $AddInfos{ $thisRecord->{'mms_id'} };
                                        $hBookData{$aktBookData->{'Signatur'}}->{'dataLink'}    = $thisRecord->{'mms_id'};
                                        
                                    };  # if (lc($aktBookData->{'ISBN'}) eq lc($AddInfos{ $thisRecord->{'mms_id'} }->{'isbn'})) {
                                };   # foreach my $aktBookData (@BookData) {
                            };   # if ($lPrintParent) { / else
                            
                            
                            # zweiter Test, ist Signatur immer noch leer?
                            # Dann Zuordnung einer Temporären Signatur am Ende
                            if ($AddInfos{ $thisRecord->{'mms_id'} }->{'call_number'} eq '') {
                                $nBooksWithoutMatch++;
                                $AddInfos{ $thisRecord->{'mms_id'} }->{'call_number'}   = 'ZZ 999 Z9999';
                                $AddInfos{ $thisRecord->{'mms_id'} }->{'statistik'}     = '01';
                            };
                        };  # if ($AddInfos{ $thisRecord->{'mms_id'} }->{'call_number'} eq '') {


                        $AddInfos{ $thisRecord->{'mms_id'} }->{'sprache'}   =  $lang;
                        $AddInfos{ $thisRecord->{'mms_id'} }->{'jahr'}      =  $year;
                        $AddInfos{ $thisRecord->{'mms_id'} }->{'url'}       =  'https://primo.bib.uni-mannheim.de/primo-explore/search?tab=default_tab&search_scope=MAN_ALMA&vid=MAN_UB&lang=de_DE&offset=0&query=any,contains,' . $thisRecord->{'mms_id'};


                        print $nBookNr . ": " . $thisRecord->{'mms_id'} . " ebook " . $AddInfos{$thisRecord->{'mms_id'}}->{'type'} . "\n";
                        $nBookNr++;

                        print_CSV( $out, \%AddInfos, $thisRecord->{'mms_id'}, $wahr, $falsch );
                    }
                };   # if $lAvailability
            }
        }
    }


    $nOffset += $nLimit;
    print $nOffset . "\n";

} until ($nAktBookAnzahl >= $nBookAnzahl);

close $CSVERRORLOG;

# Liste der Books ohne eBooks
print $CSVOHNEEBOOK "Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Publisher|Signatur|Fach\n";
foreach my $aktBook (sort {$a cmp $b} (keys(%hBookData))) {
    if (!$hBookData{$aktBook}->{'alsEBook'}) {
        print $CSVOHNEEBOOK $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Aleph-ID'} . "|";
        print $CSVOHNEEBOOK $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Autor'} . "|";
        print $CSVOHNEEBOOK $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Titel'} . "|";
        print $CSVOHNEEBOOK $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Auflage'} . "|";
        print $CSVOHNEEBOOK $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Jahr'} . "|";
        print $CSVOHNEEBOOK $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'ISBN'} . "|";
        print $CSVOHNEEBOOK $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Sprache'} . "|";
        print $CSVOHNEEBOOK $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Publisher'} . "|";
        print $CSVOHNEEBOOK $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Signatur'} . "|";
        print $CSVOHNEEBOOK $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Fach'} . "\n";

    #print_CSV( $CSVOHNEEBOOK, \%AddInfos, $aktId, $falsch, $wahr );
    } else {
        print $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Aleph-ID'} . "|";
        print $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Autor'} . "|";
        print $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Titel'} . "|";
        print $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Auflage'} . "|";
        print $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Jahr'} . "|";
        print $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'ISBN'} . "|";
        print $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Sprache'} . "|";
        print $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Publisher'} . "|";
        print $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Signatur'} . "|";
        print $BookData[$hBookData{$aktBook}->{'nIndex'}]->{'Fach'} . "\n";
    }
}

close $CSVOHNEEBOOK;

if ($lEbooks) {
    print $nBookNr . "\n";
    print $nBooksWithoutMatch . "\n";
}

#Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Signatur|Fach
sub readRecordStufe1 {
    my $record          = shift();
    my $lSkipSubTitle   = shift();
    my $cStartSkipWith  = shift();

    my %data            = ();

    # AlmaID
    $data{'mms_id'}     = $record->{'mms_id'}[0];
    $data{'isbn'}       = $record->{'isbn'}[0];
    $data{'author'}    	= $record->{'author'}[0];
    $data{'title'}     	= $record->{'title'}[0];
    $data{'publisher'}  = $record->{'publisher_const'}[0];

    # Abschliessende LZ entfernen
    $data{'title'}      =~ s/\s+$//;

    # title sometimes with ending '/'
    $data{'title'} =~ s/^(.*?)\s\/$/$1/;

    if ($lSkipSubTitle) {
        if ($data{'title'} =~ m/(.*?)$cStartSkipWith(.*?)/) {
            $data{'title'} = $1;

            # Abschliessende LZ entfernen
            $data{'title'}      =~ s/\s+$//;
        };
    };


    # vorbelegen mit dummywerten der zu ergänzenden Felder
    $data{'call_number'} = '';
    $data{'holding_id'} = '';
    $data{'location'} = '';
    $data{'location_id'} = '';
    #
    $data{'statistik'} = '';
    $data{'type'} = '';
    $data{'auflage'} = '';
    $data{'jahr'} = '';
    $data{'sprache'} = '';

    # Stufe 1 Daten eines Buches werden zurückgemeldet
    return(\%data);
}

sub readRecordStufe2 {
    my $record = shift();
    my %data = ();
    print ERRORLOG "readRecordStufe2()\n";
    print ERRORLOG Dumper($record);

    # AlmaID
    $data{'call_number'} = $record->{'call_number'}[0];
    $data{'holding_id'} = $record->{'holding_id'}[0];

    # Achtung location enthält manchmal kein weiteren Hash
    if (ref($record->{'location'}[0]) eq 'HASH') {
        if (exists($record->{'location'}[0]->{'desc'})) {
            $data{'location'} = $record->{'location'}[0]->{'desc'};
            $data{'location_id'} = $record->{'location'}[0]->{'content'};
        } else {
            $data{'location'} = $record->{'location'}[0];
            $data{'location_id'} = $record->{'location'}[0];
        }
    } else {
        $data{'location'} = $record->{'location'}[0];
        $data{'location_id'} = $record->{'location'}[0];
    }

    # Stufe 2 Daten eines Buches werden zurückgemeldet
    return(\%data);
}


sub readRecordStufe3 {
    my $record = shift();
    my %data = ();

    # item / item_data / physical_material_type / content => BOOK
    # item / item_data / statistics_note_1 => Item Statistics: 28///1


    # AlmaID
    $data{'type'} = $record->{'physical_material_type'}[0]->{'content'};

    # wg. Fehlerliste
    $data{'barcode'} = $record->{'barcode'}[0];
    $data{'pid'} = $record->{'pid'}[0];


    my $cTemp = $record->{'statistics_note_1'}[0];
    if (ref($record->{'statistics_note_1'}[0]) eq 'HASH') {
        print ERRORLOG __LINE__ . " Fehler wg. Hash $cTemp\n";
        $cTemp = '';
    } else {
        if ($cTemp =~ m/^Item Statistics: (\d{2,2})\/(.*?)$/) {
            $cTemp =~ s/^Item Statistics: (\d{2,2})\/(.*?)$/$1/;
        } else {
            if ($cTemp =~ m/(\d{2,2})$/) {
                $cTemp = $1;
            } else {
                print ERRORLOG __LINE__ . " Fehler Unklar $cTemp\n";
                $cTemp = '';
            }
        }
    }
    $data{'statistik'} = $cTemp;
    
    # Bestellposten Verknüpungsid
    $data{'po_line'} = $record->{'po_line'}[0];


    # Stufe 3 Daten eines Buches werden zurückgemeldet
    return(\%data);
}


sub readRecordStufe4 {
    my $record = shift();
    my %data = ();

    # item_data / imprint =>  'Stuttgart ; Metzler 2001' statt ; kann auch : vorkommen
    # item_data / 'language' =>  'ger'


    my $cTempLang = $record->{'language'}[0];
    if (ref($record->{'language'}[0]) eq 'HASH') {
        print ERRORLOG __LINE__ . " Fehler wg. Hash $cTempLang\n";
        $cTempLang = '';
    } else {
        $cTempLang = $record->{'language'}[0];
    }
    $data{'language'} = $cTempLang;
    

    my $cImprint = $record->{'imprint'}[0];

    if (ref($record->{'imprint'}[0]) eq 'HASH') {
        print ERRORLOG __LINE__ . " Fehler wg. Hash $cImprint\n";
        $cImprint  = '';
    } else {
        #if ($cImprint  =~ m/^(.*?)\s;\s(.*?)\s([\d\.\[\]]{4,6})$/) {
        if ($cImprint  =~ m/^(.*?)\s[;:]\s(.*?)\s([\d\.\[\]]{4,7})$/) {
            $cImprint = $3;
        } else {
        print ERRORLOG __LINE__ . " Fehler Unklar $cImprint\n";
        }
    }
    $data{'year'} = $cImprint;

    # Stufe 4 Daten eines Buches werden zurückgemeldet
    return(\%data);
}



sub TransformWinPathToPerl {
    my $cPath   = shift();
    $cPath =~ s/\\/\//g;
    return( $cPath );
}



sub print_CSV {
    my $out         = shift();
    my $AddInfos    = shift();
    my $aktId       = shift();
    my $lEBook	    = shift();
    my $lError      = shift();

    print $out ${$AddInfos}{$aktId}->{'mms_id'} . '|';

#  HASH(0x31f9938)
#   'auflage' => '4., neubearbeitete Auflage'
#   'ausgaben' => ARRAY(0x32aecb0)
#      0  HASH(0x32998a0)
#         9917858664402561 => HASH(0x329e9c0)
#              empty hash
#         'auflage' => '4., neubearbeitete Auflage'
#         'barcode' => 918529516180
#         'call_number' => '120 PD 3006 B734(4)'
#         'holding_id' => 22167611800002561
#         'jahr' => '[2016]'
#         'pid' => 23163440330002561
#         'sprache' => 'ger'
#         'statistik' => ''
#         'type' => 'BOOK'
#   'author' => 'Bork, Reinhard'
#   'call_number' => '120 PD 3006 B734(4)'
#   'holding_id' => 22167611800002561
#   'isbn' => 9783161544477
#   'jahr' => '[2016]'
#   'location' => ''
#   'location_id' => ''
#   'mms_id' => 9917858664402561
#   'pid' => 23163440330002561
#   'publisher' => 'Mohr Siebeck,'
#   'sprache' => 'ger'
#   'statistik' => ''
#   'title' => 'Allgemeiner Teil des B�rgerlichen Gesetzbuchs'
#   'type' => 'BOOK'


    
    #foreach my $akt (@{${$AddInfos}{$aktId}->{'ausgaben'}}) {
        if ($lError) {
            if (!$lEBook) {
                print $out ${$AddInfos}{$aktId}->{'barcode'} . '|';
            }
        }
        
        
        if (${$AddInfos}{$aktId}->{'author'} ne '') {
            print $out ${$AddInfos}{$aktId}->{'author'} . '|';
        } else {
            print $out '|';
        }
        if (${$AddInfos}{$aktId}->{'title'} ne '') {
            print $out ${$AddInfos}{$aktId}->{'title'} . '|';
        } else {
            print $out '|';
        }
        if (exists(${$AddInfos}{$aktId}->{'auflage'}) && ${$AddInfos}{$aktId}->{'auflage'} ne '') {
            print $out ${$AddInfos}{$aktId}->{'auflage'} . '|';
        } else {
            print $out '|';
        }
        if (${$AddInfos}{$aktId}->{'jahr'} ne '') {
            print $out ${$AddInfos}{$aktId}->{'jahr'} . '|';
        } else {
            print $out '|';
        }
        if (${$AddInfos}{$aktId}->{'isbn'} ne '') {
            print $out ${$AddInfos}{$aktId}->{'isbn'} . '|';
        } else {
            print $out '|';
        }
        if (${$AddInfos}{$aktId}->{'sprache'} ne '') {
            print $out ${$AddInfos}{$aktId}->{'sprache'} . '|';
        } else {
            print $out '|';
        }

        if (!$lEBook) {
        # neu 18.10.2018 Ft
            if (${$AddInfos}{$aktId}->{'publisher'} ne '') {
                print $out ${$AddInfos}{$aktId}->{'publisher'} . '|';
            } else {
                print $out '|';
            }

            if (${$AddInfos}{$aktId}->{'call_number'} ne '') {
                print $out ${$AddInfos}{$aktId}->{'call_number'} . '|';
            } else {
                print $out '|';
            }

            # Letztes Feld nicht mit | abschliesen
            if (${$AddInfos}{$aktId}->{'statistik'} ne '') {
                print $out ${$AddInfos}{$aktId}->{'statistik'};
            } else {
                #print $out '|';
            }
        } else {
            # nur bei $lEBook
            if (${$AddInfos}{$aktId}->{'statistik'} ne '') {
                print $out ${$AddInfos}{$aktId}->{'statistik'} . '|';
            } else {
                print $out '|';
            }
            if (${$AddInfos}{$aktId}->{'call_number'} ne '') {
                print $out ${$AddInfos}{$aktId}->{'call_number'} . '|';
            } else {
                print $out '|';
            }
            # Letztes Feld nicht mit | abschliesen
            if (${$AddInfos}{$aktId}->{'url'} ne '') {
                print $out ${$AddInfos}{$aktId}->{'url'};
            } else {
                #print $out '|';
            }
        }
    #}

    print $out "\n";
}

