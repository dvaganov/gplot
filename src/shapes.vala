using GLib;
using Cairo;
using Plot;

public abstract class Plot.Shapes : GLib.Object {
	public int id {get; protected set;}
	public int parent_id {get; protected set;}
	public string group_name {get; protected set;}
	public bool is_selected {get; set; default = true;}
	public ulong? motion_handler_id {get; set; default = null;}
	public Array<Point?> points {get; set; default = new Array<Point?> ();}
	public Point scale {get; set; default = Point () {x = 1, y = 1};}
	public Point shift {get; set; default = Point () {x = 0, y = 0};}
	public abstract void save_to_file (KeyFile file);
	public abstract void transform (Gtk.Widget widget, Gdk.EventButton event);
	public abstract void draw (Cairo.Context cr);
	
	public virtual void recalculate_points (Point shift, Point scale) {
		for (int i = 0; i < points.length; i++) {
			// Restore data points
			points.index (i).x -= this.shift.x;
			points.index (i).y -= this.shift.y;
			points.index (i).x /= this.scale.x;
			points.index (i).y /= this.scale.y;
			// Transform data
			points.index (i).x *= scale.x;
			points.index (i).y *= scale.y;
			points.index (i).x += shift.x;
			points.index (i).y += shift.y;
		}
		// Save new shift parameter
		this.shift = shift;
		this.scale = scale;
	}
}
