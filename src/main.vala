using Gtk;

public class Plot.App : Gtk.Application {
	public App (string[] args) {
		Object(application_id: "home.dvaganov.gplot");
	}
	protected override void activate () {
		var win = new Window ();
		add_window (win);
		win.show_all();
	}

	public static int main (string[] args) {
		var app = new App (args);
		return app.run (args);
	}
}
