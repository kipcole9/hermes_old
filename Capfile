load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'

namespace(:deploy) do
  desc "Symlink the database config to the current release directory." 
  task :symlink_database_yml do 
    run "ln -nsf #{shared_path}/config/database.yml #{release_path}/config/database.yml" 
  end

  desc "Symlink the nginx_streaming plugin into the plugins directory - used only for ngix deployment." 
  task :symlink_nginx_streaming do 
    run "ln -nsf #{release_path}/vendor/deployment_plugins/nginx_streaming #{release_path}/vendor/plugins/ngix_streaming" 
  end

  desc "Restart mongrel_cluster" 
  task :restart do 
    run "/etc/init.d/mongrel_cluster restart" 
  end
  
  desc "Create asset packages for production" 
  task :create_asset_packages, :roles => [:web] do
    run <<-EOF
      cd #{release_path} && rake RAILS_ENV=production asset:packager:build_all
    EOF
  end
  
  desc "Run database migrations"
  task :run_database_migrations, :roles => [:db] do
    run "cd #{release_path} && rake RAILS_ENV=production db:migrate"
  end

  after 'deploy:update_code', 'deploy:create_asset_packages'
  after 'deploy:update_code', 'deploy:symlink_database_yml'
  after 'deploy:update_code', 'deploy:symlink_nginx_streaming'
  after 'deploy:update_code', 'deploy:run_database_migrations'
end

namespace(:web) do
  desc "Restart nginx server"
  task :restart do
    run "/etc/init.d/nginx restart"
  end
  
  desc "Stop nginx server"
  task :stop do
    run "/etc/init.d/nginx stop"
  end
  
  desc "Start nginx server"
  task :start do
    run "/etc/init.d/nginx start"
  end
  
  desc "Reconfigure nginx server"
  task :reconfigure do
    run "/etc/init.d/nginx reconfigure"
  end
  
  desc "Tail of nginx error log"
  task :error_log do
    stream "tail -f /usr/local/nginx/logs/error.log"
  end
  
  desc "Tail of nginx access log"
  task :access_log do
    stream "tail -f /usr/local/nginx/logs/access.log"
  end
end