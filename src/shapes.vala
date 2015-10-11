using GLib;
using Cairo;
using Plot;

public abstract class Plot.Shapes : GLib.Object {
	public uint id {get; protected set;}
	public uint parent_id {get; protected set;}
	public string group_name {get; protected set;}
	public bool is_selected {get; set; default = true;}
	public ulong? motion_handler_id {get; set; default = null;}
	public GenericArray<Point?> points {get; set; default = new GenericArray<Point?> ();}
	public Point scale {get; set; default = Point () {x = 1, y = 1};}
	public Point shift {get; set; default = Point () {x = 0, y = 0};}
	public abstract void save_to_file (KeyFile file);
	public abstract void transform (Gtk.Widget widget, Gdk.EventButton event);
	public abstract void draw (Cairo.Context cr);
	
	public virtual void recalculate_points (Point shift, Point scale) {
		for (var i = 0; i < points.length; i++) {
			// Restore data points
			points.get (i).x -= this.shift.x;
			points.get (i).y -= this.shift.y;
			points.get (i).x /= this.scale.x;
			points.get (i).y /= this.scale.y;
			// Transform data
			points.get (i).x *= scale.x;
			points.get (i).y *= scale.y;
			points.get (i).x += shift.x;
			points.get (i).y += shift.y;
		}
		this.shift = shift;
		this.scale = scale;
	}
}
