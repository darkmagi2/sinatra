$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/")
require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra' 
require 'mysql2'
require '/var/data/cfg/db.rb'
require 'rack/throttle'
require 'shotgun'

#use Rack::Throttle::Daily,    :max => 1000  # requests
#use Rack::Throttle::Hourly,   :max => 100   # requests
#use Rack::Throttle::Minute,   :max => 120    # requests
#use Rack::Throttle::Second,   :max => 2     # requests
#use Rack::Throttle::Interval, :min => 0.5   # seconds

#Experimental authentication
use Rack::Session::Pool

helpers do
  def logged? ; session["isLogdIn"] == true; end
#  def protected! ; halt 401 unless logged? ; end
  def protected!
    unless logged?
      throw(:halt, [401, "Oops... we need your login"])
    end
  end
end

get "/login/?" do
  erb :login
end

post '/login/?' do
  if params['password'] == "password"
    session["isLogdIn"] = true
    redirect '/testlock'
  else
    halt 401
  end
end

get('/logout/?'){ session["isLogdIn"] = false ; redirect '/login' }

get '/testlock' do
  protected!
  erb :locked
end

#Define MYSQL Client variable
$client = Mysql2::Client.new(:host => @config["db_host"], :username => @config["db_user"], :password => @config["db_pass"], :database => 'shotcount')

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

#Index (enter name for tracking)

get '/shots' do
	@names = $client.query("SELECT * FROM people").map{|result| [ result["name"], result["shots"] ] }
	erb :shottable
end
get '/add' do
	erb :entername
end

#Post
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
	exists = $client.query("SELECT * FROM people WHERE name='#{realname}'")
	#If name doesn't exists, insert into database with shot count of 0
	if exists.count == 0
		$client.query("INSERT INTO  people (name, shots) VALUES ('#{realname}', 0)")
	end
	#Increment shotcount of entered name
	$client.query("UPDATE people SET shots=shots+1 WHERE name='#{realname}'")
	#Query database for name/shotcount of entered name and output results
	results = $client.query("SELECT * FROM people WHERE name='#{realname}'")
	"#{results.first["name"].capitalize} has #{results.first["shots"]} shots owed." 
end


