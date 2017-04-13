#!/usr/bin/env ruby
#
# This code snippet shows how to enable SSL in Sinatra+Thin.
# Taken from https://developers.intercom.io/docs/setting-up-oauth

require 'sinatra'
require 'thin'
require "net/http"
require "uri"
require 'intercom'
require 'json'
require 'cgi'
require 'dotenv'
Dotenv.load

def gen_state
	(0...15).map { ('a'..'z').to_a[rand(26)] }.join
end

class MyThinBackend < ::Thin::Backends::TcpServer
  def initialize(host, port, options)
    super(host, port)
    @ssl = true
    @ssl_options = options
  end
end

configure do
  set :environment, :production
  set :bind, '0.0.0.0'
  if !ENV["PORT"].nil? && !ENV["PORT"].empty? then
    set :port, ENV["PORT"]
  end
  set :server, "thin"
  set :show_exceptions, :after_handler # show errors http://www.sinatrarb.com/intro.html#Error
  enable :sessions
  if ENV["self_ssl"].to_i == 1 then
    # Create SSL these cert files via:
    # openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout pkey.pem -out cert.crt
	  class << settings
	    def server_settings
	      {
	          :backend          => MyThinBackend,
	          :private_key_file => File.dirname(__FILE__) + "/pkey.pem",
	          :cert_chain_file  => File.dirname(__FILE__) + "/cert.crt",
	          :verify_peer      => false
	      }
	    end
	  end
  end
end

get '/' do
  session[:state] = session[:state] || gen_state
  erb :intercom_button, :locals => {:client_id => ENV["client_id"],
                                    :redirect_url => ENV["redirect_url"]}

end

get '/home' do

  # Manual request via the API

  uri = URI.parse("https://api.intercom.io/me")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri.request_uri)
  request.add_field("Accept", "application/json")
  puts request
  puts "TOKEN #{session[:token]}"
  begin
    request.basic_auth(CGI.unescape(session[:token]), "")
    response = http.request(request)
    rsp = JSON.parse(response.body)
  rescue Exception => e
    puts e.message
    puts e.backtrace.inspect
    raise 'EXCEPTION'
  end

  @name = rsp["name"]
  @type = rsp["type"]
  @email = rsp["email"]
  @id = rsp["id"]
  @app_type = rsp["app"]["type"]
  @app_code = rsp["app"]["id_code"]
  @app_create_date = rsp["app"]["created_at"]
  @app_identity_verification = rsp["app"]["identity_verification"]
  @avatar = rsp["avatar"]["image_url"]

  # Request via Intercom Ruby library
  intercom = Intercom::Client.new(token: session[:token])
  @counts = intercom.counts.for_app
  puts "Counts: #{@counts.inspect}"

  erb :greeting
end

get '/callback' do
  #Get the Code passed back to our redirect callback
  session[:code] = params[:code]
  session[:state] = params[:state]

  puts "CODE: #{session[:code]}"
  puts "STATE:#{session[:state]}"

  #We can do a Post now to get the access token
  uri = URI.parse("https://api.intercom.io/auth/eagle/token")
  response = Net::HTTP.post_form(uri, {"code" => params[:code],
                                       "client_id" => ENV["client_id"],
                                       "client_secret" => ENV["client_secret"]})

  #Break Up the response and print out the Access Token
  rsp = JSON.parse(response.body)
  session[:token] = rsp["token"]

  puts "ACCESS TOKEN: #{session[:token]}"
  redirect '/home'
end

#post '/callback' do
#  push = JSON.parse(request.body.read)
#  puts "I got some JSON: #{push.inspect}"
#end
