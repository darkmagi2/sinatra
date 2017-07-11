$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/")
require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra' 
require 'mysql2'
require 'cfg/db.rb'

#Define MYSQL Client variable
@@client = Mysql2::Client.new(:host => @config["db_host"], :username => @config["db_user"], :password => @config["db_pass"], :database => 'shotcount')

#Haproxy makes this irrelevant
get '/' do
  erb :index 
end

#Generate 404 errors
not_found do
	status 404
	'not found'
end

#Begin Shotcount routes
get '/shots' do
	erb :entername
end
post '/shots' do
	erb :shots, :locals => {:name => params[:ename]}
end
get '/shots/:name' do
	erb :shots, :locals => {:name => params[:name].capitalize!}
end
post '/shots/:name' do
	#Special characters to pull out using regex
	regex = /@|;|\)|\(|\$|&|"|'/
	#Convert entered name into name minus special characters
	realname = params[:name].downcase.gsub(regex,'') 
	#Check if name exists in database
	exists = @@client.query("SELECT * FROM people WHERE name='#{realname}'")
	#If name doesn't exists, insert into database with shot count of 0
	if exists.count == 0
		@@client.query("INSERT INTO  people (name, shots) VALUES ('#{realname}', 0)")
	end
	#Increment shotcount of entered name
	@@client.query("UPDATE people SET shots=shots+1 WHERE name='#{realname}'")
	#Query database for name/shotcount of entered name and output results
	results = @@client.query("SELECT * FROM people WHERE name='#{realname}'")
	"#{results.first["name"].capitalize} has #{results.first["shots"]} shots owed." 
end


