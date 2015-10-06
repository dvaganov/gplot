using Cairo;

namespace Plot {
	public struct Point {
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
		public enum Orientation {
			LEFT,
			BOTTOM,
			RIGHT,
			TOP
		}
		public enum TickType {
			NONE,
			IN,
			OUT,
			BOTH
		}
		// Axes parameters
		public Orientation orientation {get; private set;}
		public double length {get; private set;}
		public bool visible {get; set; default = true;}
		public double position {get; set; default = 0;}
		public double zero_point {get; set;}
		public string caption {get; set;}
		// Ticks parameters
		public TickType tick_type {get; set; default = TickType.IN;}
		public ushort major_tick {get; set; default = 2;}
		public double major_tick_size {get; set; default = mm;}
		public ushort minor_tick {get; set; default = 0;}
		public double minor_tick_size {get; set; default = 0.5*mm;}

		public Axes (double length, Orientation orientation) {
			this.length = length;
			this.orientation = orientation;
			color = {0,0,0,1.0};
		}
		public override void draw (Context cr) {
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color);
			cr.set_line_width (1);
			// Draw ticks
			draw_ticks (cr, minor_tick, minor_tick_size, length / (major_tick - 1));
			//draw_ticks (cr, major_tick, major_tick_size, length);
			// Draw axes
			switch (orientation) {
				case Orientation.BOTTOM:
				case Orientation.TOP:
					cr.move_to (0, position);
					cr.rel_line_to (length, 0);
					break;
				case Orientation.LEFT:
				case Orientation.RIGHT:
					cr.move_to (position, 0);
					cr.rel_line_to (0, length);
					break;
			}
			cr.stroke ();
			cr.restore ();
		}
		private void draw_ticks (Cairo.Context cr, double ticks, double tick_size_old, double interval) {
			double tick_size = major_tick_size;
			double tick_amount = major_tick + minor_tick * (major_tick - 1);
			double tick_interval = length / (tick_amount - 1);
			for (var i = 0; i < tick_amount; i++) {
				if (i % (1 + minor_tick) == 0) {
					tick_size = major_tick_size;
				} else {
					tick_size = minor_tick_size;
				}
				switch (tick_type) {
				case TickType.NONE:
					break;
				case TickType.IN:
					switch (orientation) {
						case Orientation.BOTTOM:
							cr.move_to (i * tick_interval, position);
							cr.rel_line_to (0, -tick_size);
							break;
						case Orientation.TOP:
							cr.move_to (i * tick_interval, position);
							cr.rel_line_to (0, tick_size);
							break;
						case Orientation.LEFT:
							cr.move_to (position, i * tick_interval);
							cr.rel_line_to (tick_size, 0);
							break;
						case Orientation.RIGHT:
							cr.move_to (position, i * tick_interval);
							cr.rel_line_to (-tick_size, 0);
							break;
					}
					break;
				case TickType.OUT:
					switch (orientation) {
						case Orientation.BOTTOM:
							cr.move_to (i * tick_interval, position);
							cr.rel_line_to (0, tick_size);
							break;
						case Orientation.TOP:
							cr.move_to (i * tick_interval, position);
							cr.rel_line_to (0, -tick_size);
							break;
						case Orientation.LEFT:
							cr.move_to (position, i * tick_interval);
							cr.rel_line_to (-tick_size, 0);
							break;
						case Orientation.RIGHT:
							cr.move_to (position, i * tick_interval);
							cr.rel_line_to (tick_size, 0);
							break;
					}
					break;
					case TickType.BOTH:
					switch (orientation) {
						case Orientation.BOTTOM:
						case Orientation.TOP:
							cr.move_to (i * tick_interval, position - tick_size);
							cr.rel_line_to (0, 2*tick_size);
							break;
						case Orientation.LEFT:
						case Orientation.RIGHT:
							cr.move_to (position, i * tick_interval - tick_size);
							cr.rel_line_to (2*tick_size, 0);
							break;
					}
					break;
				}
			}
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
			grid_color = {0.5, 0.5, 0.5, 0.5};
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
				cr.set_line_width (1);
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
				cr.set_line_width (0.5);
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
		private Point center;
		private inline void calc_center () {center = {0.5*(points[0].x + points[3].x), 0.5*(points[0].y + points[3].y)};}

		public bool is_selected {get; set; default = true;}
		public Gdk.RGBA selection_color {get; set; default = Gdk.RGBA () {red = 1, green = 0.5, blue = 0.5, alpha = 1};}
		public Point[] points {get; set; default = new Point[4];}
		public ulong motion_handler_id {get; set;}

		public Curve () {
			radius_control_point = 5;
			color = {0,0,0,1};
		}
		public void transform_cb (Gtk.Widget widget, Gdk.EventButton event) {
			Point pointer = {event.x - widget.margin, event.y - widget.margin};
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
					Point motion_pointer = {motion_event.x - widget.margin, motion_event.y - widget.margin};
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
		public Array<Point?> points {get; set; default = new Array<Point?> ();}
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
