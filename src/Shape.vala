using GLib;
using Gtk;
using Cairo;

public abstract class Gplot.Shape : Element
{
	protected Layer _parent;

	protected Data? _x;
	protected Data? _y;

	public Layer getParent()
	{
		return this._parent;
	}

	public Shape setParent(Layer layer)
	{
		this._parent = layer;
		return this;
	}

	public Data getX()
	{
		return this._x;
	}

	public Data getY()
	{
		return this._y;
	}

	public Shape setX(Data? data)
	{
		this._x = data;
		return this;
	}

	public Shape setY(Data? data)
	{
		this._y = data;
		return this;
	}

	public override void show(Context cr)
	{
		if (this._x != null && this._y != null) {
			base.show(cr);
		}
	}
}
