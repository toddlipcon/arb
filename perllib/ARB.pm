package ARB;

use warnings;
use strict;

use JSON;
use LWP::UserAgent;
use Term::ReadKey;
use Cwd;

my $PROJECT_REGEX = qr#^/files/git/repos/[^/]+/(.+?)/?(?:\.git)?$#;

my $WEBAPP_BASEURL = 'http://janus.corp.amiestreet.com:3000/';

my $REVIEW_BASE = '/files/git/repos/review';
my $MAIN_BASE   = '/files/git/repos/main';

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
    foreach my $config (qw/remote.main.url remote.review.url remote.origin.url/) {
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
    return $ENV{'ARB_USER'} if (exists $ENV{'ARB_USER'});

    chomp(my $me = `whoami`);

    if ($me eq 'amiest') {
        die "Logged in as 'amiest' and ARB_USER env variable not set.";
    }

    return $me;
}


=item prompt_password

Prompts the user for their LDAP password to authenticate to the review system

=cut

sub prompt_password {
    my $password;
    {
        local $| = 1;
        print "Password for user '" . &get_current_developer() . "':";
        ReadMode('noecho');
        chomp($password = ReadLine(0));
        ReadMode('restore');
        print "\n";
    }

    return $password;
}
=item get_current_repository

Returns the repository the user is working in

=cut

sub get_current_repository {
    chomp(my $cdup = `git-rev-parse --show-cdup`);
    die "couldn't git-rev-parse cdup" unless $? == 0;

    return Cwd::realpath($cdup);
}


=item get_review_repository

Returns the repository to push reviews to

=cut

sub get_review_repository {
    return $REVIEW_BASE . '/' . deduce_project();
}


=item get_main_repository

Returns the repository to eventually push commits to

=cut

sub get_main_repository {
    return $MAIN_BASE . '/' . deduce_project();
}




=item create_review($against_sha1)

Returns the unique id for a new review in the database

=cut

sub create_review {
    my $against_sha1 = shift @_;

    die "Bad sha1" if (not defined $against_sha1) || ($against_sha1 !~ /^[\da-f]{40}$/);

    my $response = post_json_request('/review/new/json',
                                     {
                                         repository => get_current_repository(),
                                         developer => get_current_developer(),
                                         project => deduce_project(),
                                         against_sha1 => $against_sha1
                                        });
    return $response;
}

=item get_review($id)

Returns an ARB::Review instance for the given review id, or C<undef> if it
is not found.

=cut

sub get_review {
    my ($id) = @_;

    return get_json_request('/review/' . $id . '/json');
#TODO(nyi) ARB::Review object
}


=item approve_commit($sha1)

Approves the commit named by the given (abbreviated) sha1

=cut

sub approve_commit {
    my ($sha1) = @_;

    my $project = deduce_project();
    my $developer = get_current_developer();
    my $password = prompt_password();

    return get_json_request("/project/$project/commit/sha1/$sha1/approve/json",
                            {},
                            [$developer, $password]);
}


=item get_review_url($review_id)

Gets the URL for the human-readable review

=cut

sub get_review_url {
    my ($review_id) = @_;

    return $WEBAPP_BASEURL . 'review/' . $review_id . '/show';
}

=item get_json_request($path, \%params, \@credentials)

=item post_json_request($path, \%params. \@credentials)

Does an HTTP POST to the review server with the given path and parameters.
Expects that the response is JSON encoded and decodes it to a perl hashref.

If C<\@credentials> is passed, it should be a [$user, $password] pair.

=cut

sub post_json_request {
    return json_request('post', @_);
}

sub get_json_request {
    return json_request('get', @_);
}

sub json_request {
    my ($method, $path, $params, $credentials) = @_;

    die "bad method" unless $method =~ /^get|post$/i;

    $path =~ s#^/##;

    my $url = $WEBAPP_BASEURL . $path;

    my $ua = _create_useragent($credentials);

    my $response = $ua->$method($url, $params);
    return _decode_response($url, uc $method, $response);
}

sub _create_useragent {
    my $credentials = shift @_;

    my $ua = LWP::UserAgent->new;
    $ua->timeout($USER_AGENT_TIMEOUT);

    if (defined $credentials) {
        die 'bad credentials. Expected [$user, $password]'
            unless scalar @{$credentials} == 2;

        my $h = HTTP::Headers->new;
        $h->authorization_basic(@$credentials);
        $ua->default_headers($h);
    }

    return $ua;
}

sub _decode_response {
    my ($url, $method, $response) = @_;

    if ($response->code == 401) { # 401 Unauthorized
        print STDERR "401 Unauthorized -- bad username or password\n";
        exit 1;
    }

    die "unsuccessful $method to $url: " . $response->status_line .
        "\n\nResponse\n\n" . $response->content
        unless $response->is_success;

    my $json = new JSON(unmapping => 1);
    return $json->jsonToObj($response->content);
}

=back

=head1 AUTHOR

Todd Lipcon E<lt>todd@amiestreet.comE<gt>
1;
