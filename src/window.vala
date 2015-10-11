using Gtk;

public class Plot.Window : Gtk.ApplicationWindow {
	private View plot_view;

	public Window () {
		plot_view = new View ();
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
		box_plot_left.margin = 10;
		pane_plot.pack1 (box_plot_left, true, false);

		var stack_switcher_plot_left = new Gtk.StackSwitcher ();
		stack_switcher_plot_left.valign = Gtk.Align.START;
		stack_switcher_plot_left.halign = Gtk.Align.CENTER;
		box_plot_left.pack_start (stack_switcher_plot_left, false, false);

		// Plot: Left: Parameters
		var stack_plot_left = new Stack ();
		stack_switcher_plot_left.stack = stack_plot_left;
		stack_plot_left.hhomogeneous = true;
		stack_plot_left.width_request = 300;
		stack_plot_left.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
		stack_plot_left.margin_top = stack_plot_left.margin_bottom = 20;
		box_plot_left.pack_start (stack_plot_left, true, true);

		var box_parameters = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		box_parameters.expand = true;
		stack_plot_left.add_titled (box_parameters, "parameters", "Parameters");

		create_section_selection (box_parameters);
		
		var param1 = new Gtk.Label ("Zero point");
		box_parameters.pack_start (param1, false, false);

		var ent_param1 = new Gtk.Entry ();
		ent_param1.activate.connect ((widget) => {
			plot_view.layers.get (0).top_left_point = Point.from_string (widget.text);
			plot_view.queue_draw ();
		});
		box_parameters.pack_start (ent_param1, false, false);

		var param2 = new Gtk.Label ("Width:");
		box_parameters.pack_start (param2, false, false);

		var ent_param2 = new Gtk.Entry ();
		ent_param2.activate.connect ((widget) => {
			plot_view.layers.get (0).width = int.parse (widget.text);
			plot_view.queue_draw ();
		});
		box_parameters.pack_start (ent_param2, false, false);

		// Plot: Left: Adds
		var box_add_elements = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		box_add_elements.expand = true;
		stack_plot_left.add_titled (box_add_elements, "elements", "Add elements");

		var btn_add_curve = new Gtk.Button.with_label ("Add curve");
		btn_add_curve.clicked.connect (() => {
			plot_view.layers.get (0).add_shape (Plot.ShapeType.CURVE);
			plot_view.queue_draw ();
		});
		box_add_elements.pack_start (btn_add_curve, true, false);
		
		var btn_add_scatters = new Gtk.Button.with_label ("Add scatters");
		btn_add_scatters.clicked.connect (() => {
			plot_view.layers.get (0).add_shape (Plot.ShapeType.SCATTERS);
			plot_view.queue_draw ();
		});
		box_add_elements.pack_start (btn_add_scatters, true, false);

		var scroll = new ScrolledWindow (null, null);
		scroll.expand = true;
		pane_plot.pack2 (scroll, true, false);

		scroll.min_content_width = 500;
		scroll.min_content_height = 500;
		scroll.add (plot_view);

		var grid_table = new Gtk.Grid ();
		stack.add_titled (grid_table, "table", "Table view");
	}
	private void create_section_selection (Gtk.Box box) {
		var box_selection = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
		box.pack_start (box_selection, false, false);
		
		var label_layers = new Label ("<b>Layers</b>");
		label_layers.use_markup = true;
		label_layers.halign = Gtk.Align.START;
		box_selection.pack_start (label_layers);
		
		var frame_layers = new Gtk.Frame (null);
		frame_layers.shadow_type = Gtk.ShadowType.IN;
		box_selection.pack_start (frame_layers, false, false);
		
		var list_box_layers = new Gtk.ListBox ();
		list_box_layers.activate_on_single_click = true;
		list_box_layers.selection_mode = Gtk.SelectionMode.SINGLE;
		Gtk.Label label;
		for (var i = 0; i < plot_view.layers.length; i++) {
			label = new Gtk.Label (@"Layer $(plot_view.layers.get (i).id)");
			list_box_layers.add (label);
		}
		frame_layers.add (list_box_layers);
		
		var label_axes = new Label ("<b>Axes</b>");
		label_axes.use_markup = true;
		label_axes.halign = Gtk.Align.START;
		box_selection.pack_start (label_axes);
		
		var frame_axes = new Gtk.Frame (null);
		frame_axes.shadow_type = Gtk.ShadowType.IN;
		box_selection.pack_start (frame_axes, false, false);
		
		var list_box_axes = new Gtk.ListBox ();
		list_box_axes.activate_on_single_click = true;
		list_box_axes.selection_mode = Gtk.SelectionMode.SINGLE;
		for (var i = 0; i < plot_view.layers.get (0).axes.length; i++) {
			label = new Gtk.Label (@"Axes $(i)");
			list_box_axes.add (label);
		}
		frame_axes.add (list_box_axes);
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
