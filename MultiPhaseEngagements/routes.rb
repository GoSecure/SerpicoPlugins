require 'sinatra'
require './plugins/MultiPhaseEngagements/model/phases'
require './plugins/MultiPhaseEngagements/helpers/multiphase_plugin_listener'

PluginNotifier.instance.attach_plugin(MultiphasePluginListener.new)

# Entry point, will redirect to admin if we want to manage the phases
get '/MultiPhase' do
        redirect to("/") unless valid_session?

        if request.referrer =~ /admin/ or params[:admin_view] == "true"
                redirect to("/MultiPhase/admin") if is_administrator?
        end

      	report_id = params[:report_id]
        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

        @report_id = report_id

      	DataMapper.repository(:phases) {
          @report_phases = ReportPhase.all(report_id: report_id, order: [:phase_order.asc])

          @last_sort_order = ReportPhase.max(:phase_order)

          if !@last_sort_order
            @last_sort_order = 0
          end

          @all_phases = EngagementPhase.all()
          @available_phases = EngagementPhase.all()
          if @report_phases.length > 0
            @available_phases.delete_if {|obj| @report_phases.map{|obj| obj.phase_id}.include? obj.id}
          end
        }

        haml :'../plugins/MultiPhaseEngagements/views/report_phases', :encode_html => true
end

post '/MultiPhase/add' do
        redirect to("/") unless valid_session?

        data = request.POST
      	report_id = data['report_id']
        phase_id = data['new_phase_id']

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

      	DataMapper.repository(:phases) {
          @last_sort_order = ReportPhase.max(:phase_order)

          if !@last_sort_order
            @last_sort_order = 0
          end

          @report_phases = ReportPhase.create(:report_id => report_id, :phase_id => phase_id, :phase_order => (@last_sort_order+1))
        }

        redirect to("/MultiPhase?report_id=" + report_id)
end

get '/MultiPhase/delete' do
        redirect to("/") unless valid_session?

      	report_id = params[:report_id]
        phase_id = params[:deleted_phase_id]

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

      	DataMapper.repository(:phases) {
          @report_phases = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)
          @report_phases.destroy
        }

        redirect to("/MultiPhase?report_id=" + report_id)
end

get '/MultiPhase/MoveUp' do
        redirect to("/") unless valid_session?

      	report_id = params[:report_id]
        phase_id = params[:phase_id]

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

      	DataMapper.repository(:phases) {
          @moved_up_phase = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)
          @moved_down_phase = ReportPhase.first(:report_id => report_id, :phase_order => (@moved_up_phase.phase_order - 1))

          @moved_up_phase.phase_order = @moved_up_phase.phase_order - 1
          @moved_down_phase.phase_order = @moved_down_phase.phase_order + 1

          @moved_up_phase.save
          @moved_down_phase.save
        }

        redirect to("/MultiPhase?report_id=" + report_id)
end

get '/MultiPhase/MoveDown' do
        redirect to("/") unless valid_session?

      	report_id = params[:report_id]
        phase_id = params[:phase_id]

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

      	DataMapper.repository(:phases) {
          @moved_down_phase = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)
          @moved_up_phase = ReportPhase.first(:report_id => report_id, :phase_order => (@moved_down_phase.phase_order + 1))

          @moved_down_phase.phase_order = @moved_down_phase.phase_order + 1
          @moved_up_phase.phase_order = @moved_up_phase.phase_order - 1

          @moved_down_phase.save
          @moved_up_phase.save
        }

        redirect to("/MultiPhase?report_id=" + report_id)
end

get '/MultiPhase/edit' do
        redirect to("/") unless valid_session?

      	report_id = params[:report_id]
        phase_id = params[:phase_id]

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

        @report_id = report_id
        @phase_id = phase_id

      	DataMapper.repository(:phases) {
          @phase = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)
          @all_report_phases = ReportPhase.all(:report_id => report_id)

          if @phase
            @phase_findings = ReportPhaseFinding.all(:report_phase_id => @phase.id)
            @all_report_phases = @all_report_phases - @phase
          end

          @available_phases = EngagementPhase.all()
          if @all_report_phases && @all_report_phases.length > 0
            @available_phases.delete_if {|obj| @all_report_phases.map{|obj| obj.phase_id}.include? obj.id}
          end
        }

        @appreciation_levels = ["Effective", "Adequate", "Partial", "Exposed"]

        @all_findings = Findings.all(report_id: report_id)
        @available_findings = Findings.all(report_id: report_id)
        if @phase_findings && @phase_findings.length > 0
          @available_findings.delete_if {|obj| @phase_findings.map{|obj| obj.finding_id}.include? obj.id}
        end

        haml :'../plugins/MultiPhaseEngagements/views/edit_report_phase', :encode_html => true
end

