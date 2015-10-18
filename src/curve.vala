using GLib;
using Cairo;
using Plot;

public class Plot.Curve : Plot.Shapes {
	private int radius_control_point {get; set; default = mm / 2;}

	public Gdk.RGBA color_curve {get; set;}
	public Gdk.RGBA color_selection {get; set;}

	public Curve (int parent_id, int id) {
		this.id = id;
		group_name = @"Curve:$parent_id:$id";
		color_curve = {0,0,0,1};
		color_selection = {1, 0.5, 0.5, 1};
		points.append_val (Point () {x = 0*cm, y = 0*cm});
		points.append_val (Point () {x = 0*cm, y = 4*cm});
		points.append_val (Point () {x = 3*cm, y = 0*cm});
		points.append_val (Point () {x = 3*cm, y = 4*cm});
	}
	public Curve.from_file (GLib.KeyFile file, int parent_id, int id) {
		group_name = @"Curve:$parent_id:$id";
		try {
			// From Shapes
			is_selected = file.get_boolean (group_name, "is_selected");
			var points_list = file.get_string_list (group_name, "points");
			for (int i = 0; i < points_list.length; i++) {
				points.append_val (Point.from_string (points_list[i]));
			}
			scale = Point.from_string (file.get_string (group_name, "scale"));
			shift = Point.from_string (file.get_string (group_name, "shift"));
			// From Curve
			_color_curve.parse (file.get_string (group_name, "color_curve"));
			_color_selection.parse (file.get_string (group_name, "color_selection"));
		} catch (KeyFileError err) {
			print (@"$group_name: $(err.message)\n");
		}
	}
	public override void save_to_file (GLib.KeyFile file) {
		// From Shapes
		file.set_boolean (group_name, "is_selected", is_selected);
		string[] points_list = new string[points.length];
		for (int i = 0; i < points.length; i++) {
			points_list[i] = points.index(i).to_string ();
		}
		file.set_string_list (group_name, "points", points_list);
		file.set_string (group_name, "scale", scale.to_string ());
		file.set_string (group_name, "shift", shift.to_string ());
		// From Curve
		file.set_string (group_name, "color_curve", color_curve.to_string ());
		file.set_string (group_name, "color_selection", color_selection.to_string ());
	}
	public override void draw (Cairo.Context cr) {
		// Draw curve
		cr.save ();
		Gdk.cairo_set_source_rgba (cr, color_curve);
		cr.set_line_width (2);
		cr.move_to (points.index (0).x, points.index (0).y);
		cr.rel_curve_to (points.index (1).x, points.index (1).y, points.index (2).x, points.index (2).y, points.index (3).x, points.index (3).y);
		cr.stroke ();
		cr.restore ();

		if (is_selected) {
			// Draw curve start and end points
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color_curve);
			cr.arc (points.index (0).x, points.index (0).y, radius_control_point, 0, 2*Math.PI);
			cr.fill ();
			cr.arc (points.index (0).x + points.index (3).x, points.index (0).y + points.index (3).y, radius_control_point, 0, 2*Math.PI);
			cr.fill ();
			cr.restore ();
			// Draw curve selection
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color_selection);
			cr.set_line_width (2);
			cr.set_dash ({mm, 0.5*mm}, 0);
			cr.move_to (points.index (0).x, points.index (0).y);
			cr.rel_curve_to (points.index (1).x, points.index (1).y, points.index (2).x, points.index (2).y, points.index (3).x, points.index (3).y);
			cr.stroke ();
			cr.arc (points.index (0).x, points.index (0).y, radius_control_point, 0, 2*Math.PI);
			cr.stroke ();
			cr.arc (points.index (0).x + points.index (3).x, points.index (0).y + points.index (3).y, 0.5*radius_control_point, 0, 2*Math.PI);
			cr.fill ();
			cr.restore ();
			// Draw controls
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color_selection);
			cr.set_line_width (1);
			cr.move_to (points.index (0).x, points.index (0).y);
			cr.rel_line_to (points.index (1).x, points.index (1).y);
			cr.stroke ();
			cr.arc (points.index (0).x + points.index (1).x, points.index (0).y + points.index (1).y, radius_control_point, 0, 2*Math.PI);
			cr.fill ();
			cr.move_to (points.index (0).x + points.index (3).x, points.index (0).y + points.index (3).y);
			cr.line_to (points.index (0).x + points.index (2).x, points.index (0).y + points.index (2).y);
			cr.stroke ();
			cr.arc (points.index (0).x + points.index (2).x, points.index (0).y + points.index (2).y, 5, 0, 2*Math.PI);
			cr.fill ();
		}
	}
	public override void transform (Gtk.Widget widget, Gdk.EventButton event) {
		double x, y; // For position
		Point rel = {0, 0}; // For motion
		for (int i = 0; i < points.length; i++) {
			x = points.index (i).x;
			y = points.index (i).y;
			if (i != 0) {
				x += points.index (0).x;
				y += points.index (0).y;
				rel.x = points.index (0).x;
				rel.y = points.index (0).y;
			}
			if (x + radius_control_point > event.x && event.x > x - radius_control_point &&
				y + radius_control_point > event.y && event.y > y - radius_control_point) {
				motion_handler_id = widget.motion_notify_event.connect ((motion_event) => {
					points.index (i).x = motion_event.x - rel.x;
					points.index (i).y = motion_event.y - rel.y;
					widget.queue_draw ();
					return true;
				});
				break;
			}
		}
	}
	public override void recalculate_points (Point shift, Point scale) {
		// Because of relative curve
		points.index (0).x -= this.shift.x;
		points.index (0).y -= this.shift.y;
		for (int i = 0; i < points.length; i++) {
			// Restore data points
			points.index (i).x /= this.scale.x;
			points.index (i).y /= this.scale.y;
			// Transform data
			points.index (i).x *= scale.x;
			points.index (i).y *= scale.y;
		}
		points.index (0).x += shift.x;
		points.index (0).y += shift.y;
		// Save new transformation parameters
		this.shift = shift;
		this.scale = scale;
	}
}
