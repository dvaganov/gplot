using GLib;
using Gtk;

[GtkTemplate (ui = "/org/gplot/table.ui")]
public class Gplot.ColumnView : TreeView
{
	protected Column _column;
	protected SimpleActionGroup _action_group;

	[GtkChild]
	protected TreeViewColumn column_id;
	[GtkChild]
	protected TreeViewColumn column_values;
	[GtkChild]
	protected Popover popover_rename;
	[GtkChild]
	protected Entry entry_rename;
	[GtkChild]
	protected Gtk.Menu menu;

	public string title
	{
		set;
		get;
		default = "Values";
	}

	public string precise
	{
		set;
		get;
		default = "%.2f";
	}

	public ColumnView(Column column)
	{
		this._column = column;
		this.menu.attach_widget = this;
		this.setupActions();

		this.column_id.set_cell_data_func(
			this.column_id.get_cells().first().data,
			(cell_layout, cell, tree_model, iter) => {
				var cell_text = cell as CellRendererText;

				var s_num = tree_model.get_string_from_iter(iter);

				cell_text.text = (int.parse(s_num) + 1).to_string();
			}
		);

		this.column_values.set_cell_data_func(
			this.column_values.get_cells().first().data,
			(cell_layout, cell, tree_model, iter) => {
				var cell_text = cell as Gtk.CellRendererText;

				Object obj;
				tree_model.get(iter, 0, out obj);

				var row = obj as Cell;
				cell_text.text = row.getString("%.2f");
			}
		);

		this.column_values.title = this.title;
		this.column_values.bind_property("title", this, "title", BindingFlags.BIDIRECTIONAL);

		this.entry_rename.text = this.column_values.title;
		this.entry_rename.bind_property("text", this.column_values, "title", BindingFlags.BIDIRECTIONAL);

		this.popover_rename.relative_to = this.column_values.get_button();
	}

	public void insert(int position = -1)
	{
		Gtk.TreeIter iter;
		var row = this._column.insert(position);
		print(this.title + ": insert()\n");
		var model = this.model as Gtk.ListStore;

		model.insert(out iter, position);
		model.set(iter, 0, row);
	}

	public void removeRow()
	{
		TreeIter iter;
		this.get_selection().get_selected(null, out iter);

		var model = this.model as Gtk.ListStore;
		var row_index = int.parse(model.get_string_from_iter(iter));

		this._column.remove(row_index);
		model.remove(iter);
	}

	[GtkCallback]
	private void onTitlePress()
	{
		if (this.popover_rename.visible) {
			this.popover_rename.visible = false;
		} else {
			this.popover_rename.visible = true;
		}
	}

	[GtkCallback]
	private void onTitleChanged()
	{
		this.popover_rename.visible = false;
	}

	[GtkCallback]
	private bool onButtonPress(Gdk.EventButton event)
	{
		if ((event.type == Gdk.EventType.BUTTON_PRESS) && (event.button == 3)) {
			var rect = Gdk.Rectangle();

			Gtk.TreePath path;
			this.get_bin_window().get_device_position(event.device, out rect.x, out rect.y, null);
			this.get_path_at_pos(rect.x, rect.y, out path, null, null, null);

			if (path != null) {
				this.set_cursor(path, null, false);
				this.menu.popup(null, null, null, event.button, event.time);
			}
		}
		return false;
	}

	[GtkCallback]
	private void onCellEdited(string path, string new_text)
	{
		Gtk.TreeIter iter;
		var index = int.parse(path);
		var model = this.model as Gtk.ListStore;

		model.get_iter_from_string(out iter, path);

		this._column.getCell(index).setString(new_text);

		if (model.iter_next(ref iter)) {
			this.set_cursor(model.get_path(iter), null, true);
		} else {
			this.insert();
			model.get_iter_from_string(out iter, path);
			model.iter_next(ref iter);
			this.set_cursor(model.get_path(iter), null, true);
		}
	}

	protected void setupActions()
	{
		this._action_group = new SimpleActionGroup();

		this._action_group = new SimpleActionGroup();
		this.insert_action_group("column", this._action_group);

		var action = new GLib.SimpleAction("add", null);
		action.activate.connect(
			() => {
				this.insert();
			}
		);
		this._action_group.add_action(action);

		action = new GLib.SimpleAction("add-above", null);
		action.activate.connect(
			() => {
				TreeIter iter;
				this.get_selection().get_selected(null, out iter);

				this.insert(int.parse(this.model.get_string_from_iter(iter)));
			}
		);
		this._action_group.add_action(action);

		action = new GLib.SimpleAction("add-below", null);
		action.activate.connect(
			() => {
				TreeIter iter;
				this.get_selection().get_selected(null, out iter);

				this.insert(int.parse(this.model.get_string_from_iter(iter)) + 1);
			}
		);
		this._action_group.add_action(action);

		action = new GLib.SimpleAction("delete", null);
		action.activate.connect(this.removeRow);
		this._action_group.add_action(action);
	}

	public void syncData()
	{
		for (var i = 0; i < this._column.length; i++) {
			Gtk.TreeIter iter;
			var model = this.model as Gtk.ListStore;
			model.append(out iter);
			model.set(iter, 0, this._column.getCell(i));
		}
	}
}
