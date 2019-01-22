default[:openfire][:source_tarball] = 'openfire_4_1_5.tar.gz'

# precalculated checksums: `sha256sum openfire_v_v_v.tar.gz | cut -c1-16`
checksums = {
	'openfire_4_1_5.tar.gz' => '219a2f52539ecc4b',
	'openfire_3_8_1.tar.gz' => '554dce3a1b0a0b88',
	'openfire_3_8_0.tar.gz' => 'd5bef61a313ee41b',
	'openfire_3_10_3.tar.gz' => '25c207c19ac060c4'
}

default[:openfire][:base_dir] = '/opt'
default[:openfire][:home_dir] = "#{openfire[:base_dir]}/openfire"
default[:openfire][:log_dir]  = '/var/log/openfire'
default[:openfire][:opts]     = "\"-Xms256m -Xmx2048m -javaagent:#{node[:openfire][:home_dir]}/newrelic/newrelic.jar\""

default[:openfire][:user]  = 'openfire'
default[:openfire][:group] = 'openfire'

default[:openfire][:pidfile] = '/var/run/openfire.pid'

# Admin info
default[:openfire][:password] = 'Videri123'

# Logs retention configuration
default[:openfire][:log_info_size] = '20M'
default[:openfire][:log_info_count] = '10'
default[:openfire][:log_debug_size] = '20M'
default[:openfire][:log_debug_count] = '10'
default[:openfire][:log_warn_size] = '20M'
default[:openfire][:log_warn_count] = '10'
default[:openfire][:log_error_size] = '20M'
default[:openfire][:log_error_count] = '10'
default[:openfire][:log_all_size] = '20M'
default[:openfire][:log_all_count] = '10'

# RestAPI info
default[:openfire][:api_secret] = 'DSpfe2a5sv96LN4I'

# By default, only enable secure admin port
default[:openfire][:config][:admin_console][:port]        = 9090
default[:openfire][:config][:admin_console][:secure_port] = 9091
default[:openfire][:config][:locale] = 'en'
default[:openfire][:config][:network][:interface] = nil

# Database info
# Take the name of the stack_hostname for the db name (replace - by _ MySQL really doesn't like -)
default[:openfire][:database][:name]      = "#{normal[:opsworks][:stack][:name]}_openfire"
default[:openfire][:database][:name]      = default[:openfire][:database][:name].tr('-', '_')

default[:openfire][:database][:type]      = 'mysql'
default[:openfire][:database][:port]      = '3306'
default[:openfire][:database][:user]      = 'openfire'
default[:openfire][:database][:password]  = 'password'
default[:openfire][:database][:driver] 		= 'com.mysql.jdbc.Driver'

# Newrelic
default[:openfire][:app_name] = "(#{normal[:opsworks][:stack][:name]})-xmpp"

# Hazelcast
default[:openfire][:hazelcast][:aws][:access_key] = node[:aws][:ro_access_key]
default[:openfire][:hazelcast][:aws][:secret_key] = node[:aws][:ro_secret_key]
default[:openfire][:hazelcast][:aws][:region] = node[:aws][:S3][:region]
default[:openfire][:hazelcast][:aws][:host_header] = 'ec2.amazonaws.com'
default[:openfire][:hazelcast][:aws][:security_group_name] = 'AWS-OpsWorks-OpenFire-Server'
default[:openfire][:hazelcast][:aws][:tag_key] = 'opsworks:stack'
default[:openfire][:hazelcast][:aws][:tag_value] = node[:opsworks][:stack][:name]
