using GLib;

public class Gplot.DataItem : Object, DataString
{
	protected double? _val;

	public DataItem(double? val = null)
	{
		this._val = val;
	}

	public string getString(string format)
	{
		return (this._val != null) ? format.printf((double) this._val) : "";
	}

	public DataString setString(string s_val)
	{
		double? d_val;
		this._val = (double.try_parse(s_val, out d_val) && s_val != "") ? d_val : null;
		return this;
	}

	public double? getValue()
	{
		return this._val;
	}

	public DataItem setValue(double? val)
	{
		this._val = val;
		return this;
	}
}
