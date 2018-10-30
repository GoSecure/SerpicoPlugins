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

        @all_findings_phases = Findings.all(:report_id => report_id).map(&:assessment_type)

      	DataMapper.repository(:phases) {

          @last_sort_order = ReportPhase.max(:phase_order, :conditions => ["report_id = ?", report_id])

          if !@last_sort_order
            @last_sort_order = 0
          end

          @all_findings_phases.each{ |phase|
            engagement_phase = EngagementPhase.first(:title => phase, :language => report.language)
            if engagement_phase
              report_phase = ReportPhase.first(:report_id => report_id, :phase_id => engagement_phase.id)
              if !report_phase
                ReportPhase.create(:report_id => report_id, :phase_id => engagement_phase.id, :phase_order => (@last_sort_order+1),
                  :full_scope => engagement_phase.full_scope_template, :objective => engagement_phase.objective_template)
              end
            end
          }

          @report_phases = ReportPhase.all(report_id: report_id, order: [:phase_order.asc])

          @all_phases = EngagementPhase.all(:language => report.language)
          @available_phases = EngagementPhase.all(:language => report.language)
          if @report_phases.length > 0
            @available_phases.delete_if {|obj| @report_phases.map{|obj| obj.phase_id}.include? obj.id}
          end
        }

        haml :'../plugins/MultiPhaseEngagements/views/report_phases'
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
          @last_sort_order = ReportPhase.max(:phase_order, :conditions => ["report_id = ?", report_id])

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

          @available_phases = EngagementPhase.all(:language => report.language)
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

        haml :'../plugins/MultiPhaseEngagements/views/edit_report_phase'
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
          end
        }

        redirect to("/MultiPhase?report_id=" + report_id)
end

# Phases administration
get '/MultiPhase/admin' do
        redirect to("/") unless valid_session?
        redirect to("/no_access") if not is_administrator?

      	DataMapper.repository(:phases) {
          @phases = EngagementPhase.all()
        }

        haml :'../plugins/MultiPhaseEngagements/views/manage_phases'
end

get '/MultiPhase/admin/edit' do
        redirect to("/") unless valid_session?
        redirect to("/no_access") if not is_administrator?

        phase_id = params[:phase_id]

      	DataMapper.repository(:phases) {
          @phase = EngagementPhase.first(:id => phase_id)

          # We fetch the assessments phases descriptions we have not filled out yet
          @assessment_types = settings.assessment_types.map{ |type|
            @assessment_languages = EngagementPhase.all(:title => type).map(&:language)
            remaining_languages = Config['languages'].select{ |language|
              (@phase and @phase.title == type and @phase.language == language) or !@assessment_languages.include?(language)
            }

            if remaining_languages and remaining_languages.count > 0
              {type => remaining_languages}
            end
          }.compact
        }

        haml :'../plugins/MultiPhaseEngagements/views/edit_phase'
end

post '/MultiPhase/admin/edit' do
        redirect to("/") unless valid_session?
        redirect to("/no_access") if not is_administrator?

        data = url_escape_hash(request.POST)
        phase_id = data['phase_id']
        title = data['title']
        phase_name = data['phase_name']
        language = data['language']
        description = data['description']
        objective_template = data['objective_template']
        full_scope_template = data['full_scope_template']

        DataMapper.repository(:phases) {
          if phase_id
              @phase = EngagementPhase.first(:id => phase_id)
              @phase.update(:title => title, :phase_name => phase_name, :language => language, :description => description,
                :objective_template => objective_template, :full_scope_template => full_scope_template)
          else
              @phase = EngagementPhase.create(:title => title, :phase_name => phase_name, :language => language, :description => description,
                :objective_template => objective_template, :full_scope_template => full_scope_template)
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
