using GLib;
using Cairo;
using Plot;

public class Plot.Scatters : Plot.Shapes {
	public enum Form {
		NONE,
		SQUARE,
		CIRCLE
	}

	public Form form {get; set; default = Form.SQUARE;}
	public Gdk.RGBA color_scatters {get; set;}
	public Gdk.RGBA color_line {get; set;}
	public int size {get; set; default = mm;}

	public Scatters (uint parent_id, uint id) {
		this.id = id;
		group_name = @"Scatters:$parent_id:$id";
		color_scatters = {0, 0, 0, 1};
		color_line = {0, 0, 0, 1};
		for (int i = 0; i < 4; i++) {
			points.add (Point () {x = i*cm, y = i*cm});
		}
	}
	public Scatters.from_file (KeyFile file, uint parent_id, uint id) {
		group_name = @"Scatters:$parent_id:$id";
		try {
			// From Shapes
			is_selected = file.get_boolean (group_name, "is_selected");
			var points_list = file.get_string_list (group_name, "points");
			foreach (unowned string point in points_list) {
				points.add (Point.from_string (point));
			}
			scale = Point.from_string (file.get_string (group_name, "scale"));
			shift = Point.from_string (file.get_string (group_name, "shift"));
			// From Scatters
			form = (Form) file.get_integer (group_name, "form");
			_color_scatters.parse (file.get_string (group_name, "color_scatters"));
			_color_line.parse (file.get_string (group_name, "color_line"));
			size = file.get_integer (group_name, "size");
		} catch (KeyFileError err) {
			print (@"$group_name: $(err.message)\n");
		}
	}
	public override void save_to_file (KeyFile file) {
		// From Shapes
		file.set_boolean (group_name, "is_selected", is_selected);
		string[] points_list = new string[points.length];
		for (int i = 0; i < points.length; i++) {
			points_list[i] = points.get (i).to_string ();
		}
		file.set_string_list (group_name, "points", points_list);
		file.set_string (group_name, "scale", scale.to_string ());
		file.set_string (group_name, "shift", shift.to_string ());
		// From Scatters
		file.set_integer (group_name, "form", (int) form);
		file.set_string (group_name, "color_scatters", color_scatters.to_string ());
		file.set_string (group_name, "color_line", color_line.to_string ());
		file.set_integer (group_name, "size", size);
	}
	public override void draw (Context cr) {
		cr.save ();
		Gdk.cairo_set_source_rgba (cr, color_scatters);
		switch (form) {
			case Form.SQUARE:
				for (int i = 0; i < points.length; i++) {
					cr.move_to (points.get (i).x - 0.5*size, points.get (i).y - 0.5*size);
					cr.rel_line_to (size, 0);
					cr.rel_line_to (0, size);
					cr.rel_line_to (-size, 0);
					cr.close_path ();
				}
				cr.fill ();
				break;
		}
		cr.restore ();
	}
	public override void transform (Gtk.Widget widget, Gdk.EventButton event) {
		return;
	}
}
