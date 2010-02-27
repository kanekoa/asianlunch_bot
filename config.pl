#!/opt/local/bin/perl

use strict;
use warnings;

use Config::Pit;

my $config = Config::Pit::set("asianlunch_bot", config => {
    twitter_username => "username on twitter",
    twitter_password => "password on twitter",
    gmail_username   => "username on gmail",
    gmail_password   => "password on gmail"
});

print "please set \$EDITOR\n" unless scalar keys %$config;

exit;
