using GLib;
using Cairo;

namespace Plot {
	public struct Point {
		public double x;
		public double y;
		public string to_string () {
			return x.to_string () + ";" + y.to_string ();
		}
		public Point.from_string (string str) {
			var array = str.split (";");
			x = double.parse (array[0]);
			y = double.parse (array[1]);
		}
	}

	public abstract class Shapes : Object {
		public int id {get; protected set;}
		public string group_name {get; protected set;}
		public abstract Gdk.RGBA color {get; set;}

		public abstract void draw (Cairo.Context cr, Point zero_point);
		public abstract void save_to_file (KeyFile file);
	}

	public class Axes : Shapes {
		public enum Orientation {
			LEFT,
			RIGHT,
			BOTTOM,
			TOP
		}
		public enum TickType {
			NONE,
			IN,
			OUT,
			BOTH
		}
		public override Gdk.RGBA color {get; set;}
		// Axes parameters
		public Orientation orientation {get; private set;}
		public double length {get; set;}
		public bool visible {get; set; default = true;}
		public Point position {get; set;}
		public double zero_point {get; set;}
		public string caption {get; set; default = "";}
		// Ticks parameters
		public TickType tick_type {get; set; default = TickType.IN;}
		public int major_tick {get; set; default = 2;}
		public double major_tick_size {get; set; default = mm;}
		public int minor_tick {get; set; default = 0;}
		public double minor_tick_size {get; set; default = 0.5*mm;}

