#!/usr/bin/env ruby
# An app for url shortening
# @author Nat Welch - https://github.com/icco/abelinkin

begin
   require "rubygems"
rescue LoadError
   puts "Please install Ruby Gems to continue."
   exit
end

# Check all of the gems we need are there.
[ "sinatra", "less", "sequel" ].each {|gem|
   begin
      require gem
   rescue LoadError
      puts "The gem #{gem} is not installed.\n"
      exit
   end
}

configure do
   set :sessions, true
   DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://data.db')
end

get '/' do
   erb :index
end

post '/' do
   e = Entry.new
   e.url = params[:url]
   e.hash = 'a'
   e.date = Time.now
   e.save

   redirect '/'
end

get /^[0-9a-f]+$/ do |hash|
   e = Entry.find(:hash => hash)

   e.inspect
end

get '/stats' do
   entries = Entry.all
   erb :stats, :locals => { :entries => entries }
end

get '/style.css' do
   content_type 'text/css', :charset => 'utf-8'
   less :style
end

class Entry < Sequel::Model(:entries)
   def hash= x
      if (self.entryid)
         super self.entryid.to_s(32)
      else
         super Entry.max(:entryid).to_s(32)
      end
   end
end
