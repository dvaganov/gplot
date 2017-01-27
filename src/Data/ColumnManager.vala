using GLib;
using Gee;

public class Gplot.ColumnManager : Object
{
	protected HashMap<uint, Column> _columns_gee;
	protected HashMap<string, uint> _columnsNames;

	public ColumnManager()
	{
		this._columns_gee = new HashMap<uint, Column>();
		this._columnsNames = new HashMap<string, uint>();
	}

	public string?[] listColumns()
	{
		return this._columnsNames.keys.to_array();
	}

	public Column getColumn(string name)
	{
		var columnID = this._columnsNames.get(name);
		return this._columns_gee.get(columnID);
	}

	public Column addColumn(string? id = null, double?[]? values = null)
	{
		var column = new Column();

		this._columns_gee.set(column.getID(), column);
		this._columnsNames.set(column.getName(), column.getID());

		if (values != null) {
			for (var i = 0; i < values.length; i++) {
				column.addValue(values[i]);
			}
		}

		return column;
	}
}
