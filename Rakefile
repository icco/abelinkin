# It's a RakeFile!

# Import in official clean and clobber tasks
require 'rake/clean'
CLEAN.include("data.db")

desc "Create local db."
task :db do
   require "sequel"

   DB = Sequel.connect(ENV['DATABASE_URL'] || "sqlite://data.db")
   DB.create_table! :entries do
      primary_key :entryid
      String   :url,    :default => ""
      String   :hash,   :default => ""
      Integer  :visits, :default => 0
      DateTime :date
   end 

   puts "Database built."
end
