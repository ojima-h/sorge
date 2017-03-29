require 'sorge/server'

# Rackup Sorge server:
#
#     $ rackup sample/config.ru

options = {
  sorgefile: 'test/Sorgefile.rb'
}
run Sorge::Server.create(options)
