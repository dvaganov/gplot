using Gtk;

public class Gplot.App : Gtk.Application
{
	public App(string[] args)
	{
		Object(application_id: "org.gplot");
	}

	protected override void activate()
	{
		var builder = new Builder.from_resource("/org/gplot/window.ui");
		var win = builder.get_object("window") as ApplicationWindow;

		win.set_titlebar(builder.get_object("header_bar") as Widget);

		var data_manager = new DataManager();
		data_manager.newData("x").addValue(10).addValue(200);
		data_manager.newData("y").addValue(200).addValue(30);

		var grid = builder.get_object("grid_table") as Grid;
		grid.attach(data_manager.getDataView("x"), 0, 0);
		grid.attach(data_manager.getDataView("y"), 1, 0);

		var data_chooser = builder.get_object("data_chooser") as ComboBoxText;
		var data_names = data_manager.getDataNames();
		for (var i = 0; i < data_names.length; i++) {
			data_chooser.append_text(data_names[i]);
		}

		var line = new Line();
		line
			.setX(data_manager.getData("x"))
			.setY(data_manager.getData("y"));
		line.visible = true;

		var layer = new Layer();
		layer.visible = true;
		layer.addChild(line);

		var view = builder.get_object("view") as DrawingArea;
		view.draw.connect((cr) => {
			layer.show(cr);
			return true;
		});

		data_chooser.changed.connect(() => {
			var entry = data_chooser.get_active_text();
			line.setX(data_manager.getData(entry));
			view.queue_draw();
		});

		win.show_all();

		this.add_window(win);
	}

	public static int main(string[] args)
	{
		var app = new App(args);
		return app.run(args);
	}
}
