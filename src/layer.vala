public class Plot.Layer : Object {
	private Point priv_start_point;
	private Point shift;
	private Point scale;
	private Gdk.RGBA color_background {get; set;}
	private Gdk.RGBA color_border {get; set;}

	public uint id {get; set;}
	public string group_name {get; construct set;}
	public Point top_left_point {get; set;}
	public int width {get; set;}
	public int height {get; set;}
	public int[] margin {get; set; default = new int[4];}
	public Axes[] axes {get; private set; default = new Axes[4];}
	// Coordinates parameters
	public Point units {get; private set;}

	public unowned RedrawFunc redraw {private get; set;}

	public GenericArray<Shapes> children {get; set; default = new GenericArray<Shapes> ();}

	public Layer (int id) {
		this.id = id;
		group_name = @"Layer:0:$id";
		// Default parameters
		color_background = {1, 1, 1, 1};
		color_border = {0, 0, 0, 1};
		width = 4*cm;
		height = 4*cm;
		margin = {mm, mm, mm, mm};
		top_left_point = {0, 0};
		priv_start_point = top_left_point;
		units = {300, 360};
		for (int i = 0; i < axes.length; i++) {
			axes[i] = new Axes (id, (Axes.Orientation) i);
			axes[i].redraw = () => redraw ();
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
		Gtk.ListBox list_box[3];
		for (int i = 0; i < list_box.length; i++) {
			list_box[i] = new Gtk.ListBox ();
			list_box[i].selection_mode = Gtk.SelectionMode.NONE;
			list_box[i].set_header_func ((row) => {
				if (row.get_index () == 0) {
					row.set_header (null);
				} else if (row.get_header () == null) {
					row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
				}
			});
		}
		// General
		list_box[0].add (create_box_with_color_btn ("Background color", &_color_background));
		list_box[0].add (create_box_with_color_btn ("Border color", &_color_border));
		list_box[0].add (create_box_with_spin_btn_int ("Width, px", &_width, 0, 10000, 10, redraw));
		list_box[0].add (create_box_with_spin_btn_int ("Height, px", &_height, 0, 10000, 10, redraw));
		// Position
		list_box[1].add (create_box_with_spin_btn_double ("Left, px", &_top_left_point.x, 0, 10000, 10, redraw));
		list_box[1].add (create_box_with_spin_btn_double ("Top, px", &_top_left_point.y, 0, 10000, 10, redraw));
		// Margins
		string margin_names[4] = {"Left", "Right", "Bottom", "Top"};
		for (var i = 0; i < margin.length; i++) {
			list_box[2].add (create_box_with_spin_btn_int (margin_names[i], &_margin[i], 0, 10000, 10, redraw));
		}
		// Add to box
		var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 15);
		Gtk.Frame frame;
		string? titles[3] = {null, "Position", "Margins"};
		for (var i = 0; i < list_box.length; i++) {
			frame = new Gtk.Frame (null);
			frame.shadow_type = Gtk.ShadowType.IN;
			frame.valign = Gtk.Align.START;
			frame.add (list_box[i]);
			if (titles[i] != null) {
				box.pack_start (new Gtk.Label (titles[i]));
			}
			box.pack_start (frame, false);
		}
		// Add to stack
		var scroll = new Gtk.ScrolledWindow (null, null);
		scroll.add (box);
		stack.add_titled (scroll, group_name, @"Layer $id");
		// Create settings for children
		foreach (Plot.Axes _axes in axes) {
			_axes.settings (stack);
		}
	}
}
