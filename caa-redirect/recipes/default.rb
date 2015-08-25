include_recipe "apt"

package "python-cherrypy3"
package "python-psycopg2"
package "python-sqlalchemy"
package "python-werkzeug"

user "coverart_redirect" do
  action :create
  home "/home/coverart_redirect"
  shell "/bin/bash"
  supports :manage_home => true
end

package "git"
git "/home/coverart_redirect/coverart_redirect" do
  repository "git://github.com/metabrainz/coverart_redirect.git"
  revision node['caa-redirect'][:revision]
  action :sync
  user "coverart_redirect"
end

template "/home/coverart_redirect/coverart_redirect/coverart_redirect.conf" do
  owner "coverart_redirect"
  mode "644"
  variables :config => node['caa-redirect']
end

include_recipe "daemontools"
service "svscan" do
  action :start
  provider Chef::Provider::Service::Upstart
end

daemontools_service "caa-redirect" do
  directory "/home/coverart_redirect/svc-coverart_redirect"
  template "coverart_redirect"
  log true
  action [:enable, :start]
end

link "/home/coverart_redirect/svc-coverart_redirect/coverart_redirect" do
  to "/home/coverart_redirect/coverart_redirect"
end
