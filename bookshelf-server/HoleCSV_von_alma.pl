#!/usr/bin/perl -w
#-------------------------------------------------------------------------------
# Copyright (C) 2016 Universitätsbibliothek Mannheim
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
# Hinweis:
# 	Funktioniert aktuell nur bei books für die vorher in Alma eine Sammlung eingetragen wurde
#
#-------------------------------------------------------------------------------
# Feldreihenfolge bei den CSV-Dateien
# bei ebooks
#RecordID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Fach|Signatur|URL
# bei prints
#Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Signatur|Fach

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
use Text::CSV::Simple;
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

#-------------------------------------------------------------------------------
# Altes CSV-Fehler Protokoll leeren
#-------------------------------------------------------------------------------
my $log_csv_error = __FILE__ . ".csv_error.log";
open( my $CSVERRORLOG, ">$log_csv_error" ) or die "Kann nicht in $log_csv_error schreiben $!\n";



GetOptions(
		# Errolog beim Starten loeschen
		"resetlog"                              => \$lresetlog,
        );


#--------------------------------------------------------------
# wenn gewünscht ist das das Errorlog zurückgesetzt wird
#--------------------------------------------------------------
if ($lresetlog)
{
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
my $apiKey  = $cfg->val( 'ALMA', 'apiKey' );
my $cSkipSubTitle = $cfg->val( 'ALMA', 'skipSubtitles' );
my $lSkipSubTitle = 0;
my $cStartSkipWith = ':';

if (lc($cSkipSubTitle) eq 'yes' || lc($cSkipSubTitle) eq 'ja') {
	$lSkipSubTitle = 1;
	$cStartSkipWith = $cfg->val( 'ALMA', 'SkipStartWith' );
}


my $sourceDir = TransformWinPathToPerl($cfg->val( 'PATH', 'csv' ));
if ($sourceDir =~ m/^(.*?)\/$/) {
    $sourceDir = $1;
}


# 'learningcenter_print.csv';   # default für print-csv-Datei
my $pSourceFilePrint        = $cfg->val( 'CSV', 'print' );

my $SourceFilePrint          = $sourceDir . '/' . $pSourceFilePrint;

open(my $out, ">:utf8", $SourceFilePrint) or die
    "Kann OUT File $SourceFilePrint nicht oeffnen ($!)\n";



print $out 'Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Signatur|Fach' . "\n";

my $ua          = LWP::UserAgent->new;
my $ua2         = LWP::UserAgent->new;
my $ua3         = LWP::UserAgent->new;
my $ua4         = LWP::UserAgent->new;

#'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/collections/' . $collection . '/bibs?apikey=' . $apiKey
my $nOffset = 0;
my $nLimit = 100;

my $nBookAnzahl = 1000;
my $nAktBookAnzahl = 0;
my $nBookNr = 0;


do {

	$nAktBookAnzahl += $nLimit;
	# 1. Anfrage
	my $cAnfrage1 = 'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/collections/' .
		$collection . '/bibs?apikey=' . $apiKey .
		'&offset=' . $nOffset .
		'&limit=' . $nLimit;
	print ERRORLOG "------------- ANFRAGE 1 -----------------\n";
	print ERRORLOG $cAnfrage1 . "\n";
	print ERRORLOG "-----------------------------------------\n";

	my $cRequest1 = 'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/collections/' .
		    $collection . '/bibs?apikey=' . $apiKey .
		    '&offset=' . $nOffset .
		    '&limit=' . $nLimit;

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

		my %AddInfos = ();

		foreach my $aktRecord (@{$bibBooks->{'bib'}}) {
			my $thisRecord = readRecordStufe1($aktRecord, $lSkipSubTitle, $cStartSkipWith);

			$AddInfos{ $thisRecord->{'mms_id'} } = $thisRecord;
			#print $nBookNr . ": " . $thisRecord->{'mms_id'} . "\n";


			# jetzt mit den Daten Weiterarbeiten und die Zweite Stufe holen
			# 2. Anfrage
			# Holding_id ermitteln
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

				if (($thisRecord->{'mms_id'} eq "990015538210402561") or ($thisRecord->{'mms_id'} eq "990011530170402561")) {
					sleep(1);
				}

				foreach my $aktRecord (@{$holdings->{'holding'}}) {
					my $thisRecordHolding = readRecordStufe2($aktRecord);
					if ($thisRecordHolding->{'location_id'} eq '110') {
						$AddInfos{ $thisRecord->{'mms_id'} }->{'call_number'} = $thisRecordHolding->{'call_number'};
						$AddInfos{ $thisRecord->{'mms_id'} }->{'holding_id'} = $thisRecordHolding->{'holding_id'};
						last;
					}
				}
				# Weitere Daten holen
				$AddInfos{ $thisRecord->{'mms_id'} }->{'auflage'} = $holdings->{'bib_data'}[0]->{'complete_edition'}[0];





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
					printf "%s\n(3) " . $response3->status_line . "\n";
					printf ERRORLOG "%s\n(3) " . $response3->status_line . "\n";
					print ERRORLOG "\t" . $cAnfrage3 . "\n";

				} else {

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

						$AddInfos{ $thisRecord->{'mms_id'} }->{'type'} = $thisRecordBookDetails->{'type'};
						$AddInfos{ $thisRecord->{'mms_id'} }->{'statistik'} = $thisRecordBookDetails->{'statistik1'};
						$AddInfos{ $thisRecord->{'mms_id'} }->{'pid'} = $thisRecordBookDetails->{'pid'};
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
								if ($cTempSig =~ m/^110 (.*?)$/) {
									$lSigOk = $wahr;
								}
							}

							if ($AddInfos{$aktId}->{'call_number'} eq '') {
								print_CSV( $CSVERRORLOG, \%AddInfos, $aktId, $wahr );
							} elsif (!$lSigOk) {
								print_CSV( $CSVERRORLOG, \%AddInfos, $aktId, $wahr );
							} elsif ($AddInfos{$aktId}->{'statistik'} eq '') {
								print_CSV( $CSVERRORLOG, \%AddInfos, $aktId, $wahr );
							} else {


								#print $out 'Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Signatur|Fach' . "\n";

								print_CSV( $out, \%AddInfos, $aktId, $falsch );

							}
						}
						print $nBookNr . ": " . $aktId . " " . $AddInfos{$aktId}->{'type'} . " " . $AddInfos{$aktId}->{'holding_id'} . "\n";
						$nBookNr++;
					}
				}
			}
                }
        }


	$nOffset += $nLimit;
	print $nOffset . "\n";

} until ($nAktBookAnzahl >= $nBookAnzahl);

