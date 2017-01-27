using GLib;

public class Gplot.Column : Object
{
	protected static uint columnID = 1;

	protected uint _id;
	protected string _name;
	protected ColumnView _widget;
	protected GenericArray<Cell> _values;

	public int length
	{
		get
		{
			return this._values.length;
		}
	}

	public Column()
	{
		this._id = Column.columnID++;
		this._name = "Column" + this._id.to_string();
		this._widget = new ColumnView(this);
		this._values = new GenericArray<Cell>();
	}

	public uint getID()
	{
		return this._id;
	}

	public string getName()
	{
		return this._name;
	}

	public ColumnView getWidget()
	{
		this._widget.syncData();
		this._widget.insert();
		return this._widget;
	}

	public Column addValue(double? val = null)
	{
		this._values.add(new Cell(val));
		return this;
	}

	public double? getValue(int index)
	{
		return this._values.get(index).getValue();
	}

	public Column setValue(int index, double? val)
	{
		if (this._values.length > index && index > -1) {
			this._values.set(index, new Cell(val));
		}
		return this;
	}

	public Column remove(int index)
	{
		this._values.remove_index(index);
		return this;
	}

	public Cell insert(int position = -1, double? val = null)
	{
		var item = new Cell(val);
		this._values.insert(position, item);
		return item;
	}

	public Cell getCell(int index)
	{
		return this._values.get(index);
	}
}
