set :application, "hermes"
set :repository,  "git://kip-macbook.refuge.noexpectations.com.au/users/kip/development/hermes.git"
set :port, 6000
set :password, "2arieshere"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git

role :app, "kip-ubuntu"
role :web, "kip-ubuntu"
role :db,  "kip-ubuntu", :primary => true

namespace :deploy do
  task :start, :roles => :app do
    invoke_command "sh -c 'cd #{current_path} && mongrel_rails mongrel::start -d -p 80'"
  end

  task :stop, :roles => :app do
    invoke_command "sh -c 'cd #{current_path} && mongrel_rails mongrel::stop'"
  end

  task :restart, :roles => :app do
    invoke_command "sh -c 'cd #{current_path} && mongrel_rails mongrel::stop'"
    invoke_command "sh -c 'cd #{current_path} && mongrel_rails mongrel::start -d -p 80'"
  end
end