namespace :product_deployment_sheet do
  desc 'Test task for spreadsheet'
  task :update => :environment do
    status_row = [
        host_ip,
        rails_env,
        Time.now.to_s.gsub(' ', '@'),
        `git config user.name`.chomp.gsub(' ', '@'),
        branch,
        `git log --format="%H" -1 -b #{branch}`.chomp
    ]
    rake_task_str = "cd #{File.join(deploy_to, current_path)} && bundle exec rake deployment_sheet:update['#{status_row.join(' ').to_s}','#{sheet_name}','#{work_sheet_name}'] RAILS_ENV=#{rails_env}"
    queue! rake_task_str
  end
end