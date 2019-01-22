# Set group
group node[:openfire][:group] do
  system true
end

#Set User
user node[:openfire][:user] do
  gid node[:openfire][:group]
  home node[:openfire][:home_dir]
  system true
  shell '/bin/sh'
end

###############################################################################
# Install postgresql-client
#
#

package 'postgresql-client' do
  package_name value_for_platform(
                   ['centos','redhat','fedora','amazon'] => {'default' => 'postgresql'},
                   'ubuntu' => {'default' => 'postgresql-client'}
               )
  action :install
  only_if { node[:openfire][:database][:type] == 'postgresql' }
end

###############################################################################
# Force install mysql client
# (mysql::client recipe won't install if there is no db layer, WTF!!!)
#
package 'mysql-devel' do
  package_name value_for_platform(
                   ['centos','redhat','fedora','amazon'] => {'default' => 'mysql-devel'},
                   'ubuntu' => {'default' => 'libmysqlclient-dev'}
               )
  action :install
  only_if { node[:openfire][:database][:type] == 'mysql' }
end

package 'mysql-client' do
  package_name value_for_platform(
                   ['centos','redhat','fedora','amazon'] => {'default' => 'mysql'},
                   'default' => 'mysql-client'
               )
  action :install
  only_if { node[:openfire][:database][:type] == 'mysql' }
end
###############################################################################
# Set global environment variables
# on Debian/Ubuntu we use /etc/default instead of /etc/sysconfig
#
# Make a symlink so that openfire and ssh_tunnel scripts are happy
#
link '/etc/sysconfig' do
  to '/etc/default'
  only_if { node[:platform_family] == 'debian' }
end

# Variables template file
template '/etc/sysconfig/openfire' do
  mode '0644'
end

###############################################################################
# Get the openfire install tarball
#
#local_tarball_path = "#{Chef::Config[:file_cache_path]}/#{node[:openfire][:source_tarball]}"

local_tarball_path = "#{Chef::Config[:file_cache_path]}/#{node[:openfire][:source_tarball]}"

remote_file local_tarball_path do
  checksum node[:openfire][:source_checksum]
  source "https://s3.amazonaws.com/cookbooks-missing-files/#{node[:openfire][:source_tarball]}"
end

###############################################################################
# DB import file
#
template "#{node[:openfire][:base_dir]}/openfire_postgresql.sql" do
  group 'openfire'
  owner 'openfire'
end

template "#{node[:openfire][:base_dir]}/openfire_mysql.sql" do
  group 'openfire'
  owner 'openfire'
end


###############################################################################
# Do install
#
bash "install_openfire" do
  cwd node[:openfire][:base_dir]
  code <<-EOH
    tar xzf #{local_tarball_path}
    chown -R #{node[:openfire][:user]}:#{node[:openfire][:group]} #{node[:openfire][:home_dir]}
    mv #{node[:openfire][:home_dir]}/conf /etc/openfire
    rm /etc/openfire/openfire.xml
    mv #{node[:openfire][:home_dir]}/logs /var/log/openfire
    mv #{node[:openfire][:home_dir]}/resources/security /etc/openfire
  EOH
  creates node[:openfire][:home_dir]
end

###############################################################################
# Init DB

bash "init_openfire_db_postgres" do
  cwd node[:openfire][:base_dir]
  code <<-EOH
    export PGPASSWORD='#{node[:openfire][:database][:password]}'
    if ! psql -h #{node[:openfire][:database][:hosts]} -p #{node[:openfire][:database][:port]} -U #{node[:openfire][:database][:username]} -c '\\connect  #{node[:openfire][:database][:name]}'; then
      createdb -h #{node[:openfire][:database][:hosts]} -p #{node[:openfire][:database][:port]} -U #{node[:openfire][:database][:username]}  -E UTF8 #{node[:openfire][:database][:name]}
      psql -h #{node[:openfire][:database][:hosts]} -p #{node[:openfire][:database][:port]} -U #{node[:openfire][:database][:username]} #{node[:openfire][:database][:name]} < #{node[:openfire][:base_dir]}/openfire_postgresql.sql
    fi
  EOH
  only_if { node[:openfire][:database][:type] == 'postgresql' }
end

