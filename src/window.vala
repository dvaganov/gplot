using Gtk;

public class Plot.Window : Gtk.ApplicationWindow {
	private View plot_view;

	public Window () {
		var grid = new Grid ();
		add (grid);

		var btn_save = new Button.with_label ("Save");
		btn_save.halign = Align.CENTER;
		btn_save.clicked.connect (() => {
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
		grid.attach (btn_save, 0,0);
		
		var btn_load = new Button.with_label ("Load");
		btn_load.halign = Align.CENTER;
		btn_load.clicked.connect (() => {
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
		grid.attach (btn_load, 1,0);

		var btn_export = new Button.with_label ("Export");
		btn_export.halign = Align.CENTER;
		btn_export.clicked.connect (() => {
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
		grid.attach (btn_export, 2,0);

		var scroll = new ScrolledWindow (null, null);
		scroll.expand = true;
		grid.attach (scroll, 0,1,3);

		plot_view = new View ();
		scroll.add (plot_view);
	}
}
