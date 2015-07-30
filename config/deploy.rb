require 'mina/bundler'
require 'mina/rails'
require 'mina/git'

# require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
require 'mina/rvm'    # for rvm support. (http://rvm.io)
require 'yaml'

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :domain, '192.168.1.7'
set :deploy_to, '/var/www/blog.com'
set :repository, 'https://github.com/anil826/mina_test_app'
set :branch, 'master'
set :rails_env, :staging
# For system-wide RVM install.
#   set :rvm_path, '/usr/local/rvm/bin/rvm'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/database.yml', 'config/secrets.yml', 'log']

# Optional settings:
#   set :user, 'foobar'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
  set :rails_env, ENV['on'].to_sym unless ENV['on'].nil?
  # For those using RVM, use this to load an RVM version@gemset.
  require "#{File.join(__dir__, 'deploy', "#{rails_env}_configuration_files", 'settings')}"
  invoke :"rvm:use[ruby-#{ruby_version}@#{gemset}]"
end

# DON't RUN THIS TASK, IT WILL RUN FROM SETUP
task :setup_prerequesties => :environment do
  queue! %[sudo -A apt-get install mysql-server git-core libmysqlclient-dev nodejs nginx]
  queue! %[mkdir "#{deploy_to}"]
  queue! %[chown -R "#{user}" "#{deploy_to}"]
  queue! %[curl -sSL https://get.rvm.io | bash -s stable --ruby]
  queue! %[source "#{rvm_path}"]
  queue! %[rvm requirements]
  queue! %[rvm install "#{ruby_version}"]

  #setup nginx
  queue! %[sudo -A su -c "echo '#{erb(File.join(__dir__, 'deploy', 'common_template', 'nginx_conf.erb'))}' > /etc/nginx/sites-enabled/#{application}"]
  queue! %[sudo -A rm -f /etc/nginx/sites-enabled/default]

  #set unicorn settings
  queue! %[echo "#{erb(File.join(__dir__, 'deploy', 'common_template', 'unicorn.erb'))}" > #{File.join(deploy_to, shared_path, '/config/unicorn.rb')}]

  #setup unicorn
  queue! %[echo '#{erb(File.join(__dir__, 'deploy', 'common_template', 'unicorn_init.erb'))}' > /tmp/unicorn_#{application}]
  queue! %[chmod +x /tmp/unicorn_#{application}]
  queue! %[sudo -A mv -f /tmp/unicorn_#{application} /etc/init.d/unicorn_#{application}]
  queue! %[sudo -A update-rc.d -f unicorn_#{application} defaults]

  queue! %[sudo -A service nginx restart]
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  queue! %[touch "#{deploy_to}/#{shared_path}/config/secrets.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml' and 'secrets.yml'."]
  invoke :setup_prerequesties

  # queue %[
  #   repo_host=`echo $repo | sed -e 's/.*@//g' -e 's/:.*//g'` &&
  #   repo_port=`echo $repo | grep -o ':[0-9]*' | sed -e 's/://g'` &&
  #   if [ -z "${repo_port}" ]; then repo_port=22; fi &&
  #   ssh-keyscan -p $repo_port -H $repo_host >> ~/.ssh/known_hosts
  # ]
end


# RUN THIS to deploy to all webs
task :deploy_to_all_web => :environment do
  invoke :set_sudo_password
  queue! %[sudo -A service unicorn_#{application} stop]
  invoke :deploy
  queue! %[sudo -A service nginx restart]
  queue! %[sudo -A service unicorn_#{application} start]

end

desc 'Restart unicorn server'
task :restart => :environment do
  invoke :set_sudo_password
  queue! %[sudo -A service unicorn_#{application} stop]
  queue! %[sudo -A service nginx restart]
  queue! %[sudo -A service unicorn_#{application} start]
end


desc "Deploys the current version to the server."
# DON'T RUN THIS TASK IT WILL RUN FROM deploy_to_all_worker or deploy_to_all_web
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'

    invoke :install_cron
    #to :launch do
    #end
  end
  invoke :restart
end


# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers
