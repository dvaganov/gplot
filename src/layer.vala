using GLib;
using Cairo;

public class Plot.Layer : Object {
	public int id {get; set;}
	public string group_name {get; construct set;}
	public Gdk.RGBA color_background {get; set;}
	public Gdk.RGBA color_grid {get; set;}
	public Point zero_point {get; set;}
	public int width {get; set; default = 0;}
	public int height {get; set; default = 0;}
	public int[] margin {get; set; default = new int[4];}
	public bool has_major_grid {get; set; default = true;}
	public bool has_minor_grid {get; set; default = true;}

	public Array<Shapes?> children {get; set; default = new Array<Shapes?> ();}

	public Layer (int id) {
		this.id = id;
		group_name = "Layer:" + id.to_string ();
		color_background = {1,1,1,1};
		color_grid = {0.5, 0.5, 0.5, 0.5};
		zero_point = {0, 0};
		width = 5*cm;
		height = 4*cm;
		margin = {mm, 2*mm, 3*mm, mm};
		for (int i = 0; i < 4; i++) {
			var temp = new Axes ((Axes.Orientation) i);
			children.append_val (temp);
		}
	}
	public Layer.from_file (KeyFile file, int id) {
		group_name = "Layer:" + id.to_string ();
		try {
			_color_background.parse (file.get_string (group_name, "color_background"));
			_color_grid.parse (file.get_string (group_name, "color_grid"));
			zero_point.from_string (file.get_string (group_name, "zero_point"));
			width = file.get_integer (group_name, "width");
			height = file.get_integer (group_name, "height");
			margin = file.get_integer_list (group_name, "margin");
			has_major_grid = file.get_boolean (group_name, "has_major_grid");
			has_minor_grid = file.get_boolean (group_name, "has_minor_grid");
		} catch (KeyFileError err) {
			stdout.printf ("Layer: %s\n", err.message);
		}
	}
	public void draw (Cairo.Context cr) {
		// Draw background
		cr.save ();
		Gdk.cairo_set_source_rgba (cr, color_background);
		cr.paint ();
		cr.restore ();
		// Draw grid
		draw_grid (cr);
		// Draw border
		cr.save ();
		Gdk.cairo_set_source_rgba (cr, color_grid);
		cr.set_dash ({mm, 0.5*mm}, 0);
		cr.rectangle (-0.5*width - 1 + zero_point.x, -0.5*height - 1 + zero_point.y, width + 2, height + 2);
		cr.stroke ();
		cr.restore ();
		for (int i = 0; i < 4; i++) {
			unowned Axes temp = (Axes) children.index (i);
			if (i == 0 || i == 1) {
				temp.length = height - margin[2] - margin[3];
			} else if (i == 2 || i == 3) {
				temp.length = width - margin[0] - margin[1];
			}
			switch (i) {
				case 0:
				case 2:
					temp.position = {-0.5*width + margin[0], -0.5*height + margin[2]};
					break;
				case 1:
					temp.position = {0.5*width - margin[1], -0.5*height + margin[2]};
					break;
				case 3:
					temp.position = {-0.5*width + margin[0], 0.5*height - margin[3]};
					break;
			}
		}
		for (int i = 0; i < children.length; i++) {
			children.index (i).draw (cr, zero_point);
		}
	}
	private void draw_grid (Cairo.Context cr) {
		if (has_major_grid) {
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color_grid);
			cr.set_line_width (1);
			for (int i = 1; i < width / cm; i++) {
				cr.move_to (-0.5*width + i*cm + zero_point.x, -0.5*height + zero_point.y);
				cr.rel_line_to (0, height);
			}
			for (int i = 1; i < height / cm; i++) {
				cr.move_to (-0.5*width + zero_point.x, -0.5*height + i*cm + zero_point.y);
				cr.rel_line_to (width, 0);
			}
			cr.stroke ();
			cr.restore ();
		}
		if (has_minor_grid) {
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, color_grid);
			cr.set_line_width (0.5);
			for (int i = 1; i < width / mm; i++) {
				cr.move_to (-0.5*width + i*mm + zero_point.x, -0.5*height + zero_point.y);
				cr.rel_line_to (0, height);
			}
			for (int i = 1; i < height / mm; i++) {
				cr.move_to (-0.5*width + zero_point.x, -0.5*height + i*mm + zero_point.y);
				cr.rel_line_to (width, 0);
			}
			cr.stroke ();
			cr.restore ();
		}
	}
	public void save_to_file (KeyFile file) {
		file.set_string (group_name, "color_background", color_background.to_string ());
		file.set_string (group_name, "color_grid", color_grid.to_string ());
		file.set_string (group_name, "zero_point", zero_point.to_string ());
		file.set_integer (group_name, "width", width);
		file.set_integer (group_name, "height", height);
		file.set_integer_list (group_name, "margin", margin);
		file.set_boolean (group_name, "has_major_grid", has_major_grid);
		file.set_boolean (group_name, "has_minor_grid", has_minor_grid);
		for (int i = 0; i < children.length; i++) {
			children.index (i).save_to_file (file);
		}
	}
}
