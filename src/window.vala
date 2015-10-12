using Gtk;

public class Plot.Window : Gtk.ApplicationWindow {
	private View plot_view;
	private Gtk.Stack plot_view_parameters_stack;

	public Window () {
		plot_view = new View ();
		create_actions ();

		// Header bar
		var btn_save = new Button.from_icon_name ("document-save-symbolic");
		btn_save.halign = Align.CENTER;
		btn_save.action_name = "win.save";

		var btn_open = new Button.from_icon_name ("document-open-symbolic");
		btn_open.halign = Align.CENTER;
		btn_open.action_name = "win.open";

		var btn_export = new Button.from_icon_name ("document-save-as-symbolic");
		btn_export.halign = Align.CENTER;
		btn_export.action_name = "win.export";

		var box_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		box_btn.get_style_context ().add_class ("linked");
		box_btn.pack_start (btn_save);
		box_btn.pack_start (btn_open);
		box_btn.pack_start (btn_export);

		// Plot view
		var scroll_plot_view = new Gtk.ScrolledWindow (null, null);
		scroll_plot_view.expand = true;
		scroll_plot_view.min_content_width = 400;
		scroll_plot_view.min_content_height = 400;
		scroll_plot_view.add (plot_view);

		var plot_view_grid = new Gtk.Grid ();
		plot_view_grid.expand = true;
		plot_view_grid.attach (create_plot_view_left_box (), 0, 0);
		plot_view_grid.attach (scroll_plot_view, 1, 0);

		// Table view
		var table_view_grid = new Gtk.Grid ();

		// Window
		var stack = new Gtk.Stack ();
		stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

		var stack_switcher = new Gtk.StackSwitcher ();
		stack_switcher.stack = stack;
		stack.add_titled (plot_view_grid, "plot", "Plot view");
		stack.add_titled (table_view_grid, "table", "Table view");

		var header_bar = new Gtk.HeaderBar ();
		header_bar.show_close_button = true;
		header_bar.pack_start (box_btn);
		header_bar.custom_title = stack_switcher;

		set_titlebar (header_bar);
		add (stack);
	}
	private Gtk.Box create_plot_view_left_box () {
		plot_view_parameters_stack = new Gtk.Stack ();
		plot_view_parameters_stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
		set_plot_view_parameters_stack ();

		var sidebar = new Gtk.StackSidebar ();
		sidebar.stack = plot_view_parameters_stack;

		var frame_sidebar = new Gtk.Frame (null);
		frame_sidebar.shadow_type = Gtk.ShadowType.IN;
		frame_sidebar.valign = Gtk.Align.START;
		frame_sidebar.height_request = 100;
		frame_sidebar.add (sidebar);

		var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 15);
		box.width_request = 300;
		box.margin = 15;
		box.pack_start (frame_sidebar, false, true);
		box.pack_start (plot_view_parameters_stack);

