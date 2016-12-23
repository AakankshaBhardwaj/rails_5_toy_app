namespace :mysql do

  desc "Create a database for this application."
  task :create_database => :environment do
    command %[echo "cd  #{fetch(:current_path)}; bundle exec rake db:create RAILS_ENV=staging"]
  end
end