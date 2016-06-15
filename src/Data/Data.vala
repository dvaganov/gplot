using GLib;

public class Gplot.Data : Object
{
	protected GenericArray<DataItem> _values;

	public int length
	{
		get
		{
			return this._values.length;
		}
	}

	public Data()
	{
		this._values = new GenericArray<DataItem>();
	}

	public Data addValue(double? val)
	{
		this._values.add(new DataItem(val));
		return this;
	}

	public double? getValue(int index)
	{
		return this._values.get(index).getValue();
	}

	public Data setValue(int index, double? val)
	{
		if (this._values.length > index && index > -1) {
			this._values.set(index, new DataItem(val));
		}
		return this;
	}

	public Data remove(int index)
	{
		this._values.remove_index(index);
		return this;
	}

	public DataItem insertItem(int position, double? val = null)
	{
		var item = new DataItem(val);
		this._values.insert(position, item);
		return item;
	}

	public DataItem getItem(int index)
	{
		return this._values.get(index);
	}

	public DataItem addItem(double? val = null)
	{
		var item = new DataItem(val);
		this._values.add(item);
		return item;
	}
}
