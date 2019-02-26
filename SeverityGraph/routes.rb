require 'sinatra'
require './plugins/SeverityGraph/helpers/severitygraph_listener'

PluginNotifier.instance.attach_plugin(SeverityGraphListener.new)

# List current reports
get '/SeverityGraph/admin' do
	# Todo: Fetch the severity levels from the database
	haml :'../plugins/SeverityGraph/views/change_thresholds'
end

post '/SeverityGraph/admin' do
	# Todo: Save the new severity levels into the database
end
