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

package storage::hp::3par::ssh::custom::custom;

use strict;
use warnings;
use centreon::plugins::ssh;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {                      
            'hostname:s'        => { name => 'hostname' },
            'timeout:s'         => { name => 'timeout', default => 45 },
            'command:s'         => { name => 'command' },
            'command-path:s'    => { name => 'command_path' },
            'command-options:s' => { name => 'command_options' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'SSH OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{ssh} = centreon::plugins::ssh->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{ssh}->check_options(option_results => $self->{option_results});
    }

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );

    return 0;
}

##############
# Specific methods
##############
sub execute_command {
    my ($self, %options) = @_;

    $self->{ssh_commands} = '';
    my $append = '';
    foreach (@{$options{commands}}) {
       $self->{ssh_commands} .= $append . " $_"; 
       $append = ';';
    }

    my $content;
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        ($content) = $self->{ssh}->execute(
            ssh_pipe => 1,
            hostname => $self->{option_results}->{hostname},
            command => defined($self->{option_results}->{command}) && $self->{option_results}->{command} ne '' ? $self->{option_results}->{command} : $self->{ssh_commands},
            command_path => $self->{option_results}->{command_path},
            command_options => defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : undef,
            timeout => $self->{option_results}->{timeout}
        );
    } else {
        if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '') {
            $self->{output}->add_option_msg(short_msg => 'please set --hostname option for ssh connection (or --command for local)');
            $self->{output}->option_exit();
        }
        ($content) = centreon::plugins::misc::execute(
            ssh_pipe => 1,
            output => $self->{output},
            options => { timeout => $self->{option_results}->{timeout} },
            command => $self->{option_results}->{command},
            command_path => $self->{option_results}->{command_path},
            command_options => defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : undef
        );
    }

    return $content;
}

1;

__END__

=head1 NAME

ssh

=head1 SYNOPSIS

my ssh

=head1 SSH OPTIONS

=over 8

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the command (default: 45).

=item B<--command>

Command to get information. Used it you have output in a file.

=item B<--command-path>

Command path.

=item B<--command-options>

Command options.

=back

=head1 DESCRIPTION

B<custom>.

=cut
