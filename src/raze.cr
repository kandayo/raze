require "http"
require "json"
require "uri"
require "tempfile"
require "radix"

require "./raze/*"

module Raze
  def self.run(port = Raze.config.port)
    config = Raze.config
    config.global_handlers << Raze::StaticFileHandler.new(Raze.config.static_dir)
    config.global_handlers << Raze::ExceptionHandler::INSTANCE
    config.global_handlers << Raze::WebSocketServerHandler::INSTANCE
    config.global_handlers << Raze::ServerHandler::INSTANCE

    unless Raze.config.error_handlers.has_key?(404)
      error 404 do |ctx|
        unless ctx.response.headers.has_key?("Content-Type")
          ctx.response.content_type = "text/html"
        end
        ctx.response.status_code = 404
        "Not Found"
      end
    end

    unless Raze.config.error_handlers.has_key?(500)
      error 500 do |ctx, ex|
        unless ctx.response.headers.has_key?("Content-Type")
          ctx.response.content_type = "text/html"
        end
        ctx.response.status_code = 500
        Raze.config.env == "development" ? ex.message : "An error ocurred"
      end
    end

    server = HTTP::Server.new(config.host, config.port, config.global_handlers)
    puts "\nlistening at localhost:" + Raze.config.port.to_s
    server.listen
  end
end

# class Authenticator1 < Raze::Handler
#   def call(context, stack)
#     context.response.puts "Access Granted. (1)"
#     puts "Authenticator 1"
#     stack.call
#   end
# end

# class Authenticator2 < Raze::Handler
#   def call(context, stack)
#     context.response.puts "Access Granted. (2)"
#     puts "Authenticator 2"
#     stack.call
#   end
# end

# class Logger
#   include HTTP::Handler

#   def call(context)
#     # replace with string builder
#     puts "\n#{context.request.method} #{context.request.path}"
#     call_next(context)
#   end
# end
# # Raze.config.global_handlers << Logger.new

# # class Async < Raze::Handler
# #   def call(context, stack)
# #     context.response.puts "Async triggered"
# #     stack.call
# #     # context.response.close
# #     # spawn { stack.call }
# #   end
# # end

# # class LogHello < Raze::Handler
# #   def call(context, stack)
# #     puts "Logging Hello..."
# #     stack.call
# #   end
# # end

# # Raze.get "/user", [Authenticator1.new, Raze::Handler.new, Raze::Handler.new] do |context|
# #   # puts "end of the road"
# #   "/user"
# # end

# # auth1 = Authenticator1.new
# # auth2 = Authenticator2.new

# Raze.get "/hello", Authenticator1.new

# Raze.get "/hello/:name", Authenticator1.new
# Raze.get "/hello/sam", Authenticator2.new

# Raze.get "/hello/:name" do |context|
#   "yee, #{context.params["name"]}"
# end

# # Raze.get "/hello/world", [auth2, Raze::Handler.new] do |context|
# #   "Hello, world!"
# # end

# # Raze.get "/hello", [Authenticator1.new.as(Raze::Handler), Raze::Handler.new] do |context|
# #   "kewl"
# # end
# # Raze.all "/yee/**", LogHello.new

# Raze.get "/yee/boi" do |context|
#   "Yeezy"
# end

# Raze.get "/yeezy/boi" do |context|
#   "Yeezy"
# end

# class WebSocketAuthenticator < Raze::WebSocketHandler
#   def call(ctx, done)
#     puts "authenticating..."
#     done.call
#   end
# end

# do |sock, ctx|
#   sock.send("connected to yeezy room: #{ctx.params["room"]}")
#   Raze.ws_channel("yeezy").add sock

#   # Create a user id for this websocket connection
#   user_id = "user:#{Raze.ws_channel("yeezy").size}"

#   # Optional: This will print how many sockets are connected to each channel
#   Raze::WebSocketChannels::INSTANCE.channels.each do|chan_name, chan|
#     puts "#{chan_name} has #{chan.size} connections"
#   end
# end


# ws "/room/:room_id" do |ws, ctx|
#   room_id = ctx.params["room_id"].as(String)
#   channel_id = "room:#{room_id}"

#   ws.send("connected to room #{room_id}")

#   Raze.ws_channel(channel_id).add ws

#   # Create a user id for this websocket connection
#   user_id = "user:#{Raze.ws_channel(channel_id).size}"

#   # Optional: This will print how many sockets are connected to each channel
#   puts "\n=="
#   Raze::WebSocketChannels::INSTANCE.channels.each do |chan_name, chan|
#     puts "#{chan_name} has #{chan.size} connections"
#   end

#   ws.on_message do |msg|
#     # broadcast a json message to each websocket in the channel
#     Raze.ws_channel(channel_id).broadcast(
#       {"user_id" => user_id, "msg" => msg, "room_id" => room_id}
#     )
#   end

#   ws.on_close do
#     # remove the socket from the channel, and broadcast the user has left
#     Raze.ws_channel(channel_id).remove ws do |channel|
#       channel.broadcast(
#         {"user_id" => user_id, "msg" => "user disconnected", "room_id" => room_id}
#       )
#     end

#     # Optional: print how many sockets are connected to each channel
#     puts "\n=="
#     Raze::WebSocketChannels::INSTANCE.channels.each do |chan_name, chan|
#       puts "#{chan_name} has #{chan.size} connections"
#     end
#   end
# end

# class Authenticator < Raze::Handler
#   def call(context, done)
#     puts "Authenticate here..."
#     done.call
#   end
# end

# class DDoSBlocker < Raze::Handler
#   def call(context, done)
#     puts "Prevent DDoS attack here..."
#     done.call
#   end
# end

# class UserFetcher < Raze::Handler
#   def call(context, done)
#     # Fetch user record from DB here...
#     context.locals["user_name"] = "Sam"
#     done.call
#   end
# end

# get "/api/**", [Authenticator.new, DDoSBlocker.new]

# get "/api/user/:user_id", UserFetcher.new do |ctx|
#   "hello, #{ctx.locals["user_name"]}!"
# end
# Raze.post "/yee/boi" do |context|
#   puts "headers: #{context.request.headers}"
#   puts "raw body: #{context.request.body}"
#   puts "json body: #{context.json}"
#   puts "param body: #{context.body}"
#   puts "name: #{context.body["name"]}"
#   puts "age: #{context.body["age"]}"
#   puts "email: #{context.body["email"]}"
#   "Yeezy"
# end

# # Raze.get "/yee", Async.new, LogHello.new do |context|
# #   context.response.puts "yee boi"
# #   res = context.response.close
# #   nil
# # end

# # Raze.get "/sam", [auth1, Raze::Handler.new]

# Raze.run