set :application, "hermes"
set :repository,  "git@github.com:kipcole9/hermes.git"

set :user, "kip"
set :runner, "kip"
set :run_method, :run
set :ssh_options, { :forward_agent => true, :port => 9876 }

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/home/kip/apps/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git

role :app, "kipcole.com"
role :web, "kipcole.com"
role :db,  "kipcole.com", :primary => true

