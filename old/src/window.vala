public class Plot.Window : Gtk.ApplicationWindow {
	private Plot.View plot_view;

	public Window () {
		plot_view = new View ();
		create_actions ();

		// Window
		var win_stack = new Gtk.Stack ();
		win_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
		add (win_stack);

		var stack_switcher = new Gtk.StackSwitcher ();
		stack_switcher.stack = win_stack;

		var header_bar = new Gtk.HeaderBar ();
		header_bar.show_close_button = true;
		header_bar.custom_title = stack_switcher;
		set_titlebar (header_bar);

		// Header bar
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		box.get_style_context ().add_class ("linked");
		header_bar.pack_start (box);

		var button = new Gtk.Button.from_icon_name ("document-save-symbolic");
		button.halign = Gtk.Align.CENTER;
		button.action_name = "win.save";
		box.pack_start (button);

		button = new Gtk.Button.from_icon_name ("document-open-symbolic");
		button.halign = Gtk.Align.CENTER;
		button.action_name = "win.open";
		box.pack_start (button);

		button = new Gtk.Button.from_icon_name ("document-save-as-symbolic");
		button.halign = Gtk.Align.CENTER;
		button.action_name = "win.export";
		box.pack_start (button);

		// Plot view
		var grid = new Gtk.Grid ();
		win_stack.add_titled (grid, "plot", "Plot view");
        // Plot view - Parameters
		var parameters_grid = new Gtk.Grid ();
		parameters_grid.expand = false;
		parameters_grid.width_request = 300;
		parameters_grid.margin = 15;
		parameters_grid.row_spacing = 15;
		grid.attach (parameters_grid, 0, 0);

		var frame = new Gtk.Frame (null);
		frame.shadow_type = Gtk.ShadowType.IN;
		frame.expand = true;
		parameters_grid.attach (frame, 0, 0);

		var side_bar = new Gtk.StackSidebar ();
		frame.add (side_bar);

		var stack = new Gtk.Stack ();
		stack.expand = true;
		stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
		side_bar.stack = stack;
		plot_view.settings (stack);
		parameters_grid.attach (stack, 0, 1);

        // Plot view - Plot
		var scrolled_window = new Gtk.ScrolledWindow (null, null);
		scrolled_window.expand = true;
		scrolled_window.min_content_width = 400;
		scrolled_window.min_content_height = 400;
		scrolled_window.add (plot_view);
		grid.attach (scrolled_window, 1, 0);

        // Plot view - Adder
		scrolled_window = new Gtk.ScrolledWindow (null, null);
		scrolled_window.width_request = 300;
		grid.attach (scrolled_window, 2, 0);

		box = new Gtk.Box (Gtk.Orientation.VERTICAL, 15);
		box.margin = 15;
        scrolled_window.add (box);

		button = new Gtk.Button.with_label ("Add curve");
		button.clicked.connect ((widget) => {
			plot_view.layers.get (0).add_shape (ShapeType.CURVE);
		});
		box.pack_start (button);

		button = new Gtk.Button.with_label ("Add scatters");
		button.clicked.connect ((widget) => {
			plot_view.layers.get (0).add_shape (ShapeType.SCATTERS);
		});
		box.pack_start (button);

		// Table view
		grid = new Gtk.Grid ();
		win_stack.add_titled (grid, "table", "Table view");

		button = new Gtk.Button.with_label ("Import");
		button.halign = button.valign = Gtk.Align.CENTER;
		button.expand = true;
		button.action_name = "win.import";
		grid.attach (button, 0, 0);
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

		simple_action = new GLib.SimpleAction ("import", null);
		simple_action.activate.connect (() => {
			var chooser = new Gtk.FileChooserDialog (null, this, Gtk.FileChooserAction.OPEN, null);
			chooser.add_button ("_Cancel", Gtk.ResponseType.CANCEL);
			chooser.add_button ("_Open", Gtk.ResponseType.ACCEPT).get_style_context ().add_class ("suggested-action");
			var filter = new Gtk.FileFilter ();
			filter.set_filter_name ("CSV files");
			filter.add_pattern ("*.csv");
			chooser.add_filter (filter);
			if (chooser.run () == Gtk.ResponseType.ACCEPT) {
				var filename = chooser.get_filename ();
				/*KeyFile file = new KeyFile ();
				try {
					file.load_from_file (filename, KeyFileFlags.NONE);
				} catch (KeyFileError key_err) {
					print (@"Load file: $(key_err.message)\n");
				} catch (FileError err) {
					print (@"Load file: $(err.message)\n");
				}
				file.set_list_separator ('=');
				plot_view.open_file (file);*/
				print (@"Recive $filename\n");
			}
			chooser.close ();
		});
		this.add_action (simple_action);
	}
}
