using Cairo;

public class Plot.View : Gtk.DrawingArea {
	public string group_name {get; private set;}
	public int width {get; set; default = 5*cm;}
	public int height {get; set; default = 5*cm;}
	public Gdk.RGBA color_background {get; set;}
	public Gdk.RGBA color_grid {get; set;}
	public bool has_major_grid {get; set; default = true;}
	public bool has_minor_grid {get; set; default = true;}

	public GenericArray<Layer> layers {get; set; default = new GenericArray<Layer> ();}

	public View () {
		group_name = "View:0:0";
		layers.add (new Layer (0));
		color_background = {1,1,1,1};
		color_grid = {0.5, 0.5, 0.5, 0.5};
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
			width = layers.get (0).width + (int) layers.get (0).top_left_point.x + 51;
			height = layers.get (0).height + (int) layers.get (0).top_left_point.y + 51;
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
		file.set_double (group_name, "width", width);
		file.set_double (group_name, "height", height);
		file.set_string (group_name, "color_background", color_background.to_string ());
		file.set_string (group_name, "color_grid", color_grid.to_string ());
		file.set_boolean (group_name, "has_major_grid", has_major_grid);
		file.set_boolean (group_name, "has_minor_grid", has_minor_grid);
		for (int i = 0; i < layers.length; i++) {
			layers.get (i).save_to_file (file);
		}
	}
	public void open_file (KeyFile file) {
		layers.remove_range (0, layers.length);
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
}
