package ARB;

use warnings;
use strict;

my $PROJECT_REGEX = qr#^/files/git/repos/[^/]+/(.+?)/?$#;

############################################################

=head1 NAME

ARB - perl access to the Amie Review Board

=head1 SYNOPSIS

Allows access to the code review system for Amie Street

=head1 METHODS

=over 4

=cut

############################################################

=item deduce_project

Deduces the name of the project the current git repository is associated with.
Returns C<undef> if it cannot be determined (e.g. not currently in a git
repository directory, or there is no review or main remote defined)

=cut

sub deduce_project {
    foreach my $config (qw/remote.main.url remote.review.url/) {
        chomp(my $url = `git-config --get $config`);
        next if $? != 0;

        if ($url =~ $PROJECT_REGEX) {
            return $1;
        }
    }
    return undef;
}


=back

=head1 AUTHOR

Todd Lipcon E<lt>todd@amiestreet.comE<gt>
1;
