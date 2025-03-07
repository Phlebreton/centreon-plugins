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

package storage::hp::storeonce::3::restapi::mode::nasusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_nas_status_output {
    my ($self, %options) = @_;
    
    return sprintf(
        'status: %s [replication health: %s]', 
        $self->{result_values}->{health},
        $self->{result_values}->{replication_health}
    );
}

sub custom_share_status_output {
    my ($self, %options) = @_;
    
    return sprintf('status: %s', $self->{result_values}->{health});
}

sub prefix_nas_output {
    my ($self, %options) = @_;
    
    return "NAS '" . $options{instance_value}->{display} . "' ";
}

sub prefix_share_output {
    my ($self, %options) = @_;
    
    return "Share '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'nas', type => 1, cb_prefix_output => 'prefix_nas_output', message_multiple => 'All nas are ok' },
        { name => 'share', type => 1, cb_prefix_output => 'prefix_share_output', message_multiple => 'All shares are ok' }
    ];
    
    $self->{maps_counters}->{nas} = [
        {
            label => 'nas-status',
            type => 2,
            warning_default => '%{health} =~ /warning/i',
            critical_default => '%{health} =~ /critical/i',
            set => {
                key_values => [ { name => 'replication_health' }, { name => 'health' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_nas_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{share} = [
        {
            label => 'share-status', 
            type => 2,
            type => 2,
            warning_default => '%{health} =~ /warning/i',
            critical_default => '%{health} =~ /critical/i',
            set => {
                key_values => [ { name => 'health' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_share_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my %mapping_health_level = (
    0 => 'unknown',
    1 => 'ok',
    2 => 'information',
    3 => 'warning',
    4 => 'critical',
);

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nas} = {};
    $self->{share} = {};
    my $result = $options{custom}->get(path => '/cluster/servicesets/*all*/services/nas', ForceArray => ['service', 'item']);
    if (defined($result->{services}->{service})) {
        foreach my $entry (@{$result->{services}->{service}}) {
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $entry->{properties}->{ssid} !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $entry->{properties}->{ssid} . "': no matching filter.", debug => 1);
                next;
            }

            $self->{nas}->{$entry->{properties}->{ssid}} = { 
                display => $entry->{properties}->{ssid}, 
                health => $mapping_health_level{$entry->{properties}->{nasHealthLevel}},
                replication_health => $mapping_health_level{$entry->{properties}->{repHealthLevel}},
            };

            foreach my $item (@{$entry->{shares}->{item}}) {
                $self->{share}->{$entry->{properties}->{ssid} . '.' . $item->{id}} = {
                    display => $entry->{properties}->{ssid} . '.' . $item->{id},
                    health => $mapping_health_level{$item->{summaryHealthLevel}},
                };
            }
        }
    }

    if (scalar(keys %{$self->{nas}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No nas found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check NAS status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^nas-status$'

=item B<--filter-name>

Filter nas name (can be a regexp).

=item B<--warning-nas-status>

Define the conditions to match for the status to be WARNING (default: '%{health} =~ /warning/i').
You can use the following variables: %{health}, %{replication_health}, %{display}

=item B<--critical-nas-status>

Define the conditions to match for the status to be CRITICAL (default: '%{health} =~ /critical/i').
You can use the following variables: %{health}, %{replication_health}, %{display}

=item B<--warning-share-status>

Define the conditions to match for the status to be WARNING (default: '%{health} =~ /warning/i').
You can use the following variables: %{health}, %{replication_health}, %{display}

=item B<--critical-share-status>

Define the conditions to match for the status to be CRITICAL (default: '%{health} =~ /critical/i').
You can use the following variables: %{health}, %{replication_health}, %{display}

=back

=cut
