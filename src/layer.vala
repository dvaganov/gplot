using GLib;
using Cairo;
using Plot;

public class Plot.Layer : Object {
	private Point priv_start_point;
	private Point shift;
	private Point scale;
	
	public int id {get; set;}
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

	public Array<Shapes?> children {get; set; default = new Array<Shapes?> ();}

	public Layer (int id) {
		this.id = id;
		group_name = @"Layer:0:$id";
		color_background = {1, 1, 1, 1};
		color_border = {0, 0, 0, 1};
		width = 330;
		height = 4*cm;
		margin = {mm, 2*mm, 3*mm, mm};
		top_left_point = shift = {0, 0};
		priv_start_point = top_left_point;
		scale = {1, 1};
		units = {300, 360};
		notify.connect (notify_cb);
		for (int i = 0; i < axes.length; i++) {
			axes[i] = new Axes (id, (Axes.Orientation) i);
		}
		var temp = new Plot.Curve (id, 0);
		children.append_val (temp);
		var temp2 = new Plot.Scatters (id, 0);
		children.append_val (temp2);
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
						var shape = new Plot.Scatters.from_file (file, id, int.parse (temp[2]));
						children.append_val (shape);
						break;
					case "Curve":
						var shape = new Plot.Curve.from_file (file, id, int.parse (temp[2]));
						children.append_val (shape);
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
			children.index (i).save_to_file (file);
		}
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
			children.index (i).draw (cr);
		}
	}
	public void press_event_cb (Gtk.Widget widget, Gdk.EventButton event) {
		for (int i = 0; i < children.length; i++) {
			if (children.index (i).is_selected) {
				children.index (i).transform (widget, event);
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
					children.index (i).recalculate_points (shift, scale);
				}
				break;
		}
	}
}
