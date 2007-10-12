package ARB;

use warnings;
use strict;

use JSON;
use LWP::UserAgent;

my $PROJECT_REGEX = qr#^/files/git/repos/[^/]+/(.+?)/?$#;

my $WEBAPP_BASEURL = 'http://janus:3000/';

my $USER_AGENT_TIMEOUT = 5;

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


=item get_current_developer

Returns the username of the current developer

=cut

sub get_current_developer {
    chomp(my $me = `whoami`);
    return $me;
}


=item create_review

Returns the unique id for a new review in the database

=cut

sub create_review {
    my $response = post_json_request('/review/new/json',
                                     {
                                         repository => get_current_repository(),
                                         developer => get_current_developer()
                                        });
    die "nyi";
}

=item get_review($id)

Returns an ARB::Review instance for the given review id, or C<undef> if it
is not found.

=cut

sub get_review {
    my $id = (@_);

    return get_json_request('/review/' . $id . '/json');
#TODO(nyi) ARB::Review object
}

=item get_json_request($path, \%params)

=item post_json_request($path, \%params)

Does an HTTP POST to the review server with the given path and parameters.
Expects that the response is JSON encoded and decodes it to a perl hashref.

=cut

sub post_json_request {
    return json_request('post', @_);
}

sub get_json_request {
    return json_request('get', @_);
}

sub json_request {
    my ($method, $path, $params) = @_;

    die "bad method" unless $method =~ /^get|post$/i;

    my $url = $WEBAPP_BASEURL . $path;

    my $response = _create_useragent()->$method($url, $params);
    return _decode_response($url, uc $method, $response);
}

sub _create_useragent {
    my $ua = LWP::UserAgent->new;
    $ua->timeout($USER_AGENT_TIMEOUT);

    return $ua;
}

sub _decode_response {
    my ($url, $method, $response) = @_;
    die "unsuccessful $method to $url: " . $response->status_line
        unless $response->is_success;

    my $json = new JSON(unmapping => 1);
    return $json->jsonToObj($response->content);
}

=back

=head1 AUTHOR

Todd Lipcon E<lt>todd@amiestreet.comE<gt>
1;
