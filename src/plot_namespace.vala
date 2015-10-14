namespace Plot {
	const int mm = 10;
	const int cm = 10*mm;
	
	public delegate void RedrawFunc ();

	public enum ShapeType {
		CURVE, SCATTERS
	}
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
	public Gtk.Box create_color_box (string title, Gdk.RGBA* color) {
		var label = new Gtk.Label (title);
		label.halign = Gtk.Align.START;
		label.margin_start = 15;

		var button = new Gtk.ColorButton.with_rgba (*color);
		button.halign = Gtk.Align.END;
		button.margin_end = 15;
		button.color_set.connect ((widget) => {
			*color = widget.get_rgba ();
		});

		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		box.pack_start (label);
		box.pack_start (button);
		return box;
	}
	public Gtk.Box create_spin_box_int (string title, int* parameter, double min, double max, double step, RedrawFunc redraw) {
		var label = new Gtk.Label (title);
		label.halign = Gtk.Align.START;
		label.margin_start = 15;

		var spin_button = new Gtk.SpinButton.with_range (min, max, step);
		spin_button.halign = Gtk.Align.END;
		spin_button.margin_end = 15;
		spin_button.value = *parameter;
		spin_button.value_changed.connect ((widget) => {
			*parameter = (int) widget.value;
			if (redraw != null) redraw ();
		});

		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		box.pack_start (label);
		box.pack_start (spin_button);
		return box;
	}
	public Gtk.Box create_spin_box_double (string title, double* parameter, double min, double max, double step, RedrawFunc redraw) {
		var label = new Gtk.Label (title);
		label.halign = Gtk.Align.START;
		label.margin_start = 15;

		var spin_button = new Gtk.SpinButton.with_range (min, max, step);
		spin_button.halign = Gtk.Align.END;
		spin_button.margin_end = 15;
		spin_button.value = *parameter;
		spin_button.value_changed.connect ((widget) => {
			*parameter = widget.value;
			if (redraw != null) redraw ();
		});

		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		box.pack_start (label);
		box.pack_start (spin_button);
		return box;
	}
	public Gtk.Box create_boolean_box (string title, bool* parameter, RedrawFunc redraw) {
		var label = new Gtk.Label (title);
		label.halign = Gtk.Align.START;
		label.margin_start = 15;
		
		var @switch = new Gtk.Switch ();
		@switch.halign = Gtk.Align.END;
		@switch.margin_end = 15;
		@switch.active = *parameter;
		@switch.notify["active"].connect (() => {
			if (@switch.active) {
				*parameter = true;
			} else {
				*parameter = false;
			}
			if (redraw != null) redraw ();
		});

		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		box.pack_start (label);
		box.pack_start (@switch);
		return box;
	}
}
