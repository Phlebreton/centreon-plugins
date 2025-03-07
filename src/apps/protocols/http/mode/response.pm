#
# Copyright 2023 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package apps::protocols::http::mode::response;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::plugins::http;

sub custom_status_output {
    my ($self, %options) = @_;

    return $self->{result_values}->{http_code} . ' ' . $self->{result_values}->{message};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
         {
             label => 'status', type => 2, critical_default => '%{http_code} < 200 or %{http_code} >= 300',
             display_ok => 0, set => {
                key_values => [
                    { name => 'http_code' }, { name => 'message' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'time', nlabel => 'http.response.time.seconds', set => {
                key_values => [ { name => 'time' } ],
                output_template => 'response time %.3fs',
                perfdatas => [
                    { label => 'time', template => '%.3f', min => 0, unit => 's' }
                ]
            }
        },
        { label => 'size', nlabel => 'http.response.size.count', display_ok => 0, set => {
                key_values => [ { name => 'size' } ],
                output_template => 'content size: %s',
                perfdatas => [
                    { label => 'size', template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'resolve', nlabel => 'http.response.resolve.time.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'resolve' } ],
                output_template => 'resolve: %.3f ms',
                perfdatas => [
                    { label => 'resolve', template => '%.3f', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'connect', nlabel => 'http.response.connect.time.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'resolve' } ],
                output_template => 'connect: %.3f ms',
                perfdatas => [
                    { label => 'connect', template => '%.3f', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'tls', nlabel => 'http.response.tls.time.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'tls' } ],
                output_template => 'tls: %.3f ms',
                perfdatas => [
                    { label => 'tls', template => '%.3f', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'processing', nlabel => 'http.response.processing.time.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'processing' } ],
                output_template => 'processing: %.3f ms',
                perfdatas => [
                    { label => 'processing', template => '%.3f', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'transfer', nlabel => 'http.response.transfer.time.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'resolve' } ],
                output_template => 'transfer: %.3f ms',
                perfdatas => [
                    { label => 'transfer', template => '%.3f', min => 0, unit => 'ms' }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'    => { name => 'hostname' },
        'port:s'        => { name => 'port', },
        'method:s'      => { name => 'method' },
        'proto:s'       => { name => 'proto' },
        'urlpath:s'     => { name => 'url_path' },
        'credentials'   => { name => 'credentials' },
        'basic'         => { name => 'basic' },
        'ntlmv2'        => { name => 'ntlmv2' },
        'username:s'    => { name => 'username' },
        'password:s'    => { name => 'password' },
        'timeout:s'     => { name => 'timeout' },
        'no-follow'     => { name => 'no_follow', },
        'cert-file:s'   => { name => 'cert_file' },
        'key-file:s'    => { name => 'key_file' },
        'cacert-file:s' => { name => 'cacert_file' },
        'cert-pwd:s'    => { name => 'cert_pwd' },
        'cert-pkcs12'   => { name => 'cert_pkcs12' },
        'header:s@'      => { name => 'header' },
        'get-param:s@'   => { name => 'get_param' },
        'post-param:s@'  => { name => 'post_param' },
        'cookies-file:s' => { name => 'cookies_file' },
        'warning:s'      => { name => 'warning' },
        'critical:s'     => { name => 'critical' },
        'extra-stats'    => { name => 'extra_stats' }
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    # Compat
    if (defined($options{option_results}->{warning})) {
        $options{option_results}->{'warning-time'} = $options{option_results}->{warning};
        $options{option_results}->{'warning-http-response-time-seconds'} = $options{option_results}->{warning};
    }
    if (defined($options{option_results}->{critical})) {
        $options{option_results}->{'critical-time'} = $options{option_results}->{critical};
        $options{option_results}->{'critical-http-response-time-seconds'} = $options{option_results}->{critical};
    }    
    $self->SUPER::check_options(%options);
    $self->{http}->set_options(%{$self->{option_results}});
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    my $timing0 = [gettimeofday];
    my $webcontent = $self->{http}->request(
        unknown_status => '', warning_status => '', critical_status => ''
    );
    $self->{global}->{time} = tv_interval($timing0, [gettimeofday]);
    $self->{global}->{http_code} = $self->{http}->get_code();
    $self->{global}->{message} = $self->{http}->get_message();

    {
        require bytes;
        
        $self->{global}->{size} = bytes::length($webcontent);
    }

    if (defined($self->{option_results}->{extra_stats})) {
        my $times = $self->{http}->get_times();
        if (!defined($times)) {
            $self->{output}->add_option_msg(short_msg => 'Unsupported --extra-stats option for current http backend. Please try with curl backend.');
            $self->{output}->option_exit();
        }
        $self->{global} = { %$times, %{$self->{global}} };
    }
}

1;

__END__

=head1 MODE

Check Webpage response and size.

=over 8

=item B<--hostname>

IP Addr/FQDN of the web server host.

=item B<--port>

Port used by web server.

=item B<--method>

Specify http method used (default: 'GET').

=item B<--proto>

Specify https if needed (default: 'http').

=item B<--urlpath>

Define the path of the web page to get (default: '/').

=item B<--credentials>

Specify this option if you are accessing a web page using authentication.

=item B<--username>

Specify the username for authentication (mandatory if --credentials is specified).

=item B<--password>

Specify the password for authentication (mandatory if --credentials is specified).

=item B<--basic>

Specify this option if you are accessing a web page using basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your web server.

Specify this option if you are accessing a web page using hidden basic authentication or you'll get a '404 NOT FOUND' error.

(use with --credentials)

=item B<--ntlmv2>

Specify this option if you are accessing a web page using ntlmv2 authentication (use with --credentials and --port options).

=item B<--timeout>

Define the timeout in seconds (default: 5).

=item B<--no-follow>

Do not follow http redirections.

=item B<--cert-file>

Specify the certificate to send to the web server.

=item B<--key-file>

Specify the key to send to the web server.

=item B<--cacert-file>

Specify the root certificate to send to the web server.

=item B<--cert-pwd>

Specify the certificate's password.

=item B<--cert-pkcs12>

Specify that the type of certificate is PKCS1.

=item B<--get-param>

Set GET params (multiple option. Example: --get-param='key=value').

=item B<--header>

Set HTTP headers(multiple option). Example: --header='Content-Type: xxxxx'.

=item B<--post-param>

Set POST params (multiple option. Example: --post-param='key=value').

=item B<--cookies-file>

Save cookies in a file (example: '/tmp/lwp_cookies.dat').

=item B<--unknown-status>

Unknown conditions for http response code (default: '%{http_code} < 200 or %{http_code} >= 300').

=item B<--warning-status>

Warning conditions for http response code.

=item B<--critical-status>

Critical conditions for http response code.

=item B<--extra-stats>

Add detailed time statistics (only with curl backend).

=item B<--warning-*> B<--critical-*>

Thresholds. Can be:
'time', 'size',
'resolve', 'connect', 'tls', 'processing', 'transfer'. 

=back

=cut
