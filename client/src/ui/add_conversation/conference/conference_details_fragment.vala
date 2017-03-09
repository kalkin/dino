using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.AddConversation.Conference {

[GtkTemplate (ui = "/org/dino-im/add_conversation/conference_details_fragment.ui")]
protected class ConferenceDetailsFragment : Box {

    public bool done {
        get {
            Jid? parsed_jid = Jid.parse(jid);
            return parsed_jid != null && parsed_jid.localpart != null &&
                parsed_jid.resourcepart == null && nick != "";
        }
        private set {}
    }

    public Account account {
        owned get {
            foreach (Account account in stream_interactor.get_accounts()) {
                if (accounts_comboboxtext.get_active_text() == account.bare_jid.to_string()) {
                    return account;
                }
            }
            return null;
        }
        set {
            accounts_label.label = value.bare_jid.to_string();
            accounts_comboboxtext.set_active_id(value.bare_jid.to_string());
        }
    }
    public string jid {
        get { return jid_entry.text; }
        set {
            jid_label.label = value;
            jid_entry.text = value;
        }
    }
    public string nick {
        get { return nick_entry.text; }
        set {
            nick_label.label = value;
            nick_entry.text = value;
        }
    }
    public string password {
        get { return password_entry.text == "" ? null : password_entry.text; }
        set {
            password_label.label = value;
            password_entry.text = value;
        }
    }

    [GtkChild]
    private Stack accounts_stack;

    [GtkChild]
    private Stack jid_stack;

    [GtkChild]
    private Stack nick_stack;

    [GtkChild]
    private Stack password_stack;

    [GtkChild]
    private Button accounts_button;

    [GtkChild]
    private Button jid_button;

    [GtkChild]
    private Button nick_button;

    [GtkChild]
    private Button password_button;

    [GtkChild]
    private Label accounts_label;

    [GtkChild]
    private Label jid_label;

    [GtkChild]
    private Label nick_label;

    [GtkChild]
    private Label password_label;

    [GtkChild]
    private ComboBoxText accounts_comboboxtext;

    [GtkChild]
    private Entry jid_entry;

    [GtkChild]
    private Entry nick_entry;

    [GtkChild]
    private Entry password_entry;

    private StreamInteractor stream_interactor;

    public ConferenceDetailsFragment(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        accounts_stack.set_visible_child_name("label");
        jid_stack.set_visible_child_name("label");
        nick_stack.set_visible_child_name("label");
        password_stack.set_visible_child_name("label");

        accounts_button.clicked.connect(() => { set_active_stack(accounts_stack); });
        jid_button.clicked.connect(() => { set_active_stack(jid_stack); });
        nick_button.clicked.connect(() => { set_active_stack(nick_stack); });
        password_button.clicked.connect(() => { set_active_stack(password_stack); });

        accounts_comboboxtext.changed.connect(() => {accounts_label.label = accounts_comboboxtext.get_active_text(); });
        jid_entry.key_release_event.connect(on_jid_key_release_event);
        nick_entry.key_release_event.connect(on_nick_key_release_event);
        password_entry.key_release_event.connect(on_password_key_release_event);

        jid_entry.key_release_event.connect(() => { done = true; return false; }); // just for notifying
        nick_entry.key_release_event.connect(() => { done = true; return false; });

        foreach (Account account in stream_interactor.get_accounts()) {
            accounts_comboboxtext.append_text(account.bare_jid.to_string());
        }
        accounts_comboboxtext.set_active(0);
    }

    public void set_editable() {
        accounts_stack.set_visible_child_name("entry");
        nick_stack.set_visible_child_name("entry");
        password_stack.set_visible_child_name("entry");
    }

    public void clear() {
        jid = "";
        nick = "";
        password = "";
    }

    private bool on_jid_key_release_event(EventKey event) {
        jid_label.label = jid_entry.text;
        if (event.keyval == Key.Return) jid_stack.set_visible_child_name("label");
        return false;
    }

    private bool on_nick_key_release_event(EventKey event) {
        nick_label.label = nick_entry.text;
        if (event.keyval == Key.Return) nick_stack.set_visible_child_name("label");
        return false;
    }

    private bool on_password_key_release_event(EventKey event) {
        string filler = "";
        for (int i = 0; i < password_entry.text.length; i++) filler += password_entry.get_invisible_char().to_string();
        password_label.label = filler;
        if (event.keyval == Key.Return) password_stack.set_visible_child_name("label");
        return false;
    }

    private void set_active_stack(Stack stack) {
        stack.set_visible_child_name("entry");
        if (stack != accounts_stack) accounts_stack.set_visible_child_name("label");
        if (stack != jid_stack) jid_stack.set_visible_child_name("label");
        if (stack != nick_stack) nick_stack.set_visible_child_name("label");
        if (stack != password_stack) password_stack.set_visible_child_name("label");
    }

}

}