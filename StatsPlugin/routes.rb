require 'sinatra'

get '/TestPlugin' do
	haml :'../plugins/StatsPlugin/views/stats'
end
