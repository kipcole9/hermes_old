load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'

desc "Symlink the database config to the current release directory." 
task :symlink_database_yml do 
  run "ln -nsf #{shared_path}/config/database.yml #{release_path}/config/database.yml" 
end

desc "Symlink the nginx_streaming plugin into the plugins directory - used only for ngix deployment." 
task :symlink_ngnix_streaming do 
  run "ln -nsf #{release_path}/vendor/deployment_plugins/nginx_streaming #{release_path}/vendor/plugins/ngix_streaming" 
end

desc "Restart mongrel_cluster" 
task :restart do 
  run "/etc/init.d/mongrel_cluster restart" 
end 

after 'deploy:update_code', 'symlink_database_yml'
after 'deploy:update_code', 'symlink_nginx_streaming'