# musicbrainz-server git tag
default['musicbrainz-server']['revision'] =  'v-2016-03-21'
default['musicbrainz-server']['environment'] = node.chef_environment
# Select to use runit or daemontools:
default['musicbrainz-server']['init_style'] = 'runit'
# for nginx virtualhost
default['musicbrainz-server']['hostname'] = node.fqdn
default['musicbrainz-server']['listen_address'] = '80'
default['musicbrainz-server']['nproc-ws'] = 4
default['musicbrainz-server']['nproc-website'] = 4
default['musicbrainz-server']['dbdefs']['replication_type'] = 'RT_SLAVE'
default['musicbrainz-server']['dbdefs']['db_schema_sequence'] = 22
default['musicbrainz-server']['dbdefs']['renderer_port'] = '9009'
