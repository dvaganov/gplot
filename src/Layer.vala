using GLib;
using Cairo;

public class Gplot.Layer : Element
{
	private GenericArray<Element> _children;

	public Layer()
	{
		this._children = new GenericArray<Element>();
	}

	protected override void draw(Context cr)
	{
		for (var i = 0; i < this._children.length; i++) {
			this._children.get(i).show(cr);
		}
	}

	public Layer addChild(Element child)
	{
		this._children.add(child);
		return this;
	}
}
