require 'sinatra'
require 'sinatra-websocket'

# set :bind, '0.0.0.0'
set :server, 'thin'
set :admin_sockets, []
set :student_sockets, []

get '/' do
  erb :index
end

post '/' do
  message = "question:#{params[:question]}"
  send_message(settings.admin_sockets, message)
  redirect '/'
end

get '/student-socket' do
  request.websocket do |ws|
    ws.onopen do
      settings.student_sockets << ws
    end

    ws.onmessage do |msg|
      send_message(settings.admin_sockets, msg)
    end

    ws.onclose do
      warn("websocket closed")
      settings.student_sockets.delete(ws)
    end
  end
end

get '/admin' do
  erb :admin
end

get '/admin-socket' do
  request.websocket do |ws|

    ws.onopen do
      settings.admin_sockets << ws
    end

    ws.onmessage do |msg|
      send_message(settings.student_sockets, msg)
    end

    ws.onclose do
      warn("websocket closed")
      settings.admin_sockets.delete(ws)
    end

  end
end

def send_message(sockets, msg)
  EM.next_tick { sockets.each{|s| s.send(msg) } }
end