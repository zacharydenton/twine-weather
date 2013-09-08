express = require 'express'
request = require 'request'
Twitter = require 'ntwitter'

app = express()

app.configure 'development', ->
  app.use express.logger('dev')
  app.use express.errorHandler()

app.configure 'production', ->
  app.enable 'trust proxy'

app.configure ->
  app.set 'port', process.env.PORT or 4134
  app.use express.bodyParser()

app.get '/', (req, res) ->
  res.send 'twine-weather'

app.post '/', (req, res) ->
  if req.body.tweet
    api_key = '22975cf4b99ccf4f'
    params =
      query: req.body.params
    request.get {uri: "http://autocomplete.wunderground.com/aq", qs: params}, (err, result, body) =>
      console.log body
      json = JSON.parse(body)
      place = json.RESULTS[0]
      request.get {uri: "http://api.wunderground.com/api/#{api_key}/conditions#{place.l}"}, (err, results, body) ->
        console.log body
        json = JSON.parse(body)
        twitter = new Twitter
          consumer_key: req.body.auth.consumer_key
          consumer_secret: req.body.auth.consumer_secret
          access_token_key: req.body.auth.access_token_key
          access_token_secret: req.body.auth.access_token_secret
        params =
          in_reply_to_status_id: req.body.tweet.id
        if json.current_observation
          obs = json.current_observation
          twitter.updateStatus "@#{req.body.user.screen_name} #{obs.weather} #{obs.temperature_string} #{obs.wind_string} #{obs.ob_url}", params, (err, data) ->
            res.jsonp data

app.listen app.get('port'), ->
  console.log "Server started on port #{app.get 'port'} in #{app.settings.env} mode."
