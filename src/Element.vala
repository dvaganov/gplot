using GLib;
using Cairo;

public abstract class Gplot.Element : Object
{
	public bool visible {set; get; default = false;}

	protected abstract void draw(Context cr);

	public virtual void show(Context cr)
	{
		if (this.visible) {
			this.draw(cr);
		}
	}
}
