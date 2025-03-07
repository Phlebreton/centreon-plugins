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

package os::windows::wsman::mode::pendingreboot;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::windows::pendingreboot;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "'%s': reboot pending is %s [Windows Update: %s][Component Based Servicing: %s][SCCM Client: %s][File Rename Operations: %s][Computer Name Change: %s]",
        $self->{result_values}->{WindowsVersion},
        $self->{result_values}->{RebootPending},
        $self->{result_values}->{WindowsUpdate},
        $self->{result_values}->{CBServicing},
        $self->{result_values}->{CCMClientSDK},
        $self->{result_values}->{PendFileRename},
        $self->{result_values}->{PendComputerRename}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'pendingreboot', type => 0  },
    ];

    $self->{maps_counters}->{pendingreboot} = [
        { label => 'status', type => 2, warning_status => '%{RebootPending} =~ /true/i', set => {
                key_values => [
                    { name => 'WindowsVersion' }, { name => 'CBServicing' }, { name => 'RebootPending' }, { name => 'WindowsUpdate' },
                    { name => 'CCMClientSDK' }, { name => 'PendComputerRename' }, { name => 'PendFileRename' }
                ],
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

    $options{options}->add_options(arguments => {
        'ps-exec-only'        => { name => 'ps_exec_only' },
        'ps-display'          => { name => 'ps_display' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $ps = centreon::common::powershell::windows::pendingreboot::get_powershell();
    if (defined($self->{option_results}->{ps_display})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $ps
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $result = $options{wsman}->execute_powershell(
        label => 'pendingreboot',
        content => centreon::plugins::misc::powershell_encoded($ps)
    );

    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $result->{pendingreboot}->{stdout}
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($self->{output}->decode($result->{pendingreboot}->{stdout}));
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    #{ WindowsVersion: "Microsoft Windows 2003 Server", CBServicing: false, WindowsUpdate: false, CCMClientSDK: null, PendComputerRename: false, PendFileRename: false, PendFileRenVal: null, RebootPending: false }
    foreach (keys %$decoded) {
        $decoded->{$_} = '-' if (!defined($decoded->{$_}));
        $decoded->{$_} = 'true' if ($decoded->{$_} =~ /^(?:true|1)$/i);
        $decoded->{$_} = 'false' if ($decoded->{$_} =~ /^(?:false|0)$/i);
    }

    $self->{pendingreboot} = $decoded;
}

1;

__END__

=head1 MODE

Check pending Windows reboot.

=over 8

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{RebootPending} =~ /true/i').
You can use the following variables: %{RebootPending}, %{WindowsUpdate}, %{CBServicing}, %{CCMClientSDK},
%{PendFileRename}, %{PendComputerRename}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '').
You can use the following variables: %{RebootPending}, %{WindowsUpdate}, %{CBServicing}, %{CCMClientSDK},
%{PendFileRename}, %{PendComputerRename}.

=back

=cut
