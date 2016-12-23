namespace :crontab do
  desc "Install cronjobs"
  task :install => :environment do
    queue! %[echo "#{erb(File.join(__dir__, 'templates', 'crontab.erb'))}" > /tmp/crontab]
    queue! %[crontab /tmp/crontab]
  end
end
