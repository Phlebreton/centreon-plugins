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

package apps::tomcat::web::mode::applications;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::http;

sub custom_status_output {
    my ($self, %options) = @_;

    return 'state: ' . $self->{result_values}->{state};
}

sub prefix_application_output {
    my ($self, %options) = @_;

    return "Application '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'application', type => 1, cb_prefix_output => 'prefix_application_output', message_multiple => 'All applications are ok' }
    ];

    $self->{maps_counters}->{application} = [
        { label => 'status', type => 2, unknown_default => '%{state} ne "running"', critical_default => '%{state} eq "stopped"', set => {
                key_values => [ { name => 'state' }, { name => 'contextpath' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'sessions-active', nlabel => 'application.sessions.active.count', set => {
                key_values => [ { name => 'sessions' }, { name => 'display' } ],
                output_template => 'active sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'    => { name => 'hostname' },
        'port:s'        => { name => 'port', default => '8080' },
        'proto:s'       => { name => 'proto' },
        'credentials'   => { name => 'credentials' },
        'basic'         => { name => 'basic' },
        'username:s'    => { name => 'username' },
        'password:s'    => { name => 'password' },
        'timeout:s'     => { name => 'timeout' },
        'urlpath:s'     => { name => 'url_path', default => '/manager/text/list' },
        'filter-name:s' => { name => 'filter_name' },
        'filter-path:s' => { name => 'filter_path', },
        'unknown-http-status:s'  => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
        'warning-http-status:s'  => { name => 'warning_http_status', default => '' },
        'critical-http-status:s' => { name => 'critical_http_status', default => '' }
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{http}->set_options(%{$self->{option_results}});
}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $self->{http}->request(
        unknown_status => $self->{option_results}->{unknown_http_status},
        warning_status => $self->{option_results}->{warning_http_status},
        critical_status => $self->{option_results}->{critical_http_status}
    );

    $self->{application} = {};
    while ($webcontent =~ /^(.*?)\s*:\s*(.*?)\s*:\s*(.*?)\s*:\s*(.*)/mg) {
        my ($context, $state, $sessions, $contextpath) = ($1, $2, $3, $4);

        next if (defined($self->{option_results}->{filter_path}) && $self->{option_results}->{filter_path} ne '' &&
            $contextpath !~ /$self->{option_results}->{filter_path}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $context !~ /$self->{option_results}->{filter_name}/);

        $self->{application}->{$context} = {
            display     => $context,
            state       => $state,
            sessions    => $sessions,
            contextpath => $contextpath
        };
    }

    if (scalar(keys %{$self->{application}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No application found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Tomcat Application Status by Tomcat Manager

=over 8

=item B<--hostname>

IP Address or FQDN of the Tomcat Application Server

=item B<--port>

Port used by Tomcat

=item B<--proto>

Protocol used http or https

=item B<--credentials>

Specify this option if you access server-status page with authentication

=item B<--username>

Specify the username for authentication (mandatory if --credentials is specified)

=item B<--password>

Specify the password for authentication (mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access server-status page over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your web server.

Specify this option if you access server-status page over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(use with --credentials)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--urlpath>

Path to the Tomcat Manager List (default: Tomcat 7 '/manager/text/list')
Tomcat 6: '/manager/list'
Tomcat 7: '/manager/text/list'

=item B<--filter-name>

Filter context name (regexp can be used)

=item B<--filter-path>

Filter Context Path (regexp can be used).
Can be for example: '/STORAGE/context/test1'.

=item B<--unknown-http-status>

Threshold unknown for http response code (default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning-http-status>

Warning threshold for http response code

=item B<--critical-http-status>

Critical threshold for http response code

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{state} ne "running"').
You can use the following variables: %{state}, %{display}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{state}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} eq "stopped"').
You can use the following variables: %{state}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'sessions-active'.

=back

=cut
