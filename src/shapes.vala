using Cairo;

namespace Plot {
	public struct Data {
		public double x;
		public double y;
	}

	public abstract class Shapes : Object {
		public Gdk.RGBA color {get; set; default = Gdk.RGBA () {red = 0, green = 0, blue = 0, alpha = 0};}
		public abstract void draw (Cairo.Context cr);
		public inline bool in_vicinity (double vicinity, double x0, double y0, double x1, double y1)
		{
			return x1 > x0 - vicinity & x1 < x0 + vicinity & y1 > y0 - vicinity & y1 < y0 + vicinity;
		}
	}

	public class Axes : Shapes {
	    public enum Position {
	        LEFT,
	        BOTTOM,
	        RIGHT,
	        TOP
	    }
        public struct Position {
            private Position type;
            public string caption;
            public ushort major_tick;
            public ushort minor_tick;
            public double zero_point;
            public bool visible;
        }

		public double width {get; set;}
		public double height {get; set;}
		public Position left, right, bottom, top;

		public Axes (double width, double height) {
		    this.width = width;
		    this.height = height;
			color = {0,0,0,1};
		}
		public override void draw (Context cr) {
			// Draw axes
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color);
			cr.set_line_width (1);
			cr.move_to (0, 0);
            cr.line_to (0, height);
            cr.line_to (width, height);
            cr.line_to (width, 0);
            cr.close_path ();
			// Draw ticks
			double tick_interval = width / (major_tick - 1);
			for (int i = 0; i < major_tick; i++) {
				//if ((min + i * tick_interval) == intersection) continue;
			    cr.move_to (i * tick_interval, height);
			    cr.rel_line_to (0, -mm);
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
		private Data center;
		private inline void calc_center () {center = {0.5*(points[0].x + points[3].x), 0.5*(points[0].y + points[3].y)};}

		public bool is_selected {get; set; default = true;}
		public Gdk.RGBA selection_color {get; set; default = Gdk.RGBA () {red = 1, green = 0.5, blue = 0.5, alpha = 1};}
		public Data[] points {get; set; default = new Data[4];}
		public ulong motion_handler_id {get; set;}

		public Curve () {
			radius_control_point = 5;
			color = {0,0,0,1};
		}
		public void transform_cb (Gtk.Widget widget, Gdk.EventButton event) {
			Data pointer = {event.x - widget.margin, event.y - widget.margin};
			if (in_vicinity (radius_control_point, points[1].x, points[1].y, pointer.x, pointer.y)) {
				motion_handler_id = widget.motion_notify_event.connect ((motion_event) => {
					points[1] = {motion_event.x - widget.margin, motion_event.y - widget.margin};
					widget.queue_draw ();
					return true;
				});
			} else if (in_vicinity (radius_control_point, points[2].x, points[2].y, pointer.x, pointer.y)) {
				motion_handler_id = widget.motion_notify_event.connect ((motion_event) => {
					points[2] = {motion_event.x - widget.margin, motion_event.y - widget.margin};
					widget.queue_draw ();
					return true;
				});
			}
			else if (in_vicinity (radius_control_point, points[0].x, points[0].y, pointer.x, pointer.y)) {
				motion_handler_id = widget.motion_notify_event.connect ((motion_event) => {
					points[0] = {motion_event.x - widget.margin, motion_event.y - widget.margin};
					widget.queue_draw ();
					return true;
				});
			} else if (in_vicinity (radius_control_point, points[3].x, points[3].y, pointer.x, pointer.y)) {
				motion_handler_id = widget.motion_notify_event.connect ((motion_event) => {
					points[3] = {motion_event.x - widget.margin, motion_event.y - widget.margin};
					widget.queue_draw ();
					return true;
				});
			} else if (in_vicinity (radius_control_point, center.x, center.y, pointer.x, pointer.y)) {
				motion_handler_id = widget.motion_notify_event.connect ((motion_event) => {
					Data motion_pointer = {motion_event.x - widget.margin, motion_event.y - widget.margin};
					double dx, dy;
					for (int i = 0; i < points.length; i++) {
						dx = motion_pointer.x - center.x;
						dy = motion_pointer.y - center.y;
						points[i] = {points[i].x + dx, points[i].y + dy};
					}
                    calc_center ();
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
			calc_center ();

			// Draw curve
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color);
			cr.set_line_width (2);
			cr.move_to (points[0].x, points[0].y);
			cr.curve_to (points[1].x, points[1].y, points[2].x, points[2].y, points[3].x, points[3].y);
			cr.stroke ();
			cr.restore ();

			if (is_selected) {
				// Draw curve start and end points
				cr.save ();
				Gdk.cairo_set_source_rgba (cr, color);
				cr.arc (points[0].x, points[0].y, radius_control_point, 0, 2*Math.PI);
				cr.fill ();
				cr.arc (points[3].x, points[3].y, radius_control_point, 0, 2*Math.PI);
				cr.fill ();
				cr.restore ();
			    // Draw curve selection
				cr.save ();
				Gdk.cairo_set_source_rgba (cr, selection_color);
				cr.set_line_width (2);
				cr.set_dash ({mm, 0.5*mm}, 0);
				cr.move_to (points[0].x, points[0].y);
				cr.curve_to (points[1].x, points[1].y, points[2].x, points[2].y, points[3].x, points[3].y);
				cr.stroke ();
				cr.arc (points[0].x, points[0].y, radius_control_point, 0, 2*Math.PI);
				cr.stroke ();
				cr.arc (points[3].x, points[3].y, radius_control_point, 0, 2*Math.PI);
				cr.stroke ();
				cr.restore ();
				// Draw controls
				cr.save ();
				Gdk.cairo_set_source_rgba (cr, selection_color);
				cr.set_line_width (1);
				cr.move_to (points[0].x, points[0].y);
				cr.line_to (points[1].x, points[1].y);
				cr.stroke ();
				cr.arc (points[1].x, points[1].y, radius_control_point, 0, 2*Math.PI);
				cr.fill ();
				cr.move_to (points[3].x, points[3].y);
				cr.line_to (points[2].x, points[2].y);
				cr.stroke ();
				cr.arc (points[2].x, points[2].y, 5, 0, 2*Math.PI);
				cr.fill ();
				//Draw center point
				cr.arc (center.x, center.y, radius_control_point, 0, 2*Math.PI);
				cr.fill ();
				cr.restore ();
			}
		}
	}
	public class Scatters : Shapes {
		public enum Form {
			NONE,
			SQUARE,
			CIRCLE
		}
		public Form form {get; set; default = Form.SQUARE;}
		public Array<Data?> points {get; set; default = new Array<Data?> ();}
		public int size {get; set; default = mm;}
		public Scatters () {
			color = {0,1,0,1};
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
	}
}
