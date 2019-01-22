name             "openfire_v4"
description      "Installs Openfire Version 4 Jabber server"
maintainer       "devops"
maintainer_email "vrajkishore@hotmail.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.0"

depends 'java'
depends 'sk_s3_file'

recipe "openfire::setup",  "Installs openfire"
recipe "openfire::stop",   "Stop the openfire service"
recipe "openfire::config", "Config the openfire service"
