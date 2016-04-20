This cookbook forks the official musicbrainz' chef cookbook.
It allows you to select what daemon supervisor you want to use (runit or daemontools).
Selection can be made by setting the init_style attribute:

default['musicbrainz-server']['init_style'] = 'runit'

or
default['musicbrainz-server']['init_style'] = 'daemontools'

