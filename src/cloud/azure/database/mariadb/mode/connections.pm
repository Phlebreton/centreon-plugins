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

package cloud::azure::database::mariadb::mode::connections;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'active_connections' => {
            'output' => 'Active Connections',
            'label'  => 'connections-active',
            'nlabel' => 'azmariadb.connections.active.count',
            'unit'   => '',
            'min'    => '0'
        },
        'connections_failed' => {
            'output' => 'Failed Connections',
            'label'  => 'connections-failed',
            'nlabel' => 'azmariadb.connections.failed.count',
            'unit'   => '',
            'min'    => '0'
        }
    };

    return $metrics_mapping;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-metric:s'  => { name => 'filter_metric' },
        'resource:s'       => { name => 'resource' },
        'resource-group:s' => { name => 'resource_group' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify either --resource <name> with --resource-group option or --resource <id>.');
        $self->{output}->option_exit();
    }

    my $resource = $self->{option_results}->{resource};
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';
    my $resource_type = 'servers';
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.DBforMariaDB\/servers\/(.*)$/) {
        $resource_group = $1;
        $resource = $2;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = 'servers';
    $self->{az_resource_namespace} = 'Microsoft.DBforMariaDB';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : 'PT5M';
    $self->{az_aggregations} = ['Total'];
    if (defined($self->{option_results}->{aggregation})) {
        $self->{az_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            if ($stat ne '') {
                push @{$self->{az_aggregations}}, ucfirst(lc($stat));
            }
        }
    }

    my $resource_mapping = {
        'servers' => [ 'active_connections', 'connections_failed' ]
    };

    my $metrics_mapping_transformed;
    foreach my $metric_type (@{$resource_mapping->{$resource_type}}) {
        $metrics_mapping_transformed->{$metric_type} = $self->{metrics_mapping}->{$metric_type};
    }

    foreach my $metric (keys %{$metrics_mapping_transformed}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{az_metrics}}, $metric;
    }
}

1;

__END__

=head1 MODE

Check Azure Database for MariaDB connections status.

Example:

Using resource name:

perl centreon_plugins.pl --plugin=cloud::azure::database::mariadb::plugin --mode=connections --custommode=api
--resource=<db_id> --resource-group=<resourcegroup_id> --aggregation='total'
--warning-connections-active='1000' --critical-connections-active='2000'

Using resource ID:

perl centreon_plugins.pl --plugin=cloud::azure::database::mariadb::plugin --mode=connections --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.DBforMariaDB/servers/<db_id>'
--aggregation='total' --warning-connections-active='1000' --critical-connections-active='2000'

Default aggregation: 'total' / 'average', 'minimum' and 'maximum' are valid.

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--warning-*>

Warning threshold where '*' can be:
'connections-active', 'connections-failed'.

=item B<--critical-*>

Critical threshold where '*' can be:
'connections-active', 'connections-failed'.

=back

=cut
