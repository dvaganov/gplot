public class Plot.Layer : Object {
	private Point priv_start_point;
	private Point shift;
	private Point scale;
	
	public uint id {get; set;}
	public string group_name {get; construct set;}
	public Gdk.RGBA color_background {get; set;}
	public Gdk.RGBA color_border {get; set;}
	public int width {get; set;}
	public int height {get; set;}
	public int[] margin {get; set; default = new int[4];}
	public Axes[] axes {get; private set; default = new Axes[4];}
	// Coordinates parameters
	public Point top_left_point {get; set;}
	public Point units {get; private set;}

//	private signal void on_parameters_changes ();

	public GenericArray<Shapes> children {get; set; default = new GenericArray<Shapes> ();}

	public Layer (int id) {
		this.id = id;
		group_name = @"Layer:0:$id";
		// Default parameters
		color_background = {1, 1, 1, 1};
		color_border = {0, 0, 0, 1};
		width = 4*cm;
		height = 4*cm;
		margin = {mm, 2*mm, 3*mm, mm};
		top_left_point = {0, 0};
		priv_start_point = top_left_point;
		units = {300, 360};
		for (int i = 0; i < axes.length; i++) {
			axes[i] = new Axes (id, (Axes.Orientation) i);
		}
		// Inner calculations
		shift = {top_left_point.x - priv_start_point.x + margin[0], top_left_point.y - priv_start_point.y + margin[3]};
		scale = {(width - margin[0] - margin[1]) / units.x, (height - margin[2] - margin[3]) / units.y};
		notify.connect (notify_cb);
	}
	public Layer.from_file (KeyFile file, int id) {
		group_name = @"Layer:0:$id";
		try {
			_color_background.parse (file.get_string (group_name, "color_background"));
			_color_border.parse (file.get_string (group_name, "color_border"));
			width = file.get_integer (group_name, "width");
			height = file.get_integer (group_name, "height");
			margin = file.get_integer_list (group_name, "margin");
			// Coordinates parameters
			top_left_point = Point.from_string (file.get_string (group_name, "top_left_point"));
			units = Point.from_string (file.get_string (group_name, "units"));
		} catch (KeyFileError err) {
			print (@"$group_name: $(err.message)\n");
		}
		// Children creation
		var groups = file.get_groups ();
		foreach (unowned string group in groups) {
			var temp = group.split (":", 3);
			if (int.parse (temp[1]) == id) {
				switch (temp[0]) {
					case "Axes":
						axes[int.parse (temp[2])] = new Plot.Axes.from_file (file, id, int.parse (temp[2]));
						break;
					case "Scatters":
						children.add (new Plot.Scatters.from_file (file, id, int.parse (temp[2])));
						break;
					case "Curve":
						children.add (new Plot.Curve.from_file (file, id, int.parse (temp[2])));
						break;
				}
			}
		}
		notify.connect (notify_cb);
//		on_parameters_changes ();
	}
	public void save_to_file (KeyFile file) {
		file.set_string (group_name, "color_background", color_background.to_string ());
		file.set_string (group_name, "color_border", color_border.to_string ());
		file.set_integer (group_name, "width", width);
		file.set_integer (group_name, "height", height);
		file.set_integer_list (group_name, "margin", margin);
		// Coordinates parameters
		file.set_string (group_name, "top_left_point", top_left_point.to_string ());
		file.set_string (group_name, "units", units.to_string ());
		// Axes
		for (int i = 0; i < axes.length; i++) {
			axes[i].save_to_file (file);
		}
		// Children
		for (int i = 0; i < children.length; i++) {
			children.get (i).save_to_file (file);
		}
	}
	public void add_shape (Plot.ShapeType shape_type) {
		switch (shape_type) {
			case ShapeType.CURVE:
				children.add (new Curve (id, children.length));
				break;
			case ShapeType.SCATTERS:
				children.add (new Scatters (id, children.length));
				break;
		}
		children.get (children.length - 1).recalculate_points (shift, scale);
	}
	public void draw (Cairo.Context cr) {
		// Draw background and border
		cr.save ();
		Gdk.cairo_set_source_rgba (cr, color_background);
		cr.rectangle (top_left_point.x, top_left_point.y, width, height);
		cr.fill_preserve ();
		cr.restore ();
		cr.save ();
		Gdk.cairo_set_source_rgba (cr, color_border);
		cr.set_line_width (1);
		cr.stroke ();
		cr.restore ();
		// Draw axes
		for (int i = 0; i < axes.length; i++) {
			if (i == 0 || i == 1) {
				axes[i].length = height - margin[2] - margin[3];
			} else if (i == 2 || i == 3) {
				axes[i].length = width - margin[0] - margin[1];
			}
			double x, y;
			x = top_left_point.x + margin[0];
			y = top_left_point.y + margin[3];
			if (i == 1) {
				x = top_left_point.x + width - margin[1];
			}
			if (i == 2) {
				y = top_left_point.y + height - margin[2];
			}
			axes[i].position = {x, y};
			axes[i].draw (cr);
		}
		// Draw shapes
		for (int i = 0; i < children.length; i++) {
			children.get (i).draw (cr);
		}
	}
	public void press_event_cb (Gtk.Widget widget, Gdk.EventButton event) {
		for (int i = 0; i < children.length; i++) {
			if (children.get (i).is_selected) {
				children.get (i).transform (widget, event);
			}
		}
	}
	private void notify_cb (GLib.ParamSpec pspec) {
		switch (pspec.get_name ()) {
			case "top-left-point":
			case "width":
			case "height":
			case "margin":
				shift = {top_left_point.x - priv_start_point.x + margin[0], top_left_point.y - priv_start_point.y + margin[3]};
				scale = {(width - margin[0] - margin[1]) / units.x, (height - margin[2] - margin[3]) / units.y};
				for (int i = 0; i < children.length; i++) {
					children.get (i).recalculate_points (shift, scale);
				}
				break;
		}
	}
	public void settings (Gtk.Stack stack) {
		var layers_path_label = new Gtk.Label ("Path");
		
		var layers_color_background_label = new Gtk.Label ("Background color");
		layers_color_background_label.halign = Gtk.Align.START;

		var layers_color_background_button = new Gtk.ColorButton.with_rgba (color_background);
		layers_color_background_button.halign = Gtk.Align.END;
		layers_color_background_button.color_set.connect (() => {
			color_background = layers_color_background_button.rgba;
		});

		var layers_color_background_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		layers_color_background_box.margin_start = layers_color_background_box.margin_end = 15;
		layers_color_background_box.pack_start (layers_color_background_label);
		layers_color_background_box.pack_start (layers_color_background_button);

		var layers_color_border_label = new Gtk.Label ("Border color");
		layers_color_border_label.halign = Gtk.Align.START;

		var layers_color_border_button = new Gtk.ColorButton.with_rgba (color_border);
		layers_color_border_button.halign = Gtk.Align.END;
		layers_color_border_button.color_set.connect (() => {
			color_border = layers_color_border_button.rgba;
		});

		var layers_color_border_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		layers_color_border_box.margin_start = layers_color_border_box.margin_end = 15;
		layers_color_border_box.pack_start (layers_color_border_label);
		layers_color_border_box.pack_start (layers_color_border_button);
		
		var width_label = new Gtk.Label ("Width");
		width_label.halign = Gtk.Align.START;
		
		var width_spin_button = new Gtk.SpinButton.with_range (0, 10000, 10);
		width_spin_button.halign = Gtk.Align.END;
		width_spin_button.value = width;
		width_spin_button.value_changed.connect (() => {
			width = (int) width_spin_button.value;
		});
		
		var width_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		width_box.margin_start = width_box.margin_end = 15;
		width_box.pack_start (width_label);
		width_box.pack_start (width_spin_button);

		var list_box = new Gtk.ListBox ();
		list_box.selection_mode = Gtk.SelectionMode.NONE;
		list_box.add (layers_color_background_box);
		list_box.add (layers_color_border_box);
		list_box.add (width_box);
		list_box.set_header_func ((row) => {
			if (row.get_index () == 0) {
				row.set_header (null);
			} else if (row.get_header () == null) {
				row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
			}
		});

		var frame = new Gtk.Frame (null);
		frame.shadow_type = Gtk.ShadowType.IN;
		frame.valign = Gtk.Align.START;
		frame.add (list_box);

		var scroll = new Gtk.ScrolledWindow (null, null);
		scroll.add (frame);

		var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 15);
		box.pack_start (layers_path_label, false, true);
		box.pack_start (scroll, true, true);
		
//		plot_view.on_parameters_changes.connect (() => {
//			layers_color_background_button.rgba = color_background;
//			layers_color_grid_button.rgba = color_grid;
//		});

		stack.add_titled (box, "layer", @"Layer $id");
	}
}
