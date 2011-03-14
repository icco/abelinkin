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
[ "logger", "sinatra", "less", "sequel", "dalli", "uri" ].each {|gem|
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

   # Print all queries to stdout
   dblogger = Logger.new(STDOUT)
   def dblogger.format_message(level, time, progname, msg)
      " DATABASE - - [#{time.strftime("%d/%b/%Y %H:%M:%S")}] #{msg}\n"
   end
   DB.loggers << dblogger

   if (settings.environment == :production)
      CACHE = Dalli::Client.new
      Sequel::Model.plugin :caching, CACHE, :ignore_exceptions => true
   end
end

not_found { erb :fourohfour }
error do
   error = request.env['sinatra_error']
   erb :fivehundred, :locals => { :error => error }
end

get '/' do
   erb :index
end

post '/' do
   e = Entry.build params[:url]

   if !e.nil?
      erb :saved, :locals => { :entry => e }
   else
      error 'Not a valid url'
   end
end

get %r{^/s(tats)?/?$} do
   r = Entry.order(:date.desc).all
   p = Entry.order(:visits.desc).all

   erb :stats, :locals => { :recent => r, :popular => p}
end

get %r{^/s(tats)?/([0-9A-z\-\_]+)/?$} do |crap, hash|
   e = Entry.find(:urlhash => hash)
   if !e.nil?
      erb :stat, :locals => { :entry => e }
   else
      error 404
   end
end

get '/style.css' do
   content_type 'text/css', :charset => 'utf-8'
   less :style
end

get %r{^/([0-9A-z\-\_]+)/?$} do |hash|
   e = Entry.find(:urlhash => hash)
   if !e.nil?
      e.increment
      redirect e.url
   else
      error 404
   end
end

error do
   'Sorry there was a nasty error - ' + env['sinatra.error'].name
end

class Entry < Sequel::Model(:entries)
   # Generates a random hash for the url. This hash function will suck once we
   # get to around 900 million (or less...)
   def urlhash= x
      @@hash_chars = ("1".."z").reject {|val| (/\w+/ =~ val).nil? }
      r = Random.new

      begin
         idx = []
         h = ""
         (0..5).each { idx.push r.rand(0..@@hash_chars.length) }
         idx.each {|i| h << @@hash_chars[i] }
      end while !h and !Entry.find(:urlhash => h).nil?

      super h
   end

   # CALLS SAVE. You have been warned.
   def increment
      self.visits = self.visits.to_i.next
      self.save
   end

   def link
      return "/#{self.urlhash}"
   end

   def statlink
      return "/s/#{self.urlhash}"
   end

   def Entry.build url
      valid = [
         URI::HTTP,
         URI::HTTPS,
         URI::FTP
      ]

      parsed = URI::parse url

      if !valid.include? parsed.class
         return nil
      end

      f = Entry.find(:url => parsed.to_s)

      if (!f.nil?)
         return f
      else
         e = Entry.new
         e.url = parsed.to_s
         e.urlhash = parsed
         e.date = Time.now
         e.save

         return e
      end
   rescue URI::InvalidURIError
      return nil
   end
end
