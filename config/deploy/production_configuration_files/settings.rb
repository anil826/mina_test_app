set :branch, ENV['BRANCH'] || 'master'

set :domain, ENV['DOMAIN'] || '10.0.0.41'

set :user, 'anil'

set :unicorn_worker_count, 4

set :ssl_enabled, false

task :set_sudo_password => :environment do
  queue! "echo '#{erb(File.join(__dir__,'sudo_password.erb'))}' > /home/anil/SudoPass.sh"
  queue! "chmod +x /home/anil/SudoPass.sh"
  queue! "export SUDO_ASKPASS=/home/anil/SudoPass.sh"
end
