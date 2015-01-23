# nagios-plugins

Custom scripts for Nagios-based monitoring systems. Please note that these scripts are designed to be deployed using Chef, and are set to use the Chef-bundled version of Ruby rather than any installed system Ruby version.

## check_netscaler_health.rb
Script for checking the health of a NetScaler load balancer. Currently can retrieve overall CPU usage and memory usage, and the high availability status (if configured).

## check_netscaler_vserver.rb
Script for checking the availability of a virtual server on a NetScaler load balancer. By default the script will return a warning status if half of the backend servers are unavailable and a critical status if all backend servers are unavailable.

## check_smart.rb
Script for checking SMART attributes of one or a set of hard drives. The logic behind the script comes from the blog post here: https://www.backblaze.com/blog/hard-drive-smart-stats/. This script will only work for hard drives that return raw values for SMART attributes.
