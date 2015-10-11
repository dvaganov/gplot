using GLib;
using Cairo;

public class Plot.Axes : Object {
	public enum Orientation {
		LEFT,
		RIGHT,
		BOTTOM,
		TOP
	}
	public enum TickType {
		NONE,
		IN,
		OUT,
		BOTH
	}
	public int id {get; construct set;}
	public string group_name {get; construct set;}
	// Axes parameters
	public Orientation orientation {get; private set;}
	public Gdk.RGBA color {get; set;}
	public bool visible {get; set; default = true;}
	public double length {get; set;}
	public Point position {get; set;}
	public double zero_point {get; set;}
	public string caption {get; set; default = "";}
	// Ticks parameters
	public TickType tick_type {get; set; default = TickType.IN;}
	public int major_tick {get; set; default = 4;}
	public double major_tick_size {get; set; default = mm;}
	public int minor_tick {get; set; default = 5;}
	public double minor_tick_size {get; set; default = 0.5*mm;}

	public Axes (uint parent_id, Orientation orientation) {
		this.id = (int) orientation;
		group_name = @"Axes:$parent_id:$id";
		this.orientation = orientation;
		position = {0, 0};
		color = {0,0,0,1.0};
	}
	public Axes.from_file (KeyFile file, uint parent_id, uint id) {
		group_name = @"Axes:$parent_id:$id";
		try {
			orientation = (Orientation) id;
			_color.parse (file.get_string (group_name, "color"));
			visible = file.get_boolean (group_name, "visible");
			// Axes parameters
			length = file.get_double (group_name, "length");
			position = Point.from_string (file.get_string (group_name, "position"));
			zero_point = file.get_double (group_name, "zero_point");
			caption = file.get_string (group_name, "caption");
			// Ticks parameters
			tick_type = (TickType) file.get_integer (group_name, "tick_type");
			major_tick = file.get_integer (group_name, "major_tick");
			major_tick_size = file.get_double (group_name, "major_tick_size");
			minor_tick = file.get_integer (group_name, "minor_tick");
			minor_tick_size = file.get_double (group_name, "minor_tick_size");
		} catch (KeyFileError err) {
			print (@"$group_name: $(err.message)\n");
		}
	}
	public void save_to_file (KeyFile file) {
		file.set_string (group_name, "color", color.to_string ());
		file.set_boolean (group_name, "visible", visible);
		// Axes parameters
		file.set_double (group_name, "length", length);
		file.set_string (group_name, "position", position.to_string ());
		file.set_double (group_name, "zero_point", zero_point);
		file.set_string (group_name, "caption", caption);
		// Ticks parameters
		file.set_integer (group_name, "tick_type", ((int) tick_type));
		file.set_integer (group_name, "major_tick", major_tick);
		file.set_double (group_name, "major_tick_size", major_tick_size);
		file.set_integer (group_name, "minor_tick", minor_tick);
		file.set_double (group_name, "minor_tick_size", minor_tick_size);
	}
	public void draw (Cairo.Context cr) {
		cr.save ();
		Gdk.cairo_set_source_rgba (cr, color);
		cr.set_line_width (1);
		// Draw ticks
		double tick_amount = major_tick + minor_tick * (major_tick - 1);
		double tick_interval = length / (tick_amount - 1);
		double tick_size = major_tick_size;
		for (var i = 0; i < tick_amount; i++) {
			if (i % (1 + minor_tick) == 0) {
				tick_size = major_tick_size;
			} else {
				tick_size = minor_tick_size;
			}
			switch (orientation) {
				case Orientation.LEFT:
					cr.move_to (position.x, position.y + i * tick_interval);
					switch (tick_type) {
						case TickType.IN:
							cr.rel_line_to (tick_size, 0);
							break;
						case TickType.OUT:
							cr.rel_line_to (-tick_size, 0);
							break;
						case TickType.BOTH:
							cr.move_to (position.x - tick_size, position.y + i * tick_interval);
							cr.rel_line_to (2*tick_size, 0);
							break;
						case TickType.NONE:
							break;
					}
					break;
				case Orientation.RIGHT:
					cr.move_to (position.x, position.y + i * tick_interval);
					switch (tick_type) {
						case TickType.IN:
							cr.rel_line_to (-tick_size, 0);
							break;
						case TickType.OUT:
							cr.rel_line_to (tick_size, 0);
							break;
						case TickType.BOTH:
							cr.move_to (position.x - tick_size, position.y + i * tick_interval);
							cr.rel_line_to (2*tick_size, 0);
							break;
						case TickType.NONE:
							break;
					}
					break;
				case Orientation.BOTTOM:
					cr.move_to (position.x + i * tick_interval, position.y);
					switch (tick_type) {
						case TickType.IN:
							cr.rel_line_to (0, -tick_size);
							break;
						case TickType.OUT:
							cr.rel_line_to (0, tick_size);
							break;
						case TickType.BOTH:
							cr.move_to (position.x + i * tick_interval, position.y - tick_size);
							cr.rel_line_to (0, 2*tick_size);
							break;
						case TickType.NONE:
							break;
					}
					break;
				case Orientation.TOP:
					cr.move_to (position.x + i * tick_interval, position.y);
					switch (tick_type) {
						case TickType.IN:
							cr.rel_line_to (0, tick_size);
							break;
						case TickType.OUT:
							cr.rel_line_to (0, -tick_size);
							break;
						case TickType.BOTH:
							cr.move_to (position.x + i * tick_interval, position.y - tick_size);
							cr.rel_line_to (0, 2*tick_size);
							break;
						case TickType.NONE:
							break;
					}
					break;
			}
		}
		// Draw axes
		cr.move_to (position.x, position.y);
		switch (orientation) {
			case Orientation.LEFT:
			case Orientation.RIGHT:
				cr.rel_line_to (0, length);
				break;
			case Orientation.BOTTOM:
			case Orientation.TOP:
				cr.rel_line_to (length, 0);
				break;
		}
		cr.stroke ();
		cr.restore ();
	}
}
