# Create the service from script file
cookbook_file "/etc/init.d/openfire" do
  mode '0755'
end

service "openfire" do
  supports :status => true,
           :stop => true,
           :restart => true
  action :nothing
end
