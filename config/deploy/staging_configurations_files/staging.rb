#========== Instance Details===============#
set :host_ip, '35.160.61.32'
set :domain, fetch(:host_ip)
#==========================================#

#===============Rails Environment =========#
set :rails_env, 'staging'
set :ssl_enabled, true
#==========================================#