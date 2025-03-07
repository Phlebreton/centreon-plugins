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

package centreon::common::adic::tape::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|fan)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['good', 'OK'],
            ['failed', 'CRITICAL'],
            ['degraded', 'WARNING'],
            ['warning', 'WARNING'],
            ['informational', 'OK'],
            ['unknown', 'UNKNOWN'],
            ['invalid', 'CRITICAL'],
            
            ['other', 'OK'],
            ['ok', 'OK'],
            ['non-critical', 'WARNING'],
            ['critical', 'CRITICAL'],
            ['non-recoverable', 'CRITICAL'],
        ],
        component => [
            ['unknown', 'UNKNOWN'],
            ['unused', 'OK'],
            ['ok', 'OK'],
            ['warning', 'WARNING'],
            ['failed', 'CRITICAL'],
        ],
        sensor => [
            ['nominal', 'OK'],
            ['warningLow', 'WARNING'],
            ['warningHigh', 'CRITICAL'],
            ['alarmLow', 'CRITICAL'],
            ['alarmHigh', 'CRITICAL'],
            ['notInstalled', 'OK'],
            ['noData', 'OK'],
        ],
    };
    
    $self->{components_path} = 'centreon::common::adic::tape::snmp::mode::components';
    $self->{components_module} = ['global', 'physicaldrive', 'subsystem', 'component', 'temperature', 'fan'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
    
    return $self;
}

1;

__END__

=head1 MODE

Check Hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'global', 'physicaldrive', 'subsystem', 'component', 'temperature', 'fan'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=subsystem).
You can also exclude items from specific instances: --filter=physicaldrive,1

=item B<--no-component>

Define the expected status if no components are found (default: critical).


=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='physicaldrive,OK,invalid'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut
