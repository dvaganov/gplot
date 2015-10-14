using GLib;
using Cairo;

public class Plot.Axes : Object {
	public enum Orientation {
		LEFT, RIGHT, BOTTOM, TOP;
		public string to_string () {
			switch (this){
				case LEFT:
					return "Left";
				case RIGHT:
					return "Right";
				case BOTTOM:
					return "Bottom";
				case TOP:
					return "Top";
				default:
					return "Not define";
			}
		}
	}
	public enum TickType {
		NONE, IN, OUT, BOTH;
	}
	public int id {get; construct set;}
	public string group_name {get; construct set;}
	// Axes parameters
	private Gdk.RGBA _color;
	private Orientation orientation {get; private set;}
	public double length {get; set;}
	public Point position {get; set;}
	public bool visible {get; set; default = true;}
	public double zero_point {get; set;}
	public string caption {get; set; default = "";}
	// Ticks parameters
	private double major_tick_size {get; set; default = mm;}
	private double minor_tick_size {get; set; default = 0.5*mm;}
	public TickType tick_type {get; set; default = TickType.IN;}
	public int major_tick {get; set; default = 4;}
	public int minor_tick {get; set; default = 5;}

	public signal void redraw ();

	public Axes (uint parent_id, Orientation orientation) {
		this.id = (int) orientation;
		group_name = @"Axes:$parent_id:$id";
		this.orientation = orientation;
		position = {0, 0};
		_color = {0,0,0,1.0};
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
		file.set_string (group_name, "color", _color.to_string ());
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
		if (visible) {
			cr.save ();
			Gdk.cairo_set_source_rgba (cr, _color);
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
	public void settings (Gtk.Stack stack) {
		var visible_label = new Gtk.Label ("Visible");
		visible_label.margin_start = 15;
		visible_label.halign = Gtk.Align.START;

		var visible_switch = new Gtk.Switch ();
		visible_switch.halign = Gtk.Align.END;
		visible_switch.margin_end = 15;
		visible_switch.active = visible;
		visible_switch.notify["active"].connect (() => {
			if (visible_switch.active) {
				visible = true;
			} else {
				visible = false;
			}
			redraw ();
		});

		var visible_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		visible_box.pack_start (visible_label);
		visible_box.pack_start (visible_switch);

		/*var color_label = new Gtk.Label ("Line color");
		color_label.halign = Gtk.Align.START;
		color_label.margin_start = 15;

		var color_button = new Gtk.ColorButton.with_rgba (color);
		color_button.halign = Gtk.Align.END;
		color_button.margin_end = 15;
		color_button.color_set.connect ((widget) => {
			color = widget.rgba;
		});

		var color_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		color_box.pack_start (color_label);
		color_box.pack_start (color_button);*/

		var major_tick_label = new Gtk.Label ("Major tick");
		major_tick_label.halign = Gtk.Align.START;
		major_tick_label.margin_start = 15;

		var major_tick_spin_button = new Gtk.SpinButton.with_range (0, 100, 1);
		major_tick_spin_button.halign = Gtk.Align.END;
		major_tick_label.margin_end = 15;
		major_tick_spin_button.value = major_tick;
		major_tick_spin_button.value_changed.connect ((widget) => {
			major_tick = (int) widget.value;
			redraw ();
		});

		var major_tick_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		major_tick_box.pack_start (major_tick_label);
		major_tick_box.pack_start (major_tick_spin_button);

		var list_box_0 = new Gtk.ListBox ();
		list_box_0.selection_mode = Gtk.SelectionMode.NONE;
		list_box_0.add (visible_box);
		list_box_0.add (create_color_box ("Line color", &_color));
		list_box_0.add (major_tick_box);
		list_box_0.set_header_func ((row) => {
			if (row.get_index () == 0) {
				row.set_header (null);
			} else if (row.get_header () == null) {
				row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
			}
		});

		var frame_0 = new Gtk.Frame (null);
		frame_0.shadow_type = Gtk.ShadowType.IN;
		frame_0.valign = Gtk.Align.START;
		frame_0.add (list_box_0);

		var tick_type_none_button = new Gtk.RadioButton.with_label (null, "None");
		tick_type_none_button.toggled.connect ((btn) => {
			if (tick_type != TickType.NONE) {
				tick_type = TickType.NONE;
				redraw ();
			}
		});
		var tick_type_both_button = new Gtk.RadioButton.with_label_from_widget (tick_type_none_button, "Both");
		tick_type_both_button.toggled.connect ((btn) => {
			if (tick_type != TickType.BOTH) {
				tick_type = TickType.BOTH;
				redraw ();
			}
		});
		var tick_type_in_button = new Gtk.RadioButton.with_label_from_widget (tick_type_none_button, "In");
		tick_type_in_button.toggled.connect ((btn) => {
			if (tick_type != TickType.IN) {
				tick_type = TickType.IN;
				redraw ();
			}
		});
		var tick_type_out_button = new Gtk.RadioButton.with_label_from_widget (tick_type_none_button, "Out");
		tick_type_out_button.toggled.connect ((btn) => {
			if (tick_type != TickType.OUT) {
				tick_type = TickType.OUT;
				redraw ();
			}
		});

		switch (tick_type) {
			case TickType.NONE:
				tick_type_none_button.active = true;
				break;
			case TickType.BOTH:
				tick_type_both_button.active = true;
				break;
			case TickType.IN:
				tick_type_in_button.active = true;
				break;
			case TickType.OUT:
				tick_type_out_button.active = true;
				break;
		}

		var tick_type_grid = new Gtk.Grid ();
		tick_type_grid.attach (tick_type_none_button, 0, 0);
		tick_type_grid.attach (tick_type_both_button, 1, 0);
		tick_type_grid.attach (tick_type_in_button, 0, 1);
		tick_type_grid.attach (tick_type_out_button, 1, 1);

		var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 15);
		box.pack_start (tick_type_grid, false);
		box.pack_start (frame_0, false);

		var scroll = new Gtk.ScrolledWindow (null, null);
		scroll.add (box);

		stack.add_titled (scroll, group_name, @"Axes $orientation");
	}
}
