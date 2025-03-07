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

package apps::vmware::connector::mode::servicehost;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status ' . $self->{result_values}->{status} . ', maintenance mode is ' . $self->{result_values}->{maintenance};
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{maintenance} = $options{new_datas}->{$self->{instance} . '_maintenance'};
    return 0;
}

sub custom_service_output {
    my ($self, %options) = @_;

    return '[policy ' . $self->{result_values}->{policy} . '][running ' . $self->{result_values}->{running} . ']';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'host', type => 3, cb_prefix_output => 'prefix_host_output', cb_long_output => 'host_long_output', indent_long_output => '    ', message_multiple => 'All ESX hosts are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'service', cb_prefix_output => 'prefix_service_output',  message_multiple => 'All services are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        {
            label => 'status', type => 2, unknown_default => '%{status} !~ /^connected$/i && %{maintenance} =~ /false/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'maintenance' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    
    $self->{maps_counters}->{service} = [
        {
            label => 'service-status', type => 2, critical_default => '%{policy} =~ /^on|automatic/i && !%{running}',
            set => {
                key_values => [ { name => 'display' }, { name => 'policy' }, { name => 'running' }, { name => 'key' } ],
                closure_custom_output => $self->can('custom_service_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{display} . "' : ";
}

sub host_long_output {
    my ($self, %options) = @_;

    return "checking host '" . $options{instance_value}->{display} . "'";
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "service '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'esx-hostname:s'     => { name => 'esx_hostname' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' },
        'scope-cluster:s'    => { name => 'scope_cluster' },
        'filter-services:s'  => { name => 'filter_services' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{host} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'servicehost'
    );

    foreach my $host_id (keys %{$response->{data}}) {
        my $host_name = $response->{data}->{$host_id}->{name};
        $self->{host}->{$host_name} = { display => $host_name, 
            global => {
                state => $response->{data}->{$host_id}->{state},
                maintenance => $response->{data}->{$host_id}->{inMaintenanceMode}
            }
        };

        foreach (@{$response->{data}->{$host_id}->{services}}) {
            next if (defined($self->{option_results}->{filter_services}) && $self->{option_results}->{filter_services} ne '' &&
                     $_->{key} !~ /$self->{option_results}->{filter_services}/);

            $self->{host}->{$host_name}->{service} = {} if (!defined($self->{host}->{$host_name}->{service}));
            $self->{host}->{$host_name}->{service}->{$_->{label}} = { display => $_->{label}, policy => $_->{policy}, running => $_->{running}, key => $_->{key} };
        }
    }
}

1;

__END__

=head1 MODE

Check ESX services.

=over 8

=item B<--esx-hostname>

ESX hostname to check.
If not set, we check all ESX.

=item B<--filter>

ESX hostname is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--filter-services>

Filter services you want to check (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{status} !~ /^connected$/i && %{maintenance} =~ /false/i').
You can use the following variables: %{status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '').
You can use the following variables: %{status}

=item B<--warning-service-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{running}, %{label}, %{policy}

=item B<--critical-service-status>

Define the conditions to match for the status to be CRITICAL (default: '%{policy} =~ /^on|automatic/i && !%{running}').
You can use the following variables: %{running}, %{label}, %{policy}

=back

=cut
