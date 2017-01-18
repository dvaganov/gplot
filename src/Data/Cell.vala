using GLib;

public class Gplot.Cell : Object
{
	protected double? _val;

	public Cell(double? val = null)
	{
		this._val = val;
	}

	public string getString(string format)
	{
		return (this._val != null) ? format.printf((double) this._val) : "";
	}

	public Cell setString(string s_val)
	{
		double? d_val;
		this._val = (double.try_parse(s_val, out d_val) && s_val != "") ? d_val : null;
		return this;
	}

	public double? getValue()
	{
		return this._val;
	}

	public Cell setValue(double? val)
	{
		this._val = val;
		return this;
	}
}
