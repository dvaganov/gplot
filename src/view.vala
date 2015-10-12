public class Plot.View : Gtk.DrawingArea {
	public string group_name {get; private set;}
	public int width {get; private set;}
	public int height {get; private set;}
	public Gdk.RGBA color_background {get; set;}
	public Gdk.RGBA color_grid {get; set;}
	public bool has_major_grid {get; set; default = true;}
	public bool has_minor_grid {get; set; default = true;}
	
	public signal void on_parameters_changes ();

	public GenericArray<Layer> layers {get; set; default = new GenericArray<Layer> ();}

	public View () {
		group_name = "View:0:0";
		layers.add (new Layer (0));
		color_background = {1,1,1,1};
		_color_grid.parse ("#D3D7CF");
		add_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK);
		button_press_event.connect (button_press_event_cb);
		button_release_event.connect ((event) => {
			for (int i = 0; i < layers.length; i++) {
				for (int k = 0; k < layers.get (i).children.length; k++) {
					if (layers.get (i).children.get (k).motion_handler_id != null) {
						disconnect (layers.get (i).children.get (k).motion_handler_id);
						layers.get (i).children.get (k).motion_handler_id = null;
					}
				}
			}
			return true;
		});
		draw.connect ((context) => {
			width = layers.get (0).width + (int) layers.get (0).top_left_point.x;
			height = layers.get (0).height + (int) layers.get (0).top_left_point.y;
			width_request = width;
			height_request = height;
			draw_in_context (context, get_allocated_width (), get_allocated_height ());
			return true;
		});
	}
	private bool button_press_event_cb (Gdk.EventButton event) {
		if (event.button == 1 & event.type == Gdk.EventType.BUTTON_PRESS) {
//			Point min, max;
			for (int i = 0; i < layers.length; i++) {
//				min = {layers.index (i).top_left_point.x, layers.index (i).top_left_point.y};
//				max = {min.x + layers.index (i).width, min.y + layers.index (i).height};
//				if (min.x < event.x && event.x < max.x && min.y < event.y && event.y < max.y) {
					layers.get (i).press_event_cb (this, event);
//				}
			}
		}
		return true;
	}
	private void draw_in_context (Cairo.Context cr, double cr_width, double cr_height) {
		draw_background (cr);
		layers.get (0).draw (cr);
	}
	private void draw_background (Cairo.Context cr) {
		// Draw background
		cr.save ();
		Gdk.cairo_set_source_rgba (cr, color_background);
		cr.paint ();
		cr.restore ();
		// Draw major grid
		if (has_major_grid) {
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color_grid);
			cr.set_line_width (1);
			for (int i = 0; i < get_allocated_width () / cm + 1; i++) {
				cr.move_to (i*cm, 0);
				cr.rel_line_to (0, get_allocated_height ());
			}
			for (int i = 1; i < get_allocated_height () / cm + 1; i++) {
				cr.move_to (0, i*cm);
				cr.rel_line_to (get_allocated_width (), 0);
			}
			cr.stroke ();
			cr.restore ();
		}
		// Draw minor grid
		if (has_minor_grid) {
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color_grid);
			cr.set_line_width (0.5);
			for (int i = 0; i < get_allocated_width () / mm + 1; i++) {
				cr.move_to (i*mm, 0);
				cr.rel_line_to (0, get_allocated_height ());
			}
			for (int i = 1; i < get_allocated_height () / mm + 1; i++) {
				cr.move_to (0, i*mm);
				cr.rel_line_to (get_allocated_width (), 0);
			}
			cr.stroke ();
			cr.restore ();
		}
	}
	public void export_to_eps (string filename) {
		var ps_surface = new Cairo.PsSurface (filename, width, height);
		ps_surface.set_eps (true);
		ps_surface.restrict_to_level (Cairo.PsLevel.LEVEL_3);
		var export_context = new Cairo.Context (ps_surface);
		draw_in_context (export_context, width, height);
	}
	public void export_to_svg (string filename) {
		var svg_surface = new Cairo.SvgSurface (filename, width, height);
		var export_context = new Cairo.Context (svg_surface);
		draw_in_context (export_context, width, height);
	}
	public void save_to_file (KeyFile file) {
		file.set_string (group_name, "color_background", color_background.to_string ());
		file.set_string (group_name, "color_grid", color_grid.to_string ());
		file.set_boolean (group_name, "has_major_grid", has_major_grid);
		file.set_boolean (group_name, "has_minor_grid", has_minor_grid);
		for (int i = 0; i < layers.length; i++) {
			layers.get (i).save_to_file (file);
		}
	}
	public void open_file (KeyFile file) {
		try {
			_color_background.parse (file.get_string (group_name, "color_background"));
			_color_grid.parse (file.get_string (group_name, "color_grid"));
			has_major_grid = file.get_boolean (group_name, "has_major_grid");
			has_minor_grid = file.get_boolean (group_name, "has_minor_grid");
			layers.remove_range (0, layers.length);
			on_parameters_changes ();
		} catch (KeyFileError err) {
			print (@"$group_name: $(err.message)\n");
		}
		var groups = file.get_groups ();
		string group[2];
		int id;
		for (int i = 0; i < groups.length; i++) {
			group = groups[i].split (":", 2);
			id = int.parse (group[1]);
			if (group[0] == "Layer") {
				layers.add (new Layer.from_file (file, id));
			}
		}
		queue_draw ();
	}
	public void settings (Gtk.Stack stack) {
		var color_background_label = new Gtk.Label ("Background color");
		color_background_label.halign = Gtk.Align.START;

		var color_background_button = new Gtk.ColorButton.with_rgba (color_background);
		color_background_button.halign = Gtk.Align.END;
		color_background_button.color_set.connect (() => {
			color_background = color_background_button.rgba;
		});

		var color_background_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		color_background_box.margin_start = color_background_box.margin_end = 15;
		color_background_box.pack_start (color_background_label);
		color_background_box.pack_start (color_background_button);

		var color_grid_label = new Gtk.Label ("Grid color");
		color_grid_label.halign = Gtk.Align.START;

		var color_grid_button = new Gtk.ColorButton.with_rgba (color_grid);
		color_grid_button.halign = Gtk.Align.END;
		color_grid_button.color_set.connect (() => {
			color_grid = color_grid_button.rgba;
		});

		var color_grid_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		color_grid_box.margin_start = color_grid_box.margin_end = 15;
		color_grid_box.pack_start (color_grid_label);
		color_grid_box.pack_start (color_grid_button);

		var major_grid_label = new Gtk.Label ("Major grid");
		major_grid_label.halign = Gtk.Align.START;

		var major_grid_switch = new Gtk.Switch ();
		major_grid_switch.halign = Gtk.Align.END;
		major_grid_switch.active = has_major_grid;
		major_grid_switch.notify["active"].connect (() => {
			if (major_grid_switch.active) {
				has_major_grid = true;
			} else {
				has_major_grid = false;
			}
			queue_draw ();
		});

		var major_grid_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		major_grid_box.margin_start = major_grid_box.margin_end = 15;
		major_grid_box.pack_start (major_grid_label);
		major_grid_box.pack_start (major_grid_switch);

		var minor_grid_label = new Gtk.Label ("Major grid");
		minor_grid_label.halign = Gtk.Align.START;

		var minor_grid_switch = new Gtk.Switch ();
		minor_grid_switch.halign = Gtk.Align.END;
		minor_grid_switch.active = has_minor_grid;
		minor_grid_switch.notify["active"].connect (() => {
			if (minor_grid_switch.active) {
				has_minor_grid = true;
			} else {
				has_minor_grid = false;
			}
			queue_draw ();
		});

		var minor_grid_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		minor_grid_box.margin_start = minor_grid_box.margin_end = 15;
		minor_grid_box.pack_start (minor_grid_label);
		minor_grid_box.pack_start (minor_grid_switch);

		var list_box = new Gtk.ListBox ();
		list_box.selection_mode = Gtk.SelectionMode.NONE;
		list_box.add (color_background_box);
		list_box.add (color_grid_box);
		list_box.add (major_grid_box);
		list_box.add (minor_grid_box);
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
		box.pack_start (scroll, true, true);
		
		on_parameters_changes.connect (() => {
			color_background_button.rgba = color_background;
			color_grid_button.rgba = color_grid;
			major_grid_switch.active = has_major_grid;
			minor_grid_switch.active = has_minor_grid;
		});

		stack.add_titled (box, "background", "Background");
	}
}
