package AsianLunch;

use strict;
use warnings;

use utf8;
use Encode;

use Data::Dumper;

sub parse {
    my ($class, $body) = @_;

    my @lines = split("\r\n", $body);
    my @menus = ();
    my $menu_stack = q{};

 FIND:
    foreach my $line (@lines) {

        if ($menu_stack ne q{} and $line eq q{}) {
            push @menus, $menu_stack;
            $menu_stack = q{};
            next FIND;
        }

        if ( $line =~ m/^[１２３４５６][ 　]/) {
            $menu_stack = $line;
        } elsif ($menu_stack ne q{}) {
            $menu_stack .= ' '.$line;
        }
    }

    return @menus;
}

1;
__DATA__

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

=cut

