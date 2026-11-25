# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.
#
# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
#
# You can control the number of workers using ENV["WEB_CONCURRENCY"]. You
# should only set this value when you want to run 2 or more workers. The
# default is already 1. You can set it to `auto` to automatically start a worker
# for each available processor.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
#
# Jukebox Hub: each open live stream (SSE) keeps one thread busy while it waits for events, without
# holding a database connection (see PartyEvents::Listener). So the thread count is much higher
# than the Rails default and is set apart from the database pool.
threads_count = ENV.fetch("PUMA_MAX_THREADS", 32)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Runs the Solid Queue workers inside Puma, so a single process serves the API and the background jobs
# (moving the queue to the next song). Always on in development; in production set SOLID_QUEUE_IN_PUMA.
if ENV["SOLID_QUEUE_IN_PUMA"] || ENV.fetch("RAILS_ENV", "development") == "development"
  plugin :solid_queue
  # By default Solid Queue forks a process for its worker, dispatcher and scheduler, each one a full
  # copy of the app. On a small server (Render's free plan has 512 MB) set SOLID_QUEUE_MODE=async to
  # run them as threads inside Puma instead.
  solid_queue_mode ENV.fetch("SOLID_QUEUE_MODE", "fork").to_sym

  # In async mode Solid Queue starts inside Puma's main process, which in cluster mode (worker
  # processes, e.g. when the host sets WEB_CONCURRENCY, as Render does) never loads the app: it would
  # fail with "uninitialized constant SolidQueue". So async mode means a single Puma process.
  workers 0 if ENV["SOLID_QUEUE_MODE"] == "async"
end

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
