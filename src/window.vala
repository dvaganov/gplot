using Gtk;

public class Plot.Window : Gtk.ApplicationWindow {
	private View plot_view;

	public Window () {
		create_actions ();

		var header_bar = new Gtk.HeaderBar ();
		header_bar.show_close_button = true;
		set_titlebar (header_bar);

		var box_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		box_btn.get_style_context ().add_class ("linked");
		header_bar.pack_start (box_btn);

		var btn_save = new Button.from_icon_name ("document-save-symbolic");
		btn_save.halign = Align.CENTER;
		btn_save.action_name = "win.save";
		box_btn.pack_start (btn_save);

		var btn_open = new Button.from_icon_name ("document-open-symbolic");
		btn_open.halign = Align.CENTER;
		btn_open.action_name = "win.open";
		box_btn.pack_start (btn_open);

		var btn_export = new Button.from_icon_name ("document-save-as-symbolic");
		btn_export.halign = Align.CENTER;
		btn_export.action_name = "win.export";
		box_btn.pack_start (btn_export);

		var stack_switcher = new Gtk.StackSwitcher ();
		header_bar.custom_title = stack_switcher;

		var stack = new Gtk.Stack ();
		stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
		stack_switcher.stack = stack;
		add (stack);

		// Plot view
		var pane_plot = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
		stack.add_titled (pane_plot, "plot", "Plot view");

		var box_plot_left = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		pane_plot.pack1 (box_plot_left, true, false);

		var stack_switcher_plot_left = new Gtk.StackSwitcher ();
		stack_switcher_plot_left.valign = Gtk.Align.START;
		stack_switcher_plot_left.halign = Gtk.Align.CENTER;
		box_plot_left.pack_start (stack_switcher_plot_left, false, false);

		// Plot: Left: Parameters and Adds
		var stack_plot_left = new Stack ();
		stack_switcher_plot_left.stack = stack_plot_left;
		stack_plot_left.hhomogeneous = true;
		stack_plot_left.width_request = 300;
		stack_plot_left.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
		box_plot_left.pack_start (stack_plot_left, true, true);

		var box_parameters = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		box_parameters.expand = true;
		stack_plot_left.add_titled (box_parameters, "parameters", "Parameters");

		var param1 = new Gtk.Label ("Zero point");
		box_parameters.pack_start (param1, false, false);

		var ent_param1 = new Gtk.Entry ();
		ent_param1.activate.connect ((widget) => {
			plot_view.layers.index (0).zero_point = Point.from_string (widget.text);
			plot_view.queue_draw ();
		});
		box_parameters.pack_start (ent_param1, false, false);

		var param2 = new Gtk.Label ("Width:");
		box_parameters.pack_start (param2, false, false);

		var ent_param2 = new Gtk.Entry ();
		ent_param2.activate.connect ((widget) => {
			plot_view.layers.index (0).width = int.parse (widget.text);
			plot_view.queue_draw ();
		});
		box_parameters.pack_start (ent_param2, false, false);

		var box_add_elements = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		box_add_elements.expand = true;
		stack_plot_left.add_titled (box_add_elements, "elements", "Add elements");

		var label2 = new Gtk.Label ("Add elements");
		box_add_elements.pack_start (label2, true, false);

		var scroll = new ScrolledWindow (null, null);
		scroll.expand = true;
		pane_plot.pack2 (scroll, true, false);

		plot_view = new View ();
		scroll.min_content_width = 500;
		scroll.min_content_height = 500;
		scroll.add (plot_view);

		var grid_table = new Gtk.Grid ();
		stack.add_titled (grid_table, "table", "Table view");
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
					stdout.printf ("Load file: %s\n", key_err.message);
				} catch (FileError err) {
					stdout.printf ("Load file: %s\n", err.message);
				}
				file.set_list_separator ('=');
				plot_view.load_from_file (file);
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
