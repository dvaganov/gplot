using Cairo;

namespace Plot {
	const double mm = 10;
	const double cm = 10*mm;

	const ushort LEFT = 0;
	const ushort BOTTOM = 1;
	const ushort RIGHT = 2;
	const ushort TOP = 3;

	public class View : Gtk.DrawingArea {
		public double width {get; set; default = 5*cm;}
		public double height {get; set; default = 5*cm;}
		public double padding {get; set; default = mm;}

		public Background bkg;
		public Axes[] axes;
		public Curve curve1;
		public Scatters scatters;

		public View () {
			margin = (int) mm;
			width_request = (int) (width + 2*margin);
			height_request = (int) (height + 2*margin);
			add_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK);
			button_press_event.connect ((event) => {
				if (event.button == 1 & event.type == Gdk.EventType.BUTTON_PRESS) {
					curve1.transform_cb (this, event);
				}
				queue_draw ();
				return true;
			});
			button_release_event.connect ((event) => {
				curve1.remove_motion_cb (this);
				return true;
			});

			bkg = new Background ();
			bkg.width = width;
			bkg.height = height;

			// Default settings
			axes = new Axes[4];
			axes[LEFT] = new Axes (height, Axes.Orientation.LEFT);
			axes[LEFT].position = 0;
			axes[BOTTOM] = new Axes (width, Axes.Orientation.BOTTOM);
			axes[BOTTOM].position = height;
			axes[RIGHT] = new Axes (height, Axes.Orientation.RIGHT);
			axes[RIGHT].position = width;
			axes[RIGHT].tick_type = Axes.TickType.OUT;
			axes[TOP] = new Axes (width, Axes.Orientation.TOP);
			axes[TOP].position = 0;
			axes[TOP].tick_type = Axes.TickType.BOTH;

			for (int i = 0; i < axes.length; i++) {
				axes[i].major_tick = 8;
				axes[i].minor_tick = 5;
			}

			curve1 = new Curve (1);
			curve1.points[0] = {5*cm, 5*cm};
			curve1.points[1] = {5*cm, 2*cm};
			curve1.points[2] = {3*cm, 5*cm};
			curve1.points[3] = {7*cm, 4*cm};

			scatters = new Scatters (0);
			scatters.points.append_val ({1*cm, 1*cm});
			scatters.points.append_val ({2*cm, 2*cm});
			scatters.points.append_val ({3*cm, 3*cm});

			draw.connect ((context) => {
				draw_in_context (context);
				return true;
			});

			queue_draw ();
		}
		private void draw_in_context (Cairo.Context context) {
			//FIXME: Not drawn if nothing changes
			// Create border
			context.translate (margin, margin);

			// Draw a paper:
			bkg.draw (context);
			bkg.draw_grid (context);

			// Draw axes
			for (int i = 0; i < axes.length; i++) {
				axes[i].draw (context);
			}
			curve1.draw (context);

			scatters.draw (context);
		}
		public void export_to_eps (string filename) {
			var ps_surface = new Cairo.PsSurface (filename, width + 2*margin, height + 2*margin);
			ps_surface.set_eps (true);
			var export_context = new Cairo.Context (ps_surface);
			draw_in_context (export_context);
		}
		public void export_to_svg (string filename) {
			var svg_surface = new Cairo.SvgSurface (filename, width + 2*margin, height + 2*margin);
			var export_context = new Cairo.Context (svg_surface);
			draw_in_context (export_context);
		}
		public void save_to_file (KeyFile file) {
			string group_name = "View";
			file.set_double (group_name, "width", width);
			file.set_double (group_name, "height", height);
			file.set_double (group_name, "padding", padding);
			bkg.save_to_file (file);
			for (var i = 0; i < axes.length; i++) {
				axes[i].save_to_file (file);
			}
			scatters.save_to_file (file);
			curve1.save_to_file (file);
		}
	}
}
