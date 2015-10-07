using Gtk;

public class Plot.Window : Gtk.ApplicationWindow {
	private View plot_view;
	
	public Window () {
		var grid = new Grid ();
		add (grid);
		
		var button = new Button.with_label ("Click!");
		button.halign = Align.CENTER;
		button.clicked.connect (() => {
			plot_view.export_to_eps ("output.eps");
		});
		grid.attach (button, 0,0);
		
		var scroll = new ScrolledWindow (null, null);
		scroll.expand = true;
		grid.attach (scroll, 0,1);
		
		plot_view = new View ();
		scroll.add (plot_view);
	}
}
