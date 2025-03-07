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

package cloud::azure::compute::aks::mode::traffic;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'node_network_out_bytes' => {
            'output' => 'Network Out',
            'label'  => 'traffic-out',
            'nlabel' => 'aks.node.traffic.out.bytes',
            'unit'   => 'B',
            'min'    => '0',
        },
        'node_network_in_bytes' => {
            'output' => 'Network In',
            'label'  => 'traffic-in',
            'nlabel' => 'aks.node.traffic.in.bytes',
            'unit'   => 'B',
            'min'    => '0',
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
    my $resource_type = $self->{option_results}->{resource_type};
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.ContainerService\/managedClusters\/(.*)$/) {
        $resource_group = $1;
        $resource = $2;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = 'managedClusters';
    $self->{az_resource_namespace} = 'Microsoft.ContainerService';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : 'PT5M';
    $self->{az_aggregations} = ['Average'];
 
    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{az_metrics}}, $metric;
    }
}

1;

__END__

=head1 MODE

Check Azure Kubernetes Cluster network traffic usage in Bytes.

Example:

Using resource name:

perl centreon_plugins.pl --plugin=cloud::azure::compute::aks::plugin --mode=traffic --custommode=api
--resource=<cluster_id> --resource-group=<resourcegroup_id> --warning-traffic-out=10000 --critical-traffic-in=15000

Using resource ID:

perl centreon_plugins.pl --plugin=cloud::azure::compute::aks::plugin --mode=traffic --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.ContainerService/managedClusters/<cluster_id>' 
--warning-traffic-out=10000 --critical-traffic-in=15000


=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--warning-*>

Warning threshold where '*' can be: 'traffic-out', 'traffic-in'.


=item B<--critical-*>

Critical threshold where '*' can be: 'traffic-out', 'traffic-in'.

=back

=cut
