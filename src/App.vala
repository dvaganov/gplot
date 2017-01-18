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

		var data_manager = new ColumnManager();
		data_manager.addColumn().addValue(10).addValue(200);
		data_manager.addColumn().addValue(200).addValue(30);

		var grid = builder.get_object("grid_table") as Grid;
		grid.attach(data_manager.getColumnView("1"), 0, 0);
		grid.attach(data_manager.getColumnView("2"), 1, 0);

		var data_chooser = builder.get_object("data_chooser") as ComboBoxText;
		var data_names = data_manager.listColumns();

		for (var i = 0; i < data_names.length; i++) {
			data_chooser.append_text(data_names[i]);
		}

		var line = new Line();
		line
			.setX(data_manager.getColumn("1"))
			.setY(data_manager.getColumn("2"));
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
			line.setX(data_manager.getColumn(entry));
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