		return box;
	}
	private void set_plot_view_parameters_stack () {
		var path_label = new Gtk.Label ("Path");

		var color_label = new Gtk.Label ("Background color");
		color_label.halign = Gtk.Align.START;

		var color_button = new Gtk.ColorButton.with_rgba (plot_view.color_background);
		color_button.halign = Gtk.Align.END;
		color_button.color_set.connect (() => {
			plot_view.color_background = color_button.rgba;
		});

		var color_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		color_box.margin_start = color_box.margin_end = 15;
		color_box.pack_start (color_label);
		color_box.pack_start (color_button);

		var color_grid_label = new Gtk.Label ("Grid color");
		color_grid_label.halign = Gtk.Align.START;

		var color_grid_button = new Gtk.ColorButton.with_rgba (plot_view.color_grid);
		color_grid_button.halign = Gtk.Align.END;
		color_grid_button.color_set.connect (() => {
			plot_view.color_grid = color_grid_button.rgba;
		});

		var color_grid_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		color_grid_box.margin_start = color_grid_box.margin_end = 15;
		color_grid_box.pack_start (color_grid_label);
		color_grid_box.pack_start (color_grid_button);

		var major_grid_label = new Gtk.Label ("Major grid");
		major_grid_label.halign = Gtk.Align.START;

		var major_grid_switch = new Gtk.Switch ();
		major_grid_switch.halign = Gtk.Align.END;
		major_grid_switch.active = plot_view.has_major_grid;
		major_grid_switch.notify["active"].connect (() => {
			if (major_grid_switch.active) {
				plot_view.has_major_grid = true;
			} else {
				plot_view.has_major_grid = false;
			}
			plot_view.queue_draw ();
		});

		var major_grid_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		major_grid_box.margin_start = major_grid_box.margin_end = 15;
		major_grid_box.pack_start (major_grid_label);
		major_grid_box.pack_start (major_grid_switch);

		var minor_grid_label = new Gtk.Label ("Major grid");
		minor_grid_label.halign = Gtk.Align.START;

		var minor_grid_switch = new Gtk.Switch ();
		minor_grid_switch.halign = Gtk.Align.END;
		minor_grid_switch.active = plot_view.has_major_grid;
		minor_grid_switch.notify["active"].connect (() => {
			if (minor_grid_switch.active) {
				plot_view.has_minor_grid = true;
			} else {
				plot_view.has_minor_grid = false;
			}
			plot_view.queue_draw ();
		});

		var minor_grid_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		minor_grid_box.margin_start = minor_grid_box.margin_end = 15;
		minor_grid_box.pack_start (minor_grid_label);
		minor_grid_box.pack_start (minor_grid_switch);

		var list_box = new Gtk.ListBox ();
		list_box.selection_mode = Gtk.SelectionMode.NONE;
		list_box.add (color_box);
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

		var frame = new Frame (null);
		frame.shadow_type = Gtk.ShadowType.IN;
		frame.valign = Gtk.Align.START;
		frame.add (list_box);

		var scroll = new Gtk.ScrolledWindow (null, null);
		scroll.add (frame);

		var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 15);
		box.pack_start (path_label, false, true);
		box.pack_start (scroll, true, true);

		plot_view_parameters_stack.add_titled (box, "background", "Background");
	}
	private void create_actions () {
		var simple_action = new GLib.SimpleAction ("save", null);
		simple_action.activate.connect (() => {
			var chooser = new Gtk.FileChooserDialog (null, this, Gtk.FileChooserAction.SAVE, null);
			chooser.add_button ("_Cancel", Gtk.ResponseType.CANCEL);
			chooser.add_button ("_Save", Gtk.ResponseType.ACCEPT).get_style_context ().add_class ("suggested-action");
			var filter = new Gtk.FileFilter ();
			filter.set_filter_name ("gplot projects");
			filter.add_pattern ("*.gpj");
			chooser.add_filter (filter);
			if (chooser.run () == Gtk.ResponseType.ACCEPT) {
				var filename = chooser.get_filename ();
				if (!filename.has_suffix (".gpj")) {
					filename += ".gpj";
				}
				KeyFile file = new KeyFile ();
				file.set_list_separator ('=');
				plot_view.save_to_file (file);
				try {
					file.save_to_file (filename);
				} catch (FileError err) {
					print (err.message);
				}
			}
			chooser.close ();
		});
		this.add_action (simple_action);

		simple_action = new GLib.SimpleAction ("open", null);
		simple_action.activate.connect (() => {
			var chooser = new Gtk.FileChooserDialog (null, this, Gtk.FileChooserAction.OPEN, null);
			chooser.add_button ("_Cancel", Gtk.ResponseType.CANCEL);
			chooser.add_button ("_Open", Gtk.ResponseType.ACCEPT).get_style_context ().add_class ("suggested-action");
			var filter = new Gtk.FileFilter ();
			filter.set_filter_name ("gplot projects");
			filter.add_pattern ("*.gpj");
			chooser.add_filter (filter);
			if (chooser.run () == Gtk.ResponseType.ACCEPT) {
				var filename = chooser.get_filename ();
				KeyFile file = new KeyFile ();
				try {
					file.load_from_file (filename, KeyFileFlags.NONE);
				} catch (KeyFileError key_err) {
					print (@"Load file: $(key_err.message)\n");
				} catch (FileError err) {
					print (@"Load file: $(err.message)\n");
				}
				file.set_list_separator ('=');
				plot_view.open_file (file);
			}
			chooser.close ();
		});
		this.add_action (simple_action);

		simple_action = new SimpleAction ("export", null);
		simple_action.activate.connect (() => {
			var chooser = new Gtk.FileChooserDialog (null, this, Gtk.FileChooserAction.SAVE, null);
			chooser.add_button ("_Cancel", Gtk.ResponseType.CANCEL);
			chooser.add_button ("_Save", Gtk.ResponseType.ACCEPT).get_style_context ().add_class ("suggested-action");
			if (chooser.run () == Gtk.ResponseType.ACCEPT) {
				var filename = chooser.get_filename ();
				if (filename.has_suffix (".eps")) {
					plot_view.export_to_eps (filename);
				} else if (filename.has_suffix (".svg")) {
					plot_view.export_to_svg (filename);
				}
			}
			chooser.close ();
		});
		this.add_action (simple_action);
	}
}
