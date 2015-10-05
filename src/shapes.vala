using Cairo;

namespace Plot {
	private const short X = 0;
	private const short Y = 1;
	
	public abstract class Shapes : Object {
		public Gdk.RGBA color {get; set; default = Gdk.RGBA () {red = 0, green = 0, blue = 0, alpha = 0};}
		public abstract void draw (Cairo.Context cr);
		public inline bool in_vicinity (double vicinity, double x0, double y0, double x1, double y1)
		{
			return x1 > x0 - vicinity & x1 < x0 + vicinity & y1 > y0 - vicinity & y1 < y0 + vicinity;
		}
	}

	public class Axes : Shapes {
		public enum Type {
			X,
			Y
		}

		private Type type;

		public double min {get; set; default = 0;}
		public double max {get; set; default = 0;}
		public double intersection {get; set; default = 0;}
		public int major_tick {get; set; default = 3;}
		public int minor_tick {get; set; default = 0;}

		public Axes (Type type) {
			this.type = type;
			color = {0,0,0,1};
		}
		public override void draw (Context cr) {
			// Draw axes
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color);
			cr.set_line_width (1);
			if (type == Type.X) {
				cr.move_to (min, intersection);
				cr.line_to (max, intersection);
			} else {
				cr.move_to (intersection, min);
				cr.line_to (intersection, max);
			}

