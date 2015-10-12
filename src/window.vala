using Gtk;

public class Plot.Window : Gtk.ApplicationWindow {
	private Plot.View plot_view;
	// Background parameters
//	private Gtk.Label path_background_label;
//	private Gtk.ColorButton color_background_button;
//	private Gtk.ColorButton color_grid_button;
//	private Gtk.Switch major_grid_switch;
//	private Gtk.Switch minor_grid_switch;
//	// Layers parameters
//	private color_background;
//	private color_border;
//	private width;
//	private height;
//	private margin;
//	private top_left_point;
//	private units;

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
		var plot_view_parameters_stack = new Gtk.Stack ();
		plot_view_parameters_stack.expand = true;
		plot_view_parameters_stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;

		var plot_view_parameres_sidebar = new Gtk.StackSidebar ();
		plot_view_parameres_sidebar.stack = plot_view_parameters_stack;

		var plot_view_parameters_sidebar_frame = new Gtk.Frame (null);
		plot_view_parameters_sidebar_frame.shadow_type = Gtk.ShadowType.IN;
		plot_view_parameters_sidebar_frame.expand = false;
		plot_view_parameters_sidebar_frame.valign = Gtk.Align.START;
		plot_view_parameters_sidebar_frame.height_request = 100;
		plot_view_parameters_sidebar_frame.add (plot_view_parameres_sidebar);

		var plot_view_parameters_grid = new Gtk.Grid ();
		plot_view_parameters_grid.expand = false;
		plot_view_parameters_grid.width_request = 300;
		plot_view_parameters_grid.margin = 15;
		plot_view_parameters_grid.row_spacing = 15;
		plot_view_parameters_grid.attach (plot_view_parameters_sidebar_frame, 0, 0);
		plot_view_parameters_grid.attach (plot_view_parameters_stack, 0, 1);
		
		var plot_view_scroll = new Gtk.ScrolledWindow (null, null);
		plot_view_scroll.expand = true;
		plot_view_scroll.min_content_width = 400;
		plot_view_scroll.min_content_height = 400;
		plot_view_scroll.add (plot_view);

		var plot_view_grid = new Gtk.Grid ();
		plot_view_grid.attach (plot_view_parameters_grid, 0, 0);
		plot_view_grid.attach (plot_view_scroll, 1, 0);
		
		plot_view.settings (plot_view_parameters_stack);
		for (var i = 0; i < plot_view.layers.length; i++) {
			plot_view.layers.get (i).settings (plot_view_parameters_stack);
		}

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
