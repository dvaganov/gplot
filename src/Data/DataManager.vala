using GLib;

public class Gplot.DataManager : Object
{
	protected GenericArray<Data> _data;
	protected GenericArray<DataView> _views;
	protected GenericArray<string?> _names;

	public DataManager()
	{
		this._data = new GenericArray<Data>();
		this._views = new GenericArray<DataView>();
		this._names = new GenericArray<string?>();
	}

	public string?[] getDataNames()
	{
		return this._names.data;
	}

	public DataView getDataView(string name)
	{
		var view = this._views.get(this.getIndex(name));
		view.syncData();
			view.insert();
		return view;
	}

	public Data getData(string name)
	{
		return this._data.get(this.getIndex(name));
	}

	public Data newData(string name)
	{
		var data = new Data();
		var data_view = new DataView(data);

		data_view.title = name;

		this._data.add(data);
		this._views.add(data_view);
		this._names.add(name);

		return data;
	}

	public Data newDataFromArray(string name, double?[] values)
	{
		var data = this.newData(name);

		for (var i = 0; i < values.length; i++) {
			data.addValue(values[i]);
		}

		return data;
	}

	protected int getIndex(string name)
	{
		var i = 0;
		for (; i < this._names.length; i++) {
			if (name == this._names.get(i)) {
				break;
			}
		}
		return i;
	}
}
