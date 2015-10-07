using Gtk;

public class Plot.Window : Gtk.ApplicationWindow {
	private View plot_view;

	public Window () {
		var grid = new Grid ();
		add (grid);

		var button2 = new Button.with_label ("Save");
		button2.halign = Align.CENTER;
		button2.clicked.connect (() => {
			var chooser = new Gtk.FileChooserDialog (null, this, Gtk.FileChooserAction.SAVE, null);
			chooser.add_button ("_Cancel", Gtk.ResponseType.CANCEL);
			chooser.add_button ("_Save", Gtk.ResponseType.ACCEPT).get_style_context ().add_class ("suggested-action");
			if (chooser.run () == Gtk.ResponseType.ACCEPT) {
				var filename = chooser.get_filename ();
				KeyFile file = new KeyFile ();
				file.set_list_separator ('=');
				plot_view.save_to_file (file);
				try {
					file.save_to_file (filename);
				} catch (FileError err) {
					print (err.message);
				}
				//print (plot_view.axes[0].save ());
			}
			chooser.close ();
		});
		grid.attach (button2, 0,0);

		var button = new Button.with_label ("Export");
		button.halign = Align.CENTER;
		button.clicked.connect (() => {
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
		grid.attach (button, 1,0);

		var scroll = new ScrolledWindow (null, null);
		scroll.expand = true;
		grid.attach (scroll, 0,1,2);

		plot_view = new View ();
		scroll.add (plot_view);
	}
}
