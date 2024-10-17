web: bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec foreman start -c sidekiq=1,clock=1,message=1, -f Procfile.worker.$SERVER_CONTEXT.$SERVER_NAME

# WEB
# run node(ui) or rails(api) web server

# Worker
# run specific Procfile based on server context(dev, qa, live) and server name (api, ui, fire, etc)
