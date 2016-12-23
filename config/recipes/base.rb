def set_user
  default_user = 'deploy'
  STDOUT.print "\nDeploy as user(default:#{default_user}) : "
  user = STDIN.gets.strip
  user = default_user if user.empty?
  user
end

def set_branch
  default_branch = `git rev-parse --abbrev-ref HEAD`.chomp
  STDOUT.print "\nAssembla's Git branch to deploy from(default: #{default_branch}) : "
  branch = STDIN.gets.strip
  branch = default_branch if branch.empty?
  branch
end

def ask_sudo
  STDOUT.print "\nPlease enter SUDO password: "
  STDIN.gets.strip
end

def repository_url
  STDOUT.print "\nAssembla's Git Username: "
  _user_name = STDIN.gets.strip
  STDOUT.print "\nAssembla's Git Password: "
  _password = STDIN.noecho(&:gets).strip
   "https://#{_user_name}:#{_password}@git.assembla.com/papayaheaderlabs.Salak.git"
end