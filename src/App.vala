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

		// Init columns
		var columnManager = new ColumnManager();
		columnManager.addColumn().addValue(10).addValue(200);
		columnManager.addColumn().addValue(200).addValue(30);

		// Attach columns widgets
		var grid = builder.get_object("grid_table") as Grid;
		grid.attach(columnManager.getColumn("Column1").getWidget(), 0, 0);
		grid.attach(columnManager.getColumn("Column2").getWidget(), 1, 0);

		// Fill chooser with names
		var data_chooser = builder.get_object("data_chooser") as ComboBoxText;
		var data_names = columnManager.listColumns();

		for (var i = 0; i < data_names.length; i++) {
			data_chooser.append_text(data_names[i]);
		}
		data_chooser.active = 0;

		// Draw line
		var line = new Line();
		line
			.setX(columnManager.getColumn("Column1"))
			.setY(columnManager.getColumn("Column2"));
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
			var name = data_chooser.get_active_text();
			line.setX(columnManager.getColumn(name));
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
