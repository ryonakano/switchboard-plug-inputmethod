/*
* Copyright (c) 2019 Ryo Nakano
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

public class InputMethod.EnginesListView : Gtk.Grid {
    // Stores all installed engines
    private List<IBus.EngineDesc> engines = new IBus.Bus ().list_engines ();

    private string[] _active_engines;
    // Stores currently activated engines
    public string[] active_engines {
        get {
            _active_engines = InputMethod.Plug.ibus_general_settings.get_strv ("preload-engines");
            return _active_engines;
        }
        set {
            InputMethod.Plug.ibus_general_settings.set_strv ("preload-engines", value);
            InputMethod.Plug.ibus_general_settings.set_strv ("engines-order", value);
        }
    }

    // Stores names of currently activated engines
    private string[] engine_full_names;
    private Gtk.ListBox listbox;

    public EnginesListView () {
        Object (
            column_spacing: 12,
            row_spacing: 12
        );
    }

    construct {
        var display = new Gtk.Frame (null);

        listbox = new Gtk.ListBox ();

        update_engines_list ();

        var scroll = new Gtk.ScrolledWindow (null, null);
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.expand = true;
        scroll.add (listbox);

        var add_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON);
        add_button.tooltip_text = _("Add…");

        var remove_button = new Gtk.Button.from_icon_name ("list-remove-symbolic", Gtk.IconSize.BUTTON);
        remove_button.tooltip_text = _("Remove");

        var actionbar = new Gtk.ActionBar ();
        actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        actionbar.add (add_button);
        actionbar.add (remove_button);

        var grid = new Gtk.Grid ();
        grid.attach (scroll, 0, 0, 1, 1);
        grid.attach (actionbar, 0, 1, 1, 1);

        display.add (grid);
        add (display);

        var pop = new AddEnginesPopover (add_button);
        add_button.clicked.connect (() => {
            pop.show_all ();
        });

        pop.add_engine.connect ((engine) => {
            string[] new_engine_list = active_engines;
            new_engine_list += engine;
            active_engines = new_engine_list;
            update_engines_list ();
            pop.hide ();
        });

        remove_button.clicked.connect (() => {
            int index = listbox.get_selected_row ().get_index ();
            string[] new_engines = active_engines;
            new_engines[index] = "";
            active_engines = new_engines;
            update_engines_list ();
        });
    }

    private void update_engines_list () {
        listbox.get_children ().foreach ((listbox_child) => {
            listbox_child.destroy ();
            engine_full_names = {};
        });

        // Add the language and the name of activated engines
        foreach (var engine in engines) {
            foreach (var active_engine in active_engines) {
                if (engine.name == active_engine) {
                    engine_full_names += "%s - %s".printf (IBus.get_language_name (engine.language),
                                                    Utils.gettext_engine_longname (engine));
                }
            }
        }

        foreach (var engine_full_name in engine_full_names) {
            var listboxrow = new Gtk.ListBoxRow ();

            var label = new Gtk.Label (engine_full_name);
            label.margin = 6;
            label.halign = Gtk.Align.START;

            listboxrow.add (label);
            listbox.add (listboxrow);
        }

        listbox.show_all ();
    }
}