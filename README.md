# Abe Linkin

My attempt at a personal url shortner. Everyone and their mothers seems to have made one of these, so I figured I'd give it a shot. It's built on heroku, sinatra, and Sequel.

Feel free to fork customize and launch your own version.

## Libraries

This program is designed to be easily deployed to Heroku. It uses the following Heroku addons (which are free).

 * custom_domains:basic
 * logging:expanded
 * memcache:5mb
 * pgbackups:basic
 * shared-database:5mb

It also uses the following ruby gems.

 * dalli
 * less
 * logger
 * sequel
 * sinatra
 * uri

## Installation

So this assumes you have a working version of Ruby 1.9.2. I haven't tested with any other versions, so feel free to submit bug requests (or pull requests!) and the like if it needs some patches to work with your install.

I'm going to explain here how to deploy to Heroku. I plan on adding instructions to using passenger, but I have to figure that out first.

### Heroku

 1. First install the Heroku gem. `gem install heroku`.
 2. Pull down Abe Linkin. `git clone git://github.com/icco/abelinkin.git && cd abelinkin`
 3. Create a Heroku instance. `heroku create --stack bamboo-mri-1.9.2`
 4. Add caching. `heroku addons:add memcache:5mb`
 5. Deploy to Heroku. `git push heroku master`
 6. Initiate the Database. `heroku rake db`
 7. Play with your new app. `heroku open`

Optional things you can do.

 * Add better logging support to Heroku. `heroku addons:add logging:expanded`
 * Host on your own domain.
   1. `heroku addons:add custom_domains:basic`
   2. `heroku domains:add mydomain.com`
   3. `heroku domains:add www.mydomain.com`
