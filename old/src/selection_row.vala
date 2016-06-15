using GLib;
using Gtk;
using Plot;

public class Plot.SelectionRow : Gtk.ListBoxRow {
	public SelectionRow.titled (string title) {
		activatable = false;
		selectable = false;
		can_focus = false;
		var label = new Gtk.Label (title);
		label.use_markup = true;
		add (label);
	}
}
