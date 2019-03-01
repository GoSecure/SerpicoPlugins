require 'sinatra'
require './plugins/SeverityGraph/helpers/severitygraph_listener'

PluginNotifier.instance.attach_plugin(SeverityGraphListener.new)

get '/SeverityGraph' do
	redirect to("/") unless valid_session?

	if !params[:report_id].nil?
	  report_id = params[:report_id]
	  # Query for the first report matching the id
	  @report = get_report(report_id)

	  return 'No Such Report' if @report.nil?

		redirect to("/SeverityGraph/generate?report_id=1")
	elsif is_administrator?
		redirect to("/SeverityGraph/admin")
	else
		redirect to ("/")
	end

end

get '/SeverityGraph/admin' do
	redirect to("/") unless valid_session?
	redirect to("/") unless is_administrator?

	# Todo: Fetch the severity levels from the database
	haml :'../plugins/SeverityGraph/views/change_thresholds'
end

post '/SeverityGraph/admin' do
	redirect to("/") unless valid_session?
	redirect to("/") unless is_administrator?

end
