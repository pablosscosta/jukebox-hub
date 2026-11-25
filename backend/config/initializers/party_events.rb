# In development, changed code is reloaded: stop the events listener of the old code first, or each
# reload would leave one more LISTEN thread holding a database connection.
Rails.application.reloader.before_class_unload do
  PartyEvents::Listener.instance.stop if defined?(PartyEvents::Listener)
end