		public Axes (Orientation orientation) {
			this.id = (int) orientation;
			group_name = "Axes:" + id.to_string ();
			this.orientation = orientation;
			position = {0, 0};
			color = {0,0,0,1.0};
		}
		public Axes.from_file (KeyFile file, int id) {
			group_name = "Axes:" + id.to_string ();
			try {
				orientation = (Orientation) id;
				_color.parse (file.get_string (group_name, "color"));
				visible = file.get_boolean (group_name, "visible");
				// Axes parameters
				length = file.get_double (group_name, "length");
				position = Point.from_string (file.get_string (group_name, "position"));
				zero_point = file.get_double (group_name, "zero_point");
				caption = file.get_string (group_name, "caption");
				// Ticks parameters
				tick_type = (TickType) file.get_integer (group_name, "tick_type");
				major_tick = file.get_integer (group_name, "major_tick");
				major_tick_size = file.get_double (group_name, "major_tick_size");
				minor_tick = file.get_integer (group_name, "minor_tick");
				minor_tick_size = file.get_double (group_name, "minor_tick_size");
			} catch (KeyFileError err) {
				stdout.printf ("Axes: %s\n", err.message);
			}
		}
		public override void draw (Cairo.Context cr, Point zero_point) {
			Point position = {this.position.x + zero_point.x, this.position.y + zero_point.y};
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color);
			cr.set_line_width (1);
			// Draw ticks
			double tick_amount = major_tick + minor_tick * (major_tick - 1);
			double tick_interval = length / (tick_amount - 1);
			double tick_size = major_tick_size;
			for (var i = 0; i < tick_amount; i++) {
				if (i % (1 + minor_tick) == 0) {
					tick_size = major_tick_size;
				} else {
					tick_size = minor_tick_size;
				}
				switch (orientation) {
					case Orientation.LEFT:
						cr.move_to (position.x, position.y + i * tick_interval);
						switch (tick_type) {
							case TickType.IN:
								cr.rel_line_to (tick_size, 0);
								break;
							case TickType.OUT:
								cr.rel_line_to (-tick_size, 0);
								break;
							case TickType.BOTH:
								cr.move_to (position.x - tick_size, position.y + i * tick_interval);
								cr.rel_line_to (2*tick_size, 0);
								break;
							case TickType.NONE:
								break;
						}
						break;
					case Orientation.RIGHT:
						cr.move_to (position.x, position.y + i * tick_interval);
						switch (tick_type) {
							case TickType.IN:
								cr.rel_line_to (-tick_size, 0);
								break;
							case TickType.OUT:
								cr.rel_line_to (tick_size, 0);
								break;
							case TickType.BOTH:
								cr.move_to (position.x - tick_size, position.y + i * tick_interval);
								cr.rel_line_to (2*tick_size, 0);
								break;
							case TickType.NONE:
								break;
						}
						break;
					case Orientation.BOTTOM:
						cr.move_to (position.x + i * tick_interval, position.y);
						switch (tick_type) {
							case TickType.IN:
								cr.rel_line_to (0, tick_size);
								break;
							case TickType.OUT:
								cr.rel_line_to (0, -tick_size);
								break;
							case TickType.BOTH:
								cr.move_to (position.x + i * tick_interval, position.y - tick_size);
								cr.rel_line_to (0, 2*tick_size);
								break;
							case TickType.NONE:
								break;
						}
						break;
					case Orientation.TOP:
						cr.move_to (position.x + i * tick_interval, position.y);
						switch (tick_type) {
							case TickType.IN:
								cr.rel_line_to (0, -tick_size);
								break;
							case TickType.OUT:
								cr.rel_line_to (0, tick_size);
								break;
							case TickType.BOTH:
								cr.move_to (position.x + i * tick_interval, position.y - tick_size);
								cr.rel_line_to (0, 2*tick_size);
								break;
							case TickType.NONE:
								break;
						}
						break;
				}
			}
			// Draw axes
			cr.move_to (position.x, position.y);
			switch (orientation) {
				case Orientation.LEFT:
				case Orientation.RIGHT:
					cr.rel_line_to (0, length);
					break;
				case Orientation.BOTTOM:
				case Orientation.TOP:
					cr.rel_line_to (length, 0);
					break;
			}
			cr.stroke ();
			cr.restore ();
		}
		public override void save_to_file (KeyFile file) {
			file.set_string (group_name, "color", color.to_string ());
			file.set_boolean (group_name, "visible", visible);
			// Axes parameters
			file.set_double (group_name, "length", length);
			file.set_string (group_name, "position", position.to_string ());
			file.set_double (group_name, "zero_point", zero_point);
			file.set_string (group_name, "caption", caption);
			// Ticks parameters
			file.set_integer (group_name, "tick_type", ((int) tick_type));
			file.set_integer (group_name, "major_tick", major_tick);
			file.set_double (group_name, "major_tick_size", major_tick_size);
			file.set_integer (group_name, "minor_tick", minor_tick);
			file.set_double (group_name, "minor_tick_size", minor_tick_size);
		}
	}

	/*public class Curve : Shapes {
		private int radius_control_point {get; set; default = 5;}
		private Point center;
		private ulong motion_handler_id;
		private inline void calc_center () {center = {0.5*(points[0].x + points[3].x), 0.5*(points[0].y + points[3].y)};}

		public override Gdk.RGBA color {get; set;}
		public bool is_selected {get; set; default = true;}
		public Gdk.RGBA selection_color {get; set; default = Gdk.RGBA () {red = 1, green = 0.5, blue = 0.5, alpha = 1};}
		public Point[] points {get; private set;}

		public Curve (int id) {
			this.id = id;
			group_name = "Curve:" + id.to_string ();
			color = {0,0,0,1};
		}
		public Curve.from_file (KeyFile file, int id) {
			group_name = "Curve:" + id.to_string ();
			try {
				_color.parse (file.get_string (group_name, "color"));
				is_selected = file.get_boolean (group_name, "is_selected");
				_selection_color.parse (file.get_string (group_name, "selection_color"));
				var points_list = file.get_string_list (group_name, "points");
				points = new Point[4];
				for (int i = 0; i < points_list.length; i++) {
					points[i] = Point.from_string (points_list[i]);
				}
			} catch (KeyFileError err) {
				stdout.printf ("Background: %s\n", err.message);
			}
		}
		public void transform_cb (Gtk.Widget widget, Gdk.EventButton event, Cairo.Context cr) {
			Point pointer = {event.x, event.y};
			cr.device_to_user (ref pointer.x, ref pointer.y);
			double x, y; // For position
			Point rel = {0, 0}; // For motion
			for (int i = 0; i < points.length; i++) {
				x = points[i].x;
				y = points[i].y;
				if (i != 0) {
					x += points[0].x;
					y += points[0].y;
					rel.x = points[0].x;
					rel.y = points[0].y;
				}
				if (x + radius_control_point > pointer.x & x - radius_control_point < pointer.x &
					y + radius_control_point > pointer.y & y - radius_control_point < pointer.y) {
					Point motion_pointer = {0, 0};
					motion_handler_id = widget.motion_notify_event.connect ((motion_event) => {
						motion_pointer = {motion_event.x, motion_event.y};
						cr.device_to_user (ref motion_pointer.x, ref motion_pointer.y);
						points[i] = {motion_pointer.x - rel.x, motion_pointer.y - rel.y};
						widget.queue_draw ();
						return true;
					});
					break;
				}
			}
		}
		public void remove_motion_cb (Gtk.Widget widget) {
			if (motion_handler_id != 0) {
				widget.disconnect (motion_handler_id);
				motion_handler_id = 0;
			}
		}

		public override void draw (Context cr) {
			calc_center ();

			// Draw curve
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color);
			cr.set_line_width (2);
			cr.move_to (points[0].x, points[0].y);
			cr.rel_curve_to (points[1].x, points[1].y, points[2].x, points[2].y, points[3].x, points[3].y);
			cr.stroke ();
			cr.restore ();

			if (is_selected) {
				// Draw curve start and end points
				cr.save ();
				Gdk.cairo_set_source_rgba (cr, color);
				cr.arc (points[0].x, points[0].y, radius_control_point, 0, 2*Math.PI);
				cr.fill ();
				cr.arc (points[0].x + points[3].x, points[0].y + points[3].y, radius_control_point, 0, 2*Math.PI);
				cr.fill ();
				cr.restore ();
				// Draw curve selection
				cr.save ();
				Gdk.cairo_set_source_rgba (cr, selection_color);
				cr.set_line_width (2);
				cr.set_dash ({mm, 0.5*mm}, 0);
				cr.move_to (points[0].x, points[0].y);
				cr.rel_curve_to (points[1].x, points[1].y, points[2].x, points[2].y, points[3].x, points[3].y);
				cr.stroke ();
				cr.arc (points[0].x, points[0].y, radius_control_point, 0, 2*Math.PI);
				cr.stroke ();
				cr.arc (points[0].x + points[3].x, points[0].y + points[3].y, 0.5*radius_control_point, 0, 2*Math.PI);
				cr.fill ();
				cr.restore ();
				// Draw controls
				cr.save ();
				Gdk.cairo_set_source_rgba (cr, selection_color);
				cr.set_line_width (1);
				cr.move_to (points[0].x, points[0].y);
				cr.rel_line_to (points[1].x, points[1].y);
				cr.stroke ();
				cr.arc (points[0].x + points[1].x, points[0].y + points[1].y, radius_control_point, 0, 2*Math.PI);
				cr.fill ();
				cr.move_to (points[0].x + points[3].x, points[0].y + points[3].y);
				cr.line_to (points[0].x + points[2].x, points[0].y + points[2].y);
				cr.stroke ();
				cr.arc (points[0].x + points[2].x, points[0].y + points[2].y, 5, 0, 2*Math.PI);
				cr.fill ();
			}
		}
		public override void save_to_file (KeyFile file) {
			string points_list[4];
			for (int i = 0; i < points.length; i++) {
				points_list[i] = points[i].to_string ();
			}
			file.set_string (group_name, "color", color.to_string ());
			file.set_boolean (group_name, "is_selected", is_selected);
			file.set_string (group_name, "selection_color", selection_color.to_string ());
			file.set_string_list (group_name, "points", points_list);
		}
	}
	public class Scatters : Shapes {
		public enum Form {
			NONE,
			SQUARE,
			CIRCLE
		}

		public override Gdk.RGBA color {get; set;}
		public Form form {get; set; default = Form.SQUARE;}
		public double size {get; set; default = mm;}
		public Array<Point?> points {get; set; default = new Array<Point?> ();}

		public Scatters (int id) {
			this.id = id;
			group_name = "Scatters:" + id.to_string ();
			color = {0,1,0,1};
		}
		public Scatters.from_file (KeyFile file, int id) {
			group_name = "Scatters:" + id.to_string ();
			try {
				form = (Form) file.get_integer (group_name, "form");
				_color.parse (file.get_string (group_name, "color"));
				size = file.get_double (group_name, "size");
				var points_list = file.get_string_list (group_name, "points");
				foreach (unowned string point in points_list) {
					points.append_val (Point.from_string (point));
				}
			} catch (KeyFileError err) {
				stdout.printf ("Scatters: %s\n", err.message);
			}
		}
		public override void draw (Context cr) {
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color);
			switch (form) {
				case Form.SQUARE:
					for (int i = 0; i < points.length; i++) {
						cr.move_to (points.index(i).x - 0.5*size, points.index(i).y - 0.5*size);
						cr.rel_line_to (size, 0);
						cr.rel_line_to (0, size);
						cr.rel_line_to (-size, 0);
						cr.close_path ();
					}
					break;
			}
			cr.fill ();
			cr.restore ();
		}
		public override void save_to_file (KeyFile file) {
			string[] points_list = new string[points.length];
			for (int i = 0; i < points.length; i++) {
				points_list[i] = points.index(i).to_string ();
			}
			file.set_integer (group_name, "form", (int) form);
			file.set_string (group_name, "color", color.to_string ());
			file.set_double (group_name, "size", size);
			file.set_string_list (group_name, "points", points_list);
		}
	}*/
}
