case node['musicbrainz-server']['init_style']
when 'runit'
  include_recipe 'runit::default'
when 'daemontools'
  include_recipe "daemontools"
end

include_recipe "musicbrainz-server::install"
include_recipe "nginx"

package "libcatalyst-plugin-autorestart-perl"
package "libcatalyst-plugin-errorcatcher-perl"
package "libstarlet-perl"


case node['musicbrainz-server']['init_style']
when 'daemontools'
  #BOF DAEMONTOOLS
  service "svscan" do
    action :start
    provider Chef::Provider::Service::Upstart
  end

  daemontools_service "musicbrainz-server-renderer" do
    directory "/home/musicbrainz/svc-musicbrainz-server-renderer"
    template "musicbrainz-server-renderer"
    variables :port => node['musicbrainz-server']['dbdefs']['renderer_port']
    action [:enable, :up]
    log false
  end

  daemontools_service "musicbrainz-server" do
    directory "/home/musicbrainz/svc-musicbrainz-server"
    template "musicbrainz-server"
    variables :nproc => node['musicbrainz-server']['nproc-website']
    action [:enable, :up]
    log true
  end

  daemontools_service "musicbrainz-ws" do
    directory "/home/musicbrainz/svc-musicbrainz-ws"
    template "musicbrainz-ws"
    variables :nproc => node['musicbrainz-server']['nproc-ws']
    action [:enable, :up]
    log true
  end

  link "/etc/service/musicbrainz-server-renderer/mb_server" do
    to "/home/musicbrainz/musicbrainz-server"
    owner "musicbrainz"
  end
  
  link "/etc/service/musicbrainz-server/mb_server" do
    to "/home/musicbrainz/musicbrainz-server"
    owner "musicbrainz"
  end

  link "/etc/service/musicbrainz-ws/mb_server" do
    to "/home/musicbrainz/musicbrainz-server"
    owner "musicbrainz"
  end
## EOF daemontools
when 'runit'
## BOF runit
  runit_service 'musicbrainz-server-renderer' do
    service_name 'musicbrainz-server-renderer'
    run_template_name "ri-musicbrainz-server-renderer"
    env('MUSICBRAINZ_USE_PROXY' => '1')
    options(port: node['musicbrainz-server']['dbdefs']['renderer_port'])
    action [:enable, :up]
    log false
  end

  runit_service 'musicbrainz-server' do
    service_name 'musicbrainz-server'
    log_template_name 'ri-musicbrainz-server'
    run_template_name 'ri-musicbrainz-server'
    env('MUSICBRAINZ_USE_PROXY' => '1')
    options(nproc: node['musicbrainz-server']['nproc-website'])
    action [:enable, :up]
  end
  runit_service 'musicbrainz-ws' do
    service_name 'musicbrainz-ws'
    log_template_name 'ri-musicbrainz-ws'
    run_template_name 'ri-musicbrainz-ws'
    env('MUSICBRAINZ_USE_PROXY' => '1')
    options(nproc: node['musicbrainz-server']['nproc-ws'])
    action [:enable, :up]
  end
  link "/etc/sv/musicbrainz-server-renderer/mb_server" do
    to "/home/musicbrainz/musicbrainz-server"
    owner "musicbrainz"
  end
  
  link "/etc/sv/musicbrainz-server/mb_server" do
    to "/home/musicbrainz/musicbrainz-server"
    owner "musicbrainz"
  end

  link "/etc/sv/musicbrainz-ws/mb_server" do
    to "/home/musicbrainz/musicbrainz-server"
    owner "musicbrainz"
  end

  directory '/var/log/musicbrainz-server' do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end
end

template "/etc/nginx/sites-available/musicbrainz" do
  source "nginx.conf.erb"
  user "root"
  variables(
    :listen_address => node['musicbrainz-server']['listen_address'],
    :server_name => node['musicbrainz-server']['hostname']
  )
  notifies :reload, "service[nginx]"
end

template "/etc/nginx/sites-available/nginxstatus" do
  source "nginxstatus.conf.erb"
  user "root"
  notifies :reload, "service[nginx]"
end

nginx_site "musicbrainz" do
  action :nothing
  subscribes :enable, "template[/etc/nginx/sites-available/musicbrainz]";
end

nginx_site "nginxstatus" do
  action :nothing
  subscribes :enable, "template[/etc/nginx/sites-available/nginxstatus]";
end

script "make_po" do
  user "musicbrainz"
  interpreter "bash"
  cwd "/home/musicbrainz/musicbrainz-server"
  environment "HOME" => "/home/musicbrainz"
  code <<-EOH
    make -C po all_quiet
    make -C po deploy
    EOH
  #action :nothing
  subscribes :run, "git[/home/musicbrainz/musicbrainz-server]"
  notifies :run, "script[install_new_npm]"
end

script "install_new_npm" do
  user "root"
  interpreter "bash"
  cwd "/root"
  environment "HOME" => "/root"
  code "npm install -g npm@3.5.2"
  action :nothing
  notifies :run, "script[compile_resources]"
end

script "compile_resources" do
  user "musicbrainz"
  interpreter "bash"
  cwd "/home/musicbrainz/musicbrainz-server"
  environment "HOME" => "/home/musicbrainz"
  code <<-EOH
    rm -r node_modules
    npm install
    ./script/compile_resources.sh
    echo "npm installed corrio carajo!" > /tmp/npm_mbz_install.txt
    EOH
  action :nothing
  notifies :run, "script[kick_services]"
end

script "kick_services" do
  case node['musicbrainz-server']['init_style']
  when 'runit'
    user "root"
    interpreter "bash"
    cwd "/root"
    environment "HOME" => "/root"
    code <<-EOH
      sv reload /etc/service/musicbrainz-server
      sv reload /etc/service/musicbrainz-ws
      #sv down /etc/service/musicbrainz-server-renderer
      EOH
    action :nothing
  when 'daemontools'
    user "root"
    interpreter "bash"
    cwd "/root"
    environment "HOME" => "/root"
    code <<-EOH
      svc -h /etc/service/musicbrainz-server
      svc -h /etc/service/musicbrainz-ws
      svc -t /etc/service/musicbrainz-server-renderer
      EOH
    action :nothing
  end
end
