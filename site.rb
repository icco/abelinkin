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
[ "sinatra", "less", "sequel", "dalli", "uri" ].each {|gem|
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

class Integer
   def to_hashed
      val = self.to_i

      Integer.hashmath val
   end

   def Integer.hashmath x
      @@hashes = ("0".."z").reject {|val| (/\w+/ =~ val).nil? }
      if x == 0
         return ""
      else
         return Integer.hashmath(x%63) + @@hashes[x]
      end
   end
end


class Entry < Sequel::Model(:entries)
   def urlhash= x
      h = x.hash
      h36 = h.to_s 36

      while !Entry.find(:urlhash => h36).nil? do
         h = n.next
         h36 = h.to_s 36
      end

      super h36
   end

   # CALLS SAVE.
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