post '/MultiPhase/edit' do
        redirect to("/") unless valid_session?

        data = url_escape_hash(request.POST)
        report_id = data['report_id']
        phase_id = data['phase_id']
        timeframe = data['timeframe']
        objective = data['objective']
        scope_summary = data["scope_summary"]
        full_scope = data['full_scope']
        appreciation_level = data["appreciation_level"]
        appreciation = data["appreciation"]

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

      	DataMapper.repository(:phases) {

          @report_phase = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)

          if @report_phase
            @report_phase.update(:objective => objective, :scope_summary => scope_summary, :full_scope => full_scope, :timeframe => timeframe,
              :appreciation_level => appreciation_level, :appreciation => appreciation)
          else
            @last_sort_order = ReportPhase.max(:phase_order)

            if !@last_sort_order
              @last_sort_order = 0
            end

            @report_phase = ReportPhase.create(:report_id => report_id, :phase_id => phase_id, :objective => objective,
              :scope_summary => scope_summary, :full_scope => full_scope, :timeframe => timeframe, :appreciation_level => appreciation_level,
              :appreciation => appreciation, :phase_order => (@last_sort_order+1))
          end
        }

        redirect to("/MultiPhase?report_id=" + report_id)
end

get '/MultiPhase/findings' do
        redirect to("/") unless valid_session?

      	report_id = params[:report_id]
        phase_id = params[:phase_id]

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

        @report_id = report_id
        @phase_id = phase_id

      	DataMapper.repository(:phases) {
          @phase = EngagementPhase.first(:id => phase_id)
          @report_phase = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)
          @phase_findings = ReportPhaseFinding.all(:report_phase_id => @report_phase.id)
        }

        @all_findings = Findings.all(report_id: report_id)
        @available_findings = Findings.all(report_id: report_id)
        if @phase_findings.length > 0
          @available_findings.delete_if {|obj| @phase_findings.map{|obj| obj.finding_id}.include? obj.id}
        end

        haml :'../plugins/MultiPhaseEngagements/views/phase_findings', :encode_html => true
end

post '/MultiPhase/findings/add' do
        redirect to("/") unless valid_session?

        data = request.POST
      	report_id = data['report_id']
        phase_id = data['phase_id']
        finding_id = data['finding_id']

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

      	DataMapper.repository(:phases) {
          @report_phase = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)
          @phase_findings = ReportPhaseFinding.create(:report_phase_id => @report_phase.id, :finding_id => finding_id)
        }

        @findings = Findings.all(report_id: report_id)

        redirect to("/MultiPhase/findings?report_id=" + report_id + "&phase_id=" + phase_id)
end

get '/MultiPhase/findings/delete' do
        redirect to("/") unless valid_session?

      	report_id = params['report_id']
        phase_id = params['phase_id']
        finding_id = params['finding_id']

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

      	DataMapper.repository(:phases) {
          @report_phase = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)
          @phase_findings = ReportPhaseFinding.first(:report_phase_id => @report_phase.id, :finding_id => finding_id)
          @phase_findings.destroy
        }

        redirect to("/MultiPhase/findings?report_id=" + report_id + "&phase_id=" + phase_id)
end

# Phases administration
get '/MultiPhase/admin' do
        redirect to("/") unless valid_session?
        redirect to("/no_access") if not is_administrator?

      	DataMapper.repository(:phases) {
          @phases = EngagementPhase.all()
        }

        haml :'../plugins/MultiPhaseEngagements/views/manage_phases', :encode_html => true
end

get '/MultiPhase/admin/edit' do
        redirect to("/") unless valid_session?
        redirect to("/no_access") if not is_administrator?

        phase_id = params[:phase_id]

      	DataMapper.repository(:phases) {
          @phase = EngagementPhase.first(:id => phase_id)
        }

        haml :'../plugins/MultiPhaseEngagements/views/edit_phase', :encode_html => true
end

post '/MultiPhase/admin/edit' do
        redirect to("/") unless valid_session?
        redirect to("/no_access") if not is_administrator?

        data = url_escape_hash(request.POST)
        phase_id = data['phase_id']
        title = data['title']
        description = data['description']
        objective_template = data['objective_template']
        full_scope_template = data['full_scope_template']

        DataMapper.repository(:phases) {
          if phase_id
              @phase = EngagementPhase.first(:id => phase_id)
              @phase.update(:title => title, :description => description, :objective_template => objective_template,
                :full_scope_template => full_scope_template)
          else
              @phase = EngagementPhase.create(:title => title, :description => description, :objective_template => objective_template,
                :full_scope_template => full_scope_template)
          end
        }

        redirect to("/MultiPhase/admin")
end

get '/MultiPhase/admin/delete' do
        redirect to("/") unless valid_session?
        redirect to("/no_access") if not is_administrator?

        phase_id = params[:phase_id]

        DataMapper.repository(:phases) {
          if phase_id
              @phase = EngagementPhase.first(:id => phase_id)
              @phase.destroy
          end
        }

        redirect to("/MultiPhase/admin")
end
