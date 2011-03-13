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
[ "sinatra", "less", "sequel", "dalli" ].each {|gem|
   begin
      require gem
   rescue LoadError
      puts "The gem #{gem} is not installed.\n"
      exit
   end
}

configure do
   set :sessions, true
   set :logging, true

   DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://data.db')

   if (settings.environment == 'production')
      CACHE = Dalli::Client.new('localhost:11211')
      Sequel::Model.plugin :caching, CACHE, :ignore_exceptions => true
   end
end

get '/' do
   erb :index
end

post '/' do
   e = Entry.new
   e.url = params[:url]
   e.urlhash = 'a'
   e.date = Time.now
   e.save

   erb :saved, :locals => { :entry => e }
end

get '/stats' do
   entries = Entry.order(:date.desc).all
   erb :stats, :locals => { :entries => entries }
end

get '/style.css' do
   content_type 'text/css', :charset => 'utf-8'
   less :style
end

get %r{/([0-9a-f]+)/?} do |hash|
   e = Entry.find(:urlhash => hash)
   e.increment if !e.nil?
   redirect e.url
end

class Entry < Sequel::Model(:entries)
   def urlhash= x
      if (self.entryid)
         super self.entryid.to_s(32)
      else
         max = Entry.max(:entryid)
         max = max.nil? ? 0 : max + 1
         super max.to_s(32)
      end
   end

   # CALLS SAVE.
   def increment
      self.visits = self.visits.to_i.next
      self.save
   end
end
