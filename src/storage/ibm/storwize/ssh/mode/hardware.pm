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

package storage::ibm::storwize::ssh::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(systemstats)$';
    
    $self->{cb_hook2} = 'ssh_execute';
    
    $self->{thresholds} = {
        default => [
            ['online', 'OK'],
            ['offline', 'CRITICAL'],
            ['degraded', 'WARNING'],
            ['excluded', 'OK'], # lsarray
            ['mask', 'OK'] # lshost
        ],
        portfc => [
            ['active', 'OK'],
            ['inactive_unconfigured', 'OK'],
            ['.*', 'CRITICAL']
        ],
        portsas => [
            ['online', 'OK'],
            ['offline_unconfigured', 'OK'],
            ['excluded', 'OK'],
            ['offline', 'CRITICAL'],
            ['degraded', 'WARNING']
        ],
        mdisk => [
            ['online', 'OK'],
            ['excluded', 'OK'],
            ['offline', 'CRITICAL'],
            ['degraded_paths', 'WARNING'],
            ['degraded_ports', 'WARNING'],
            ['degraded', 'WARNING']
        ]
    };
    
    $self->{components_path} = 'storage::ibm::storwize::ssh::mode::components';
    $self->{components_module} = [
        'array', 'drive', 'enclosure', 'enclosurebattery', 'enclosurecanister',
        'enclosurepsu', 'host', 'portfc', 'portsas', 'vdisk', 'node', 'quorum', 'mdisk', 'systemstats'
    ];
}

sub ssh_execute {
    my ($self, %options) = @_;

    ($self->{results}) = $options{custom}->execute_command(command => $self->{ssh_commands});
    $self->{custom} = $options{custom};
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    $self->{ssh_commands} = '';
    return $self;
}

1;

__END__

=head1 MODE

Check components.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'array', 'drive', 'enclosure', 'enclosurebattery', 'enclosurecanister',
'enclosurepsu', 'host', 'portfc', 'portsas', 'vdisk', 'node', 'quorum', 'mdisk', 'systemstats'.

=item B<--add-name-instance>

Add literal description for instance value (used in filter, absent-problem and threshold options).

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=host --filter=enclosurecanister).
You can also exclude items from specific instances: --filter=host,10

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: ---threshold-overload='host,.*,OK,degraded'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,regexp,threshold)
Example: --warning='systemstats,cpu_pc,30'

=item B<--critical>

Set critical threshold for temperatures (syntax: type,regexp,threshold)
Example: --critical='systemstats,cpu_pc,40'

=back

=cut
