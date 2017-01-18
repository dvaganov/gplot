using GLib;
using Gtk;
using Cairo;

public abstract class Gplot.Shape : Element
{
	protected Layer _parent;

	protected Column? _x;
	protected Column? _y;

	public Layer getParent()
	{
		return this._parent;
	}

	public Shape setParent(Layer layer)
	{
		this._parent = layer;
		return this;
	}

	public Column getX()
	{
		return this._x;
	}

	public Column getY()
	{
		return this._y;
	}

	public Shape setX(Column? column)
	{
		this._x = column;
		return this;
	}

	public Shape setY(Column? column)
	{
		this._y = column;
		return this;
	}

	public override void show(Context cr)
	{
		if (this._x != null && this._y != null) {
			base.show(cr);
		}
	}
}
