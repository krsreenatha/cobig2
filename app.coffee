# Module dependencies
express = require 'express'
yaml = require 'js-yaml'
assets = require 'connect-assets'

RedisStore = require("connect-redis")(express)

routes = require './routes'
api = require './routes/api'
config = require './config.yaml'

basicAuth = require './modules/basicAuth'

app = module.exports = express()

# Configuration
app.locals config
app.configure ->
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  # Sessions
  app.use express.cookieParser()
  app.use express.session store: new RedisStore, secret: process.env.SESSION_SECRET
  # Assets
  app.use assets()
  app.use express.static "#{__dirname}/public"
  app.locals.GANALYTICS = process.env.GANALYTICS

app.configure 'development', ->
  app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', ->
  app.use express.errorHandler()

app.configure 'staging', ->
  app.use basicAuth

# Routes
app.get '/', routes.index
app.get '/templates/:name', routes.templates
app.get '/partials/:name', routes.partials

# JSON API
app.get '/api/linkedin/team', api.linkedin.members
app.get '/api/linkedin/team/:user', api.linkedin.members
app.get '/api/linkedin/get/*', api.linkedin.get unless 'production' is app.get 'env'
app.get '/api/linkedin/authenticate/request/:user', api.linkedin.authenticate.request
app.get '/api/linkedin/authenticate/get', api.linkedin.authenticate.get
app.get '/api/linkedin/:folder', api.linkedin.getMembersFromDropbox
app.get '/api/linkedin/:folder/:user', api.linkedin.getMembersFromDropbox
app.get '/api/facebook/authenticate/request/:user', api.facebook.authenticate.request
app.get '/api/facebook/authenticate/get', api.facebook.authenticate.get
app.get '/api/facebook/photos/:album', api.facebook.photos
app.get '/api/mendeley/papers', api.mendeley.papers
app.get '/api/dropbox/authenticate/request/:user', api.dropbox.authenticate.request
app.get '/api/dropbox/authenticate/get', api.dropbox.authenticate.get
app.get '/api/dropbox/ls', api.dropbox.ls
app.get '/api/dropbox/files/:first/:second?', api.dropbox.files
app.get '/media/:file', api.dropbox.media
app.get '/api/dropbox/files_put/:file', api.dropbox.files_put

# redirect all others to the index (HTML5 history)
app.get '*', routes.index unless app.get 'env' is 'staging'

# error handler
app.use (err, req, res, next) ->
  console.error err
  res.json err

# Start server
port = process.argv[2] or process.env.PORT or 3000;
app.listen port, ->
  console.log "Express server listening on port %d in %s mode", @address().port, app.settings.env