			// Draw ticks
			double tick_interval = (max - min) / (major_tick - 1);
			for (int i = 0; i < major_tick; i++) {
				if ((min + i * tick_interval) == intersection) continue;
				if (type == Type.X) {
					cr.move_to (min + i * tick_interval, intersection - mm);
					cr.line_to (min + i * tick_interval, intersection + mm);
				} else {
					cr.move_to (intersection - mm, min + i * tick_interval);
					cr.line_to (intersection + mm, min + i * tick_interval);
				}
			}
			cr.stroke ();
			cr.restore ();
		}
	}

	public class Background : Shapes {
		private Gdk.RGBA grid_color;

		public double width {get; set; default = 0;}
		public double height {get; set; default = 0;}
		public bool has_major_grid {get; set; default = true;}
		public bool has_minor_grid {get; set; default = true;}

		public Background () {
			color = {1,1,1,1};
			grid_color = {0.5, 0.5, 0.5, 1};
		}
		public override void draw (Context cr) {
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color);
			cr.paint ();
			cr.restore ();
		}
		public void draw_grid (Context cr) {
			if (has_major_grid) {
				cr.save ();
				Gdk.cairo_set_source_rgba (cr, grid_color);
				cr.set_line_width (0.5);
				for (int i = 0; i < width / cm + 1; i++) {
					cr.move_to (i*cm, 0);
					cr.line_to (i*cm, height);
				}
				for (int i = 0; i < height / cm + 1; i++) {
					cr.move_to (0, i*cm);
					cr.line_to (width, i*cm);
				}
				cr.stroke ();
				cr.restore ();
			}
			if (has_minor_grid) {
				cr.save ();
				Gdk.cairo_set_source_rgba (cr, grid_color);
				cr.set_line_width (0.1);
				for (int i = 0; i < width / mm + 1; i++) {
					cr.move_to (i*mm, 0);
					cr.line_to (i*mm, height);
				}
				for (int i = 0; i < height / mm + 1; i++) {
					cr.move_to (0, i*mm);
					cr.line_to (width, i*mm);
				}
				cr.stroke ();
				cr.restore ();
			}
		}
	}

	public class Curve : Shapes {
		private int radius_control_point;
		private double center[2];
		
		public bool is_selected {get; set; default = true;}
		public Gdk.RGBA selection_color {get; set; default = Gdk.RGBA () {red = 1, green = 0, blue = 0, alpha = 0.5};}
		public double[,] coords {get; set; default = {{0,0}, {0,0}, {0,0}, {0,0}};}
		public ulong motion_handler_id {get; set;}

		public Curve () {
			radius_control_point = 5;
			color = {0,0,0,1};
		}
		public void transform_cb (Gtk.Widget widget, Gdk.EventButton event) {
			double pointer[2] = {event.x - widget.margin, event.y - widget.margin};
			if (in_vicinity (radius_control_point, coords[1,X], coords[1,Y], pointer[X], pointer[Y])) {
				motion_handler_id = widget.motion_notify_event.connect ((motion_event) => {
					coords[1,X] = motion_event.x - widget.margin;
					coords[1,Y] = motion_event.y - widget.margin;
					widget.queue_draw ();
					return true;
				});
			} else if (in_vicinity (radius_control_point, coords[2,X], coords[2,Y], pointer[X], pointer[Y])) {
				motion_handler_id = widget.motion_notify_event.connect ((motion_event) => {
					coords[2,X] = motion_event.x - widget.margin;
					coords[2,Y] = motion_event.y - widget.margin;
					widget.queue_draw ();
					return true;
				});
			}
			else if (in_vicinity (radius_control_point, coords[0,X], coords[0,Y], pointer[X], pointer[Y])) {
				motion_handler_id = widget.motion_notify_event.connect ((motion_event) => {
					coords[0,X] = motion_event.x - widget.margin;
					coords[0,Y] = motion_event.y - widget.margin;
					widget.queue_draw ();
					return true;
				});
			} else if (in_vicinity (radius_control_point, coords[3,X], coords[3,Y], pointer[X], pointer[Y])) {
				motion_handler_id = widget.motion_notify_event.connect ((motion_event) => {
					coords[3,X] = motion_event.x - widget.margin;
					coords[3,Y] = motion_event.y - widget.margin;
					widget.queue_draw ();
					return true;
				});
			} else if (in_vicinity (radius_control_point, center[X], center[Y], pointer[X], pointer[Y])) {
				motion_handler_id = widget.motion_notify_event.connect ((motion_event) => {
					double motion_pointer[2] = {motion_event.x - widget.margin, motion_event.y - widget.margin};
					for (int i = 0; i < 2; i++) {
						for (int j = 0; j < 4; j++) {
							coords[j,i] += motion_pointer[i] - center[i];
						}
						center[i] = 0.5*(coords[0,i] + coords[3,i]);
					}
					widget.queue_draw ();
					return true;
				});
			}
		}
		public void remove_motion_cb (Gtk.Widget widget) {
			if (motion_handler_id != 0) {
				widget.disconnect (motion_handler_id);
				motion_handler_id = 0;
			}
		}

		public override void draw (Context cr) {
			center = {0.5*(coords[0,X] + coords[3,X]), 0.5*(coords[0,Y] + coords[3,Y])};
			if (is_selected) {
				cr.save ();
				Gdk.cairo_set_source_rgba (cr, selection_color);
				cr.set_line_width (4);
				cr.set_dash ({mm, 0.5*mm}, 0);
				cr.move_to (coords[0,X], coords[0,Y]);
				cr.curve_to (coords[1,X], coords[1,Y], coords[2,X], coords[2,Y], coords[3,X], coords[3,Y]);
				cr.stroke ();
				cr.arc (coords[0,X], coords[0,Y], radius_control_point, 0, 2*Math.PI);
				cr.stroke ();
				cr.arc (coords[3,X], coords[3,Y], radius_control_point, 0, 2*Math.PI);
				cr.stroke ();
				cr.restore ();
			}
			// Draw curve
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color);
			cr.set_line_width (2);
			cr.move_to (coords[0,X], coords[0,Y]);
			cr.curve_to (coords[1,X], coords[1,Y], coords[2,X], coords[2,Y], coords[3,X], coords[3,Y]);
			cr.stroke ();
			cr.restore ();

			if (is_selected) {
				// Draw controls
				cr.save ();
				Gdk.cairo_set_source_rgba (cr, selection_color);
				cr.set_line_width (1);
				cr.move_to (coords[0,X], coords[0,Y]);
				cr.line_to (coords[1,X], coords[1,Y]);
				cr.stroke ();
				cr.arc (coords[1,X], coords[1,Y], radius_control_point, 0, 2*Math.PI);
				cr.fill ();
				cr.arc (center[X], center[Y], radius_control_point, 0, 2*Math.PI);
				cr.fill ();
				cr.move_to (coords[3,X], coords[3,Y]);
				cr.line_to (coords[2,X], coords[2,Y]);
				cr.stroke ();
				cr.arc (coords[2,X], coords[2,Y], 5, 0, 2*Math.PI);
				cr.fill ();
				cr.restore ();

				// Draw points
				cr.save ();
				Gdk.cairo_set_source_rgba (cr, color);
				cr.arc (coords[0,X], coords[0,Y], radius_control_point, 0, 2*Math.PI);
				cr.fill ();
				cr.arc (coords[3,X], coords[3,Y], radius_control_point, 0, 2*Math.PI);
				cr.fill ();
				cr.restore ();
			}
		}
	}
}
