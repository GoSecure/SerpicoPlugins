# This is a super simplified version of the svg arc function of the d3.js library.
# All the credit for the awesome code goes to them
def arc(totalWidth, totalHeight, radius, startAngle, endAngle)
	innerWidth = 60;

	innerRadius = radius - innerWidth;
	outerRadius = radius;

	a0 = startAngle - (Math::PI / 2);
	a1 = endAngle - (Math::PI / 2);
	cw = a0 > a1 ? 0 : 1;

	x0 = outerRadius * Math.cos(a0);
	y0 = outerRadius * Math.sin(a0);
	x1 = outerRadius * Math.cos(a1);
	y1 = outerRadius * Math.sin(a1);
	l1 = (a1 - a0).abs <= Math::PI ? 0 : 1;

	x2 = innerRadius * Math.cos(a1);
	y2 = innerRadius * Math.sin(a1);
	x3 = innerRadius * Math.cos(a0);
	y3 = innerRadius * Math.sin(a0);
	l0 = (a0 - a1).abs <= Math::PI ? 0 : 1;

	return "M#{x0},#{y0}A#{outerRadius},#{outerRadius} 0 #{l1},#{cw} #{x1},#{y1}L#{x2},#{y2}A#{innerRadius},#{innerRadius} 0 #{l0},#{1 - cw} #{x3},#{y3}Z";
end

def centroid(innerRadius, outerRadius, startAngle, endAngle)
		radius = (innerRadius + outerRadius) / 2
		angle = (startAngle + endAngle) / 2 - (Math::PI / 2)
		return [ Math.cos(angle) * radius, Math.sin(angle) * radius ]
end
