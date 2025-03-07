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

package centreon::common::cisco::standard::snmp::mode::stack;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_stack_status_output {
    my ($self, %options) = @_;

    return sprintf("Stack status is '%s'", $self->{result_values}->{stack_status});
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("state is '%s', role is '%s'", $self->{result_values}->{state}, $self->{result_values}->{role});
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Number of members ";
}

sub prefix_status_output {
    my ($self, %options) = @_;
    
    return "Member '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'stack', type => 0 },
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'members', type => 1, cb_prefix_output => 'prefix_status_output', message_multiple => 'All stack members status are ok' }
    ];

    $self->{maps_counters}->{stack} = [
        { label => 'stack-status', type => 2, critical_default => '%{stack_status} =~ /notredundant/', set => {
                key_values => [ { name => 'stack_status' } ],
                closure_custom_output => $self->can('custom_stack_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'waiting', set => {
                key_values => [ { name => 'waiting' } ],
                output_template => 'waiting: %d',
                perfdatas => [
                    { label => 'waiting', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'progressing', set => {
                key_values => [ { name => 'progressing' } ],
                output_template => 'progressing: %d',
                perfdatas => [
                    { label => 'progressing', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'added', set => {
                key_values => [ { name => 'added' } ],
                output_template => 'added: %d',
                perfdatas => [
                    { label => 'added', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'ready', set => {
                key_values => [ { name => 'ready' } ],
                output_template => 'ready: %d',
                perfdatas => [
                    { label => 'ready', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'sdm-mismatch', set => {
                key_values => [ { name => 'sdmMismatch' } ],
                output_template => 'SDM mismatch: %d',
                perfdatas => [
                    { label => 'sdm_mismatch', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'version-mismatch', set => {
                key_values => [ { name => 'verMismatch' } ],
                output_template => 'version mismatch: %d',
                perfdatas => [
                    { label => 'version_mismatch', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'feature-mismatch', set => {
                key_values => [ { name => 'featureMismatch' } ],
                output_template => 'feature mismatch: %d',
                perfdatas => [
                    { label => 'feature_mismatch', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'new-master-init', set => {
                key_values => [ { name => 'newMasterInit' } ],
                output_template => 'new master init: %d',
                perfdatas => [
                    { label => 'new_master_init', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'provisioned', set => {
                key_values => [ { name => 'provisioned' } ],
                output_template => 'provisioned: %d',
                perfdatas => [
                    { label => 'provisioned', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'invalid', set => {
                key_values => [ { name => 'invalid' } ],
                output_template => 'invalid: %d',
                perfdatas => [
                    { label => 'invalid', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'removed', set => {
                key_values => [ { name => 'removed' } ],
                output_template => 'removed: %d',
                perfdatas => [
                    { label => 'removed', template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{members} = [
        { label => 'status', type => 2, critical_default => '%{state} !~ /ready/ && %{state} !~ /provisioned/', set => {
                key_values => [ { name => 'name' }, { name => 'role' }, { name => 'state' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

my %map_role = (
    1 => 'master',
    2 => 'member',
    3 => 'notMember',
    4 => 'standby'
);
my %map_state = (
    1 => 'waiting',
    2 => 'progressing',
    3 => 'added',
    4 => 'ready',
    5 => 'sdmMismatch',
    6 => 'verMismatch',
    7 => 'featureMismatch',
    8 => 'newMasterInit',
    9 => 'provisioned',
    10 => 'invalid',
    11 => 'removed',
);

my $mapping = {
    cswSwitchRole => { oid => '.1.3.6.1.4.1.9.9.500.1.2.1.1.3', map => \%map_role },
    cswSwitchState => { oid => '.1.3.6.1.4.1.9.9.500.1.2.1.1.6', map => \%map_state },
};
my $oid_cswSwitchInfoEntry = '.1.3.6.1.4.1.9.9.500.1.2.1.1';

my $oid_cswRingRedundant = '.1.3.6.1.4.1.9.9.500.1.1.3.0';
my $oid_entPhysicalName = '.1.3.6.1.2.1.47.1.1.1.1.7';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        waiting => 0, progressing => 0, added => 0, ready => 0, sdmMismatch => 0, 
        verMismatch => 0, featureMismatch => 0, newMasterInit => 0, provisioned => 0, 
        invalid => 0, removed => 0
    };
    $self->{members} = {};

    my $snmp_result = $options{snmp}->get_leef(oids => [ $oid_cswRingRedundant ], nothing_quit => 1);
    $self->{stack} = {
        stack_status => ($snmp_result->{$oid_cswRingRedundant} != 1) ? 'notredundant' : 'redundant',
    };

    $snmp_result = $options{snmp}->get_table(
        oid => $oid_cswSwitchInfoEntry,
        start => $mapping->{cswSwitchRole}->{oid},
        end => $mapping->{cswSwitchState}->{oid},
        nothing_quit => 1
    );

    foreach my $oid (keys %$snmp_result) {
        next if($oid !~ /^$mapping->{cswSwitchRole}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{members}->{$instance} = {
            name => $instance,
            role => $result->{cswSwitchRole},
            state => $result->{cswSwitchState},
        };
        $self->{global}->{ $result->{cswSwitchState} }++;
    }

    return if (scalar(keys %{$self->{members}}) <= 0);

    $options{snmp}->load(
        oids => [ $oid_entPhysicalName ],
        instances => [ keys %{$self->{members}} ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{members}}) {
        if (defined($snmp_result->{ $oid_entPhysicalName . '.' . $_ }) && $snmp_result->{ $oid_entPhysicalName . '.' . $_ } ne '') {
            $self->{members}->{$_}->{name} = $snmp_result->{ $oid_entPhysicalName . '.' . $_ };
        }
    }
}

1;

__END__

=head1 MODE

Check Cisco Stack (CISCO-STACKWISE-MIB).

=over 8

=item B<--warning-*> B<--critical-*>

Set thresholds for members count for each states.
(can be: 'waiting', 'progressing', 'added', 'ready', 'sdm-mismatch', 'version-mismatch',
'feature-mismatch', 'new-master-init', 'provisioned', 'invalid', 'removed')

=item B<--warning-stack-status>

Set warning threshold for stack status (default: '').
You can use the following variables: %{stack_status}

=item B<--critical-stack-status>

Set critical threshold for stack status (default: '%{stack_status} =~ /notredundant/').
You can use the following variables: %{stack_status}

=item B<--warning-status>

Set warning threshold for members status (default: '').
You can use the following variables: %{name}, %{role}, %{state}

=item B<--critical-status>

Set critical threshold for member status (default: '%{state} !~ /ready/ && %{state} !~ /provisioned/').
You can use the following variables: %{name}, %{role}, %{state}

Role can be: 'master', 'member', 'notMember', 'standby'.

State can be: 'waiting', 'progressing', 'added',
'ready', 'sdmMismatch', 'verMismatch', 'featureMismatch',
'newMasterInit', 'provisioned', 'invalid', 'removed'.

=back

=cut