bash "init_openfire_db" do
  cwd node[:openfire][:base_dir]
  code <<-EOH
    if ! mysql --host=#{node[:openfire][:database][:hosts]} -P #{node[:openfire][:database][:port]} -u #{node[:openfire][:database][:username]} -p#{node[:openfire][:database][:password]}  -e 'USE #{node[:openfire][:database][:name]}'; then
      mysql --host=#{node[:openfire][:database][:hosts]} -P #{node[:openfire][:database][:port]} -u #{node[:openfire][:database][:username]} -p#{node[:openfire][:database][:password]} -e "CREATE DATABASE IF NOT EXISTS #{node[:openfire][:database][:name]} CHARACTER SET='utf8';"
      mysql --host=#{node[:openfire][:database][:hosts]} -P #{node[:openfire][:database][:port]} -u #{node[:openfire][:database][:username]} -p#{node[:openfire][:database][:password]} #{node[:openfire][:database][:name]} < #{node[:openfire][:base_dir]}/openfire_mysql.sql
    fi
  EOH
  only_if { node[:openfire][:database][:type] == 'mysql' }
end

###############################################################################
# Copy the new relic agent and cfg files
#
remote_directory "#{node[:openfire][:home_dir]}/newrelic" do
  files_mode '0440'
  files_group 'openfire'
  files_owner 'openfire'
  group 'openfire'
  owner 'openfire'
  source 'newrelic'
  mode '0770'
end

# Set new relic config from template
template "#{node[:openfire][:home_dir]}/newrelic/newrelic.yml" do
  group 'openfire'
  owner 'openfire'
  mode '0600'
end

# Link to LSB-recommended directories
link "#{node[:openfire][:home_dir]}/conf" do
  to '/etc/openfire'
end

link "#{node[:openfire][:home_dir]}/logs" do
  to '/var/log/openfire'
end

link "#{node[:openfire][:home_dir]}/resources/security" do
  to '/etc/openfire/security'
end

# This directory contains keys, so lock down its permissions
directory '/etc/openfire/security' do
  group 'openfire'
  owner 'openfire'
  mode '0700'
end

template '/etc/openfire/security.xml' do
  group 'openfire'
  owner 'openfire'
  mode '0600'
end

template "#{node[:openfire][:home_dir]}/lib/log4j.xml" do
  group 'openfire'
  owner 'openfire'
  mode '0600'
end

template '/etc/openfire/openfire.xml' do
  group 'openfire'
  owner 'openfire'
  mode '0600'
  variables :server_url => "jdbc:postgresql://#{node[:openfire][:database][:hosts]}:#{node[:openfire][:database][:port]}/#{node[:openfire][:database][:name]}"
  only_if { node[:openfire][:database][:type] == 'postgresql' }
end

template '/etc/openfire/openfire.xml' do
  group 'openfire'
  owner 'openfire'
  mode '0600'
  variables :server_url => "jdbc:mysql://#{node[:openfire][:database][:hosts]}:#{node[:openfire][:database][:port]}/#{node[:openfire][:database][:name]}"
  only_if { node[:openfire][:database][:type] == 'mysql' }
end

include_recipe "openfire_v4::service"

# Install plugins
cookbook_file "#{node[:openfire][:home_dir]}/plugins/subscription.jar" do
  source 'subscription.jar'
  notifies :restart, 'service[openfire]'
end

cookbook_file "#{node[:openfire][:home_dir]}/plugins/restAPI.jar" do
  source 'restAPI.jar'
  notifies :restart, 'service[openfire]'
end

cookbook_file "#{node[:openfire][:home_dir]}/plugins/hazelcast.jar" do
  source 'hazelcast.jar'
  notifies :restart, 'service[openfire]', :immediately
end

ruby_block 'Wait for hazelcast plugin install' do
  block do
    until ::File.exists?('/opt/openfire/plugins/hazelcast/classes/hazelcast-cache-config.xml')
      Chef::Log.info('Sleeping 3 seconds until hazelcast plugin install is completed')
      sleep 3
    end
  end
end

template 'hazelcast_cache_config' do
  source 'hazelcast-cache-config.xml.erb'
  path '/opt/openfire/plugins/hazelcast/classes/hazelcast-cache-config.xml'
  group 'openfire'
  owner 'openfire'
  mode '0600'
  variables({
    :members => node[:hazelcast][:tcp_ip][:internal_ip]
  })
  notifies :restart, 'service[openfire]'
end

include_recipe "openfire_v4::service"

# Start the service
service "openfire" do
  action [ :enable, :start ]
end

admin_console = node[:openfire][:config][:admin_console]
admin_port = (admin_console[:secure_port] == -1)? admin_console[:port] : admin_console[:secure_port]
log "And now visit the server on :#{admin_port} to run the openfire wizard." do
  action :nothing
end
