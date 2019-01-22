include_recipe "openfire_v4::service"

service "openfire" do
  action :stop
end
