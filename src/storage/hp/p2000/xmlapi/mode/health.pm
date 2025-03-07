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

package storage::hp::p2000::xmlapi::mode::health;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = 
        '^(?:sensor|fan\.speed)$';
    
    $self->{cb_hook1} = 'init_health';
    
    $self->{thresholds} = {
        # disk, enclosure, vdisk, saslink, fan
        default => [
            ['ok', 'OK'],
            ['degraded', 'WARNING'],
            ['failed|fault', 'CRITICAL'],
            ['unknown', 'UNKNOWN'],
            ['not available', 'OK']
        ],
        fru => [
            ['ok', 'OK'],
            ['absent', 'WARNING'],
            ['fault', 'CRITICAL'],
            ['not available', 'UNKNOWN']
        ],
        sensor => [
            ['ok', 'OK'],
            ['warning|not installed|unavailable', 'WARNING'],
            ['error|unrecoverable', 'CRITICAL'],
            ['unknown|unsupported', 'UNKNOWN']
        ]
    };

    $self->{components_exec_load} = 0;
    $self->{components_path} = 'storage::hp::p2000::xmlapi::mode::components';
    $self->{components_module} = ['disk', 'enclosure', 'fan', 'fru', 'psu', 'saslink', 'sensor', 'vdisk'];
}

sub init_health {
    my ($self, %options) = @_;

    $self->{custom} = $options{custom};
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check health status of storage.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'disk', 'enclosure', 'fan', 'fru', 'psu', 'saslink', 'sensor', 'vdisk'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=fru --filter=enclosure).
You can also exclude items from specific instances: --filter=disk,1

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='disk,OK,unknown'

=item B<--warning>

Set warning threshold for 'sensor', 'fan.speed' (syntax: type,instance,threshold)
Example: --warning='sensor,temperature.*,30'

=item B<--critical>

Set warning threshold for 'sensor', 'fan.speed' (syntax: type,instance,threshold)
Example: --warning='sensor,temperature.*,30'

=back

=cut
