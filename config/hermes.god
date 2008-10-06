# run with:  god -c /path/to/hermes.god
# 
# This is the actual config file used to keep the mongrels of
# hermes running.

RAILS_ROOT = "/u/apps/hermes/current"
RAILS_SHARED = "/u/apps/hermes/shared"

%w{8000 8001 8002}.each do |port|
  God.watch do |w|
    w.name = "hermes-mongrel-#{port}"
    w.group = "hermes"
    w.interval = 30.seconds # default      
    w.start = "mongrel_rails start -c #{RAILS_ROOT} -p #{port} \
      -P #{RAILS_SHARED}/log/mongrel.#{port}.pid -e production -d"
    w.stop = "mongrel_rails stop -P #{RAILS_SHARED}/log/mongrel.#{port}.pid"
    w.restart = "mongrel_rails restart -P #{RAILS_SHARED}/log/mongrel.#{port}.pid"
    w.start_grace = 10.seconds
    w.restart_grace = 10.seconds
    w.pid_file = File.join(RAILS_SHARED, "log/mongrel.#{port}.pid")
    
    w.behavior(:clean_pid_file)

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
      end
    end
    
    w.restart_if do |restart|
      restart.condition(:memory_usage) do |c|
        c.above = 150.megabytes
        c.times = [3, 5] # 3 out of 5 intervals
      end
    
      restart.condition(:cpu_usage) do |c|
        c.above = 50.percent
        c.times = 5
      end
    end
    
    # lifecycle
    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start, :restart]
        c.times = 5
        c.within = 5.minute
        c.transition = :unmonitored
        c.retry_in = 10.minutes
        c.retry_times = 5
        c.retry_within = 2.hours
      end
    end
  end
end