require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rvm' # for rvm support. (http://rvm.io)
require 'yaml'
require 'io/console'

['base', 'nginx', 'mysql', 'check'].each do |pkg|
  require "#{File.join(__dir__, 'recipes', "#{pkg}")}"
end

set :application, 'Salak'
set :user, 'deploy'
set :deploy_to, "/home/#{fetch(:user)}/#{fetch(:application)}"
set :repository, repository_url
set :branch, set_branch
set :rvm_path, '/usr/local/rvm/scripts/rvm'
set :sheet_name, 'Product deployment status'
set :work_sheet_name, 'Salak'

set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml')
set :ruby_version, "#{File.readlines(File.join(__dir__, '..', '.ruby-version')).first.strip}"
set :gemset, "#{File.readlines(File.join(__dir__, '..', '.ruby-gemset')).first.strip}"

task :environment do
  set :rails_env, ENV['on'].to_sym unless ENV['on'].nil?
  require "#{File.join(__dir__, 'deploy', "#{staging_configurations_files}", "staging.rb")}"
  invoke :'rvm:use', "ruby-#{fetch(:ruby_version)}@#{fetch(:gemset)}"
end
task :setup => :environment do
  invoke :set_sudo_password
  command %[mkdir -p "#{fetch(:shared_files)}/log"]
  command %[chmod g+rx,u+rwx "#{fetch(:shared_files)}/log"]

  command %[mkdir -p "#{fetch(:shared_files)}/config"]
  command %[chmod g+rx,u+rwx "#{fetch(:shared_path)}/config"]

  # creating ebay config yml it will be sym-linked to current/ebay_ymls
  command %[mkdir -p "#{fetch(:shared_files)}/ebay_ymls"]
  command %[chmod g+rx,u+rwx "#{fetch(:shared_files)}/ebay_ymls"]

  command %[mkdir -p "#{fetch(:shared_files)}/tmp/pids"]
  command %[chmod g+rx,u+rwx "#{fetch(:shared_files)}/tmp/pids"]

  command %[touch "#{fetch(:shared_files)}/config/database.yml"]
  invoke :setup_prerequesties
  invoke :setup_yml
  comment %[echo "-----> Be sure to edit 'shared/config/*.yml files'."]

end

task :setup_prerequesties => :environment do
  command 'echo "-----> Installing development dependencies"'
  [
      'python-software-properties', 'libmysqlclient-dev', 'imagemagick', 'libmagickwand-dev', 'nodejs',
      'build-essential', 'zlib1g-dev', 'libssl-dev', 'libreadline-dev', 'libyaml-dev', 'libcurl4-openssl-dev', 'curl',
      'git-core', 'make', 'gcc', 'g++', 'pkg-config', 'libfuse-dev', 'libxml2-dev', 'zip', 'libtool',
      'xvfb', 'mysql-client', 'mysql-server', 'mime-support', 'automake'
  ].each do |package|
    puts "Installing #{package}"
    command %[sudo -A apt-get install -y #{package}]
  end

  comment 'echo "-----> Installing Ruby Version Manager"'
  command %[command curl -sSL https://rvm.io/mpapis.asc | gpg --import]
  command %[curl -sSL https://get.rvm.io | bash -s stable --ruby]

  command %[source "#{fetch(:rvm_path)}"]
  command %[rvm requirements]
  command %[rvm install "#{fetch(:ruby_version)}"]
  # invoke :'rvm:use', 'ruby-2.3.1@salak'
  command %[gem install bundler]
  command %[mkdir "#{fetch(:deploy_to)}"]
  command %[chown -R "#{fetch(:user)}" "#{fetch(:deploy_to)}"]
  # #setup nginx
  invoke :'nginx:install'
  # #setup nginx
  invoke :'nginx:setup'
  invoke :'nginx:restart'

end
# SSL certificates path
set :cert_path, "#{fetch(:deploy_to)}/current/certs/SSL.crt"
set :cert_key_path, "#{fetch(:deploy_to)}/current/certs/socialmatic.key"

task :setup_yml => :environment do
  # invoke :set_sudo_password
  Dir[File.join(__dir__, '*.yml.example')].each do |_path|
    command %[echo "#{erb _path}" > "#{File.join(fetch(:deploy_to), 'shared/config', File.basename(_path, '.yml.example') +'.yml')}"]
  end
end

desc "Deploys the current version to the server."
task :deploy => :environment do


  deploy do
    run :local do
      # set :repository, repository_url
      # set :branch, set_branch
    end
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'check:revision'
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'mysql:create_database'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'

  end
  on :launch do
  end
  invoke :restart
end


task :set_sudo_password => :environment do
  set :sudo_password, ask_sudo
  command "echo '#{erb(File.join(__dir__, 'deploy', "#{fetch(:rails_env)}_configurations_files", 'sudo_password.erb'))}' > /home/#{fetch(:user)}/SudoPass.sh"
  command "chmod +x /home/#{fetch(:user)}/SudoPass.sh"
  command "export SUDO_ASKPASS=/home/#{fetch(:user)}/SudoPass.sh"
end


desc 'Restart passenger server'
task :restart => :environment do
  invoke :set_sudo_password
  # invoke :'crontab:install'
  command %[sudo -A service nginx restart]
  comment 'echo "-----> Start Passenger"'
  command %[mkdir -p #{File.join(fetch(:current_path), 'tmp')}]
  command %[touch #{File.join(fetch(:current_path), 'tmp', 'restart.txt')}]
  # invoke :'product_deployment_sheet:update'
end