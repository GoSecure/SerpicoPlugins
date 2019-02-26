require './helpers/plugin_listener'

class SeverityGraphListener < PluginListener
  def notify_report_generated(report_object)
    # This should never happend since the notify method is called from safe locations, but we never know
    if !report_object
      return
    end

    plugin_xml = "<severitygraph>"
    # Todo: Generate the graph SVG and parse it as an image
    #       then, include the image into the report
    plugin_xml << "</severitygraph>"
    return plugin_xml
  end

  def notify_report_deleted(report_object)
    # This should never happend since the notify method is called from safe locations, but we never know
    if !report_object
      return
    end

    # Todo: Delete the image from disk
    return
  end
end
