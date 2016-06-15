using GLib;
using Cairo;

public class Gplot.Line : Gplot.Shape
{
	protected override void draw(Context cr)
	{
		cr.set_source_rgb(0, 0, 0);
		cr.set_line_width(2);
		cr.move_to(this._x.getValue(0), this._y.getValue(0));
		cr.line_to(this._x.getValue(1), this._y.getValue(1));
		cr.stroke();
	}
}
