# Abe Linkin

My attempt at a personal url shortner. Everyone and their mothers seems to have made one of these, so I figured I'd give it a shot. It's built on heroku, sinatra, and Sequel.

Feel free to fork customize and launch your own version.

## Installation

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
