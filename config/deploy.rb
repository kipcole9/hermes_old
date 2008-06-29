set :application, "hermes"
set :repository,  "git://kip-macbook.refuge.noexpectations.com.au/users/kip/development/hermes.git"
set :port, 6000
set :password, "crater123"
set :runner, "kip"


# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/kip/apps/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git

role :app, "kipcole.com"
role :web, "kipcole.com"
role :db,  "kipcole.com", :primary => true

