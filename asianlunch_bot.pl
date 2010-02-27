#!/opt/local/bin/perl

use strict;
use warnings;

use utf8;
use Encode qw/from_to/;
use Date::Calc qw/Today/;
use IO::Socket::SSL;
use Mail::IMAPClient;
use MIME::Base64;
use Net::Twitter::Lite;
use Carp;
use Data::Dumper;
use List::MoreUtils qw/notall/;
use Config::Pit;

use FindBin;
use lib "$FindBin::Bin/./lib";
use AsianLunch;

my %month_of = (
    1  => "Jan",
    2  => "Feb",
    3  => "Mar",
    4  => "Apr",
    5  => "May",
    6  => "Jun",
    7  => "Jul",
    8  => "Aug",
    9  => "Sep",
    10 => "Oct",
    11 => "Nov",
    12 => "Dec",
);

my $config = Config::Pit::get('asianlunch_bot') or croak "please '\$ ./config.pl'";
croak "missing config. please '\$ ./config.pl'" if
    notall {defined $_}
    @$config{qw/
                   twitter_username
                   twitter_password
                   gmail_username
                   gmail_password
               /};


##################################################
## login

my $socket = IO::Socket::SSL->new(
    PeerAddr => 'imap.gmail.com',
    PeerPort => 993,
) or croak "counld not make ssl socket";

my $imap = Mail::IMAPClient->new(
    Socket   => $socket,
    User     => $config->{gmail_username},
    Password => $config->{gmail_password},
    #Debug => 1,
) or croak "could not connect imap server";

$imap->IsAuthenticated or croak "no authenticated";
$imap->select("INBOX");

##################################################
## search from asian lunch mail

my ($year, $month, $day) = Date::Calc::Today;
my $senton = "$day-". $month_of{$month} ."-$year";
#$senton = "24-Jan-2010";

my $search_query = q{FROM "asianlunch@yahoo.co.jp" UNSEEN SENTON }.$senton;
#my $search_query = q{FROM "asianlunch@yahoo.co.jp" SENTON 12-Feb-2010};
#carp $search_query;
my $msgid = ($imap->search($search_query))[0] or croak 'search result is 0';

##################################################
## parse menu string

my $subject = q{};
$subject = Encode::decode('MIME-Header', $imap->subject($msgid));
#carp $subject;
my $message = Encode::decode('iso-2022-jp', $imap->body_string($msgid));
#carp $message;

my @menus = map {Encode::encode('utf8', $_)} AsianLunch->parse($message);
#carp Dumper @menus;

croak "no menu found..." unless scalar @menus;

##################################################
## post twitter

my $nt = Net::Twitter::Lite->new(
    username => $config->{twitter_username},
    password => $config->{twitter_password},
) or croak "could not make tn instance";

eval {
    $nt->update($subject);
    foreach my $menu (@menus) {
        $nt->update($menu);
    }
    $nt->update("$subject おわり");
};
if($@) {
    croak "error in update twitter $@";
}

##################################################
## finally

$imap->see($msgid);
$imap->close();

exit;

__DATA__

