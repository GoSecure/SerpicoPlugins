require './helpers/plugin_listener'
require './plugins/SeverityGraph/helpers/svg_graph_helper'

class SeverityGraphListener < PluginListener
  def notify_report_generated(report_object)
    # This should never happend since the notify method is called from safe locations, but we never know
    if !report_object
      return
    end

  	width = 250;
  	height = 250;

  	startAngle = 0

  	# End angle / nb de values
  	endAngle = (2 * Math::PI) / 3

  	radius = height/2;

  	graphSVG = "<svg width=\"#{width}\" height=\"#{height}\">"
  	graphSVG += "<g transform=\"translate(#{width/2},#{height/2})\">"

		for element in [1,2,3]
			arcD = arc(width, height, radius, startAngle, endAngle)
			centroidTransform = centroid(0, radius, startAngle, endAngle)

			graphSVG += "<g>"
			graphSVG += "<path fill=\"#000000\" stroke=\"white\" stroke-width=\"2\" d=\"#{arcD}\"></path>"
			graphSVG += "<text transform=\"translate(#{centroidTransform[0]},#{centroidTransform[1]})\">10</text>"
			graphSVG += "</g>"

			startAngle = endAngle
			# value * (End angle / nb de values)
			endAngle += 1 * ((Math::PI * 2) / 3)
		end

  	graphSVG += "</g>"
  	graphSVG += "</svg>"

  	graphSVGimg = Magick::Image.from_blob(graphSVG) {
    	  self.format = 'SVG'
    	  self.background_color = 'transparent'
    }

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
