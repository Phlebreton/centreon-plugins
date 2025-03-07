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

package hardware::ups::riello::snmp::mode::outputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Output source status is '%s'", $self->{result_values}->{status});
}

sub prefix_oline_output {
    my ($self, %options) = @_;

    return "Output line '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'oline', type => 1, cb_prefix_output => 'prefix_oline_output', message_multiple => 'All output lines are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'source-status',
            type => 2,
            set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{oline} = [
        { label => 'load', nlabel => 'line.output.load.percentage', set => {
                key_values => [ { name => 'percent_load' } ],
                output_template => 'load: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'current', nlabel => 'line.output.current.ampere', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'current: %.2f A',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'A', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'voltage', nlabel => 'line.output.voltage.volt', set => {
                key_values => [ { name => 'voltage' } ],
                output_template => 'voltage: %.2f V',
                perfdatas => [
                    { template => '%.2f', unit => 'V', label_extra_instance => 1 }
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
        'ignore-zero-counters' => { name => 'ignore_zero_counters' }
    });

    return $self;
}

my $map_status = {
    1 => 'other', 2 => 'none',
    3 => 'normal', 4 => 'bypass', 5 => 'battery',
    6 => 'booster', 7 => 'reducer'
};

my $mapping = {
    voltage      => { oid => '.1.3.6.1.4.1.5491.10.1.4.4.1.2' }, # rupsOutputVoltage (Volt) 
    current      => { oid => '.1.3.6.1.4.1.5491.10.1.4.4.1.3' }, # rupsOutputCurrent (dA)
    percent_load => { oid => '.1.3.6.1.4.1.5491.10.1.4.4.1.5' }  # rupsOutputPercentLoad
};
my $mapping2 = {
    status => { oid => '.1.3.6.1.4.1.5491.10.1.4.1', map => $map_status } # rupsOutputSource
};
my $tables = {
    rupsOutput => '.1.3.6.1.4.1.5491.10.1.4',
    rupsOutputEntry => '.1.3.6.1.4.1.5491.10.1.4.4.1'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $tables->{rupsOutput},
        end => $mapping->{percent_load}->{oid},
        nothing_quit => 1
    );

    $self->{oline} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$tables->{rupsOutputEntry}\.\d+\.(.*)$/);
        my $instance = $1;
        next if (defined($self->{oline}->{$instance}));

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        foreach (keys %$result) {
            delete $result->{$_} if (
                (defined($self->{option_results}->{ignore_zero_counters}) && $result->{$_} == 0) ||
                ($result->{$_} == -1 || $result->{$_} == 65535)
            );
        }
        $result->{current} *= 0.1 if (defined($result->{current}));
        if (scalar(keys %$result) > 0) {
            $self->{oline}->{$instance} = { display => $instance, %$result };
        }
    }

    $self->{global} = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => 0);
}

1;

__END__

=head1 MODE

Check output lines.

=over 8

=item B<--ignore-zero-counters>

Ignore counters equals to 0.

=item B<--unknown-source-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}

=item B<--warning-source-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}

=item B<--critical-source-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'load', 'voltage', 'current'.

=back

=cut
