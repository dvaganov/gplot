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
		public Axes axes[4];
		public Curve curve1;
		public Scatters scatters;

		public View () {
			add_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK);
			button_press_event.connect ((event) => {
				if (event.button == 1 & event.type == Gdk.EventType.BUTTON_PRESS) {
					var context = Gdk.cairo_create (this.get_window ());
					context.translate (get_allocated_width () / 2, get_allocated_height () / 2);
					context.scale (1, -1);
					if (curve1 != null) {
						curve1.transform_cb (this, event, context);
					}
				}
				queue_draw ();
				return true;
			});
			button_release_event.connect ((event) => {
				if (curve1 != null) {
					curve1.remove_motion_cb (this);
				}
				return true;
			});

			draw.connect ((context) => {
				draw_in_context (context);
				return true;
			});
			
			// Temporarily
			var filename = "saved.gpj";
			KeyFile file = new KeyFile ();
			try {
				file.load_from_file (filename, KeyFileFlags.NONE);
			} catch (KeyFileError key_err) {
				stdout.printf ("Load file: %s\n", key_err.message);
			} catch (FileError err) {
				stdout.printf ("Load file: %s\n", err.message);
			}
			file.set_list_separator ('=');
			load_from_file (file);
		}
		private void draw_in_context (Cairo.Context context) {
			// Modify cmt
			context.translate (get_allocated_width () / 2, get_allocated_height () / 2);
			context.scale (1, -1);

			// Draw a paper:
			if (bkg != null) {
				bkg.draw (context);
				bkg.draw_grid (context);
			}

			// Draw axes
			for (int i = 0; i < axes.length; i++) {
				if (axes[i] != null) {
					axes[i].draw (context);
				}
			}

			if (scatters != null) {
				scatters.draw (context);
			}
			if (curve1 != null) {
				curve1.draw (context);
			}
		}
		public void export_to_eps (string filename) {
			var ps_surface = new Cairo.PsSurface (filename, width + 2*padding, height + 2*padding);
			ps_surface.set_eps (true);
			var export_context = new Cairo.Context (ps_surface);
			draw_in_context (export_context);
		}
		public void export_to_svg (string filename) {
			var svg_surface = new Cairo.SvgSurface (filename, width + 2*padding, height + 2*padding);
			var export_context = new Cairo.Context (svg_surface);
			draw_in_context (export_context);
		}
		public void save_to_file (KeyFile file) {
			string group_name = "View:0";
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
		public void load_from_file (KeyFile file) {
			var groups = file.get_groups ();
			string group[2];
			int id;
			for (int i = 0; i < groups.length; i++) {
				group = groups[i].split (":", 2);
				id = int.parse (group[1]);
				switch (group[0]) {
					case "Background":
						bkg = new Background.from_file (file, id);
						break;
					case "Axes":
						axes[id] = new Axes.from_file (file, id);
						break;
					case "Scatters":
						scatters = new Scatters.from_file (file, id);
						break;
					case "Curve":
						curve1 = new Curve.from_file (file, id);
						break;
				}
			}
		}
	}
}
