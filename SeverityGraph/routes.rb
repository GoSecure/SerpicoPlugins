require 'sinatra'
require './plugins/SeverityGraph/helpers/severitygraph_listener'

PluginNotifier.instance.attach_plugin(SeverityGraphListener.new)

# List current reports
get '/SeverityGraph/admin' do
	
	haml :'../plugins/SeverityGraph/views/change_thresholds'
end

post '/SeverityGraph/admin' do

end
