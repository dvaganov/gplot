using GLib;

public class Gplot.ColumnManager : Object
{
	protected GenericArray<Column> _columns;
	protected GenericArray<ColumnView> _views;
	protected GenericArray<string?> _id;

	public ColumnManager()
	{
		this._columns = new GenericArray<Column>();
		this._views = new GenericArray<ColumnView>();
		this._id = new GenericArray<string?>();
	}

	public string?[] listColumns()
	{
		return this._id.data;
	}

	public ColumnView getColumnView(string id)
	{
		var view = this._views.get(this.searchColumn(id));

		if (view != null) {
			view.syncData();
			view.insert();
		}

		return view;
	}

	public Column getColumn(string id)
	{
		return this._columns.get(this.searchColumn(id));
	}

	public Column addColumn(string? id = null, double?[]? values = null)
	{
		// Default column id is equal to length of entries + 1
		id = (id == null) ? (this._id.length + 1).to_string() : id;

		var column = new Column();
		var data_view = new ColumnView(column);

		data_view.title = id;

		this._columns.add(column);
		this._views.add(data_view);
		this._id.add(id);

		if (values != null) {
			for (var i = 0; i < values.length; i++) {
				column.addValue(values[i]);
			}
		}

		return column;
	}

	protected int searchColumn(string id)
	{
		var i = 0;
		for (i = 0; i < this._id.length; i++) {
			if (id == this._id.get(i)) {
				break;
			}
		}
		return i;
	}
}