close $CSVERRORLOG;

#Aleph-ID|Autor|Titel|Aufl.|Jahr|ISBN|SPRACHE|Signatur|Fach
sub readRecordStufe1 {
    my $record = shift();
    my $lSkipSubTitle = shift();
    my $cStartSkipWith = shift();
    my %data = ();

    # AlmaID
    $data{'mms_id'} = $record->{'mms_id'}[0];
    $data{'isbn'} = $record->{'isbn'}[0];
    $data{'author'} = $record->{'author'}[0];
    $data{'title'} = $record->{'title'}[0];
    
    # title sometimes with ending '/'
    $data{'title'} =~ s/^(.*?)\s\/$/$1/;
    
    if ($lSkipSubTitle) {
	if ($data{'title'} =~ m/(.*?)$cStartSkipWith(.*?)/) {
		$data{'title'} = $1;
	};
    };


    # vorbelegen mit dummywerten der zu ergänzenden Felder
    $data{'call_number'} = '';
    $data{'holding_id'} = '';
    $data{'location'} = '';
    $data{'location_id'} = '';
    #
    $data{'statistik1'} = '';
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
    $data{'statistik1'} = $cTemp;


    # Stufe 3 Daten eines Buches werden zurückgemeldet
    return(\%data);
}


sub readRecordStufe4 {
    my $record = shift();
    my %data = ();

    # item_data / imprint =>  'Stuttgart ; Metzler 2001' statt ; kann auch : vorkommen
    # item_data / 'language' =>  'ger'



    $data{'language'} = $record->{'language'}[0];

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
    my $lError      = shift();

    print $out ${$AddInfos}{$aktId}->{'mms_id'} . '|';
    if ($lError) {
        print $out ${$AddInfos}{$aktId}->{'barcode'} . '|';
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
    if (${$AddInfos}{$aktId}->{'auflage'} ne '') {
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
    print $out "\n";
}
