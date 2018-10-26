require './helpers/plugin_listener'

class MultiphasePluginListener < PluginListener
  def notify_report_generated(report_object)
    # This should never happend since the notify method is called from safe locations, but we never know
    if !report_object
      return ''
    end

    multiphase_output = "<plugin_multiphase>"
    DataMapper.repository(:phases) {
      @report_phases = ReportPhase.all(report_id: report_object.id, order: [:phase_order.asc])

      @report_phases.each do |phase|
        @phase_info = EngagementPhase.first(:id => phase.phase_id)
        @phase_findings = ReportPhaseFinding.all(:report_phase_id => phase.id)

        phase_xml = Nokogiri::XML(phase.to_xml)
        report_phase_xml = phase_xml.at_css("report_phase")

        title = Nokogiri::XML::Node.new("title", report_phase_xml)
        title.content = @phase_info.title
        report_phase_xml << title

        description = Nokogiri::XML::Node.new("description", report_phase_xml)
        description.content = @phase_info.description
        report_phase_xml << description

        findings = "<findings_list>"
        @phase_findings.each do |finding|
          new_finding = "<finding>"
          new_finding = new_finding + "<id>" + finding.finding_id.to_s + "</id>"
          new_finding = new_finding + "</finding>"

          findings = findings + new_finding
        end
        findings = findings + "</findings_list>"

        report_phase_xml.last_element_child.after(findings)

        multiphase_output = multiphase_output + meta_markup_unencode(report_phase_xml.to_xml, report_object)
      end
    }

    multiphase_output << "</plugin_multiphase>"

    return multiphase_output
  end

  def notify_report_deleted(report_object)
    # This should never happend since the notify method is called from safe locations, but we never know
    if !report_object
      return
    end

    DataMapper.repository(:phases) {
      @report_phase = ReportPhase.first(:report_id => report_object.id)
      @phase_findings = ReportPhaseFinding.all(:report_phase_id => @report_phase.id)
      @phase_findings.destroy
      @report_phase.destroy
    }
    return
  end
end
