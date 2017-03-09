using Gee;

using Xmpp.Core;

namespace Xmpp.Roster {
    private const string NS_URI = "jabber:iq:roster";

    public class Module : XmppStreamModule, Iq.Handler {
        public const string ID = "roster_module";

        public signal void received_roster(XmppStream stream, Collection<Item> roster);
        public signal void item_removed(XmppStream stream, Item roster_item);
        public signal void item_updated(XmppStream stream, Item roster_item);

        public bool interested_resource = true;

        /**
         * Add a jid to the roster
         */
        public void add_jid(XmppStream stream, string jid, string? handle = null) {
            Item roster_item = new Item();
            roster_item.jid = jid;
            if (handle != null) {
                roster_item.name = handle;
            }
            roster_set(stream, roster_item);
        }

        /**
         * Remove a jid from the roster
         */
        public void remove_jid(XmppStream stream, string jid) {
            Item roster_item = new Item();
            roster_item.jid = jid;
            roster_item.subscription = Item.SUBSCRIPTION_REMOVE;

            roster_set(stream, roster_item);
        }

        /**
         * Set a handle for a jid
         * @param   handle  Handle to be set. If null, any handle will be removed.
         */
        public void set_jid_handle(XmppStream stream, string jid, string? handle) {
            Item roster_item = new Item();
            roster_item.jid = jid;
            if (handle != null) {
                roster_item.name = handle;
            }

            roster_set(stream, roster_item);
        }

        public void on_iq_set(XmppStream stream, Iq.Stanza iq) {
            StanzaNode? query_node = iq.stanza.get_subnode("query", NS_URI);
            if (query_node == null) return;

            Flag flag = Flag.get_flag(stream);
            Item item = new Item.from_stanza_node(query_node.get_subnode("item", NS_URI));
            switch (item.subscription) {
                case Item.SUBSCRIPTION_REMOVE:
                    flag.roster_items.unset(item.jid);
                    item_removed(stream, item);
                    break;
                default:
                    flag.roster_items[item.jid] = item;
                    item_updated(stream, item);
                    break;
            }
        }

        public void on_iq_get(XmppStream stream, Iq.Stanza iq) { }

        public static Module? get_module(XmppStream stream) {
            return (Module?) stream.get_module(NS_URI, ID);
        }

        public static void require(XmppStream stream) {
            if (get_module(stream) == null) stream.add_module(new Module());
        }

        public override void attach(XmppStream stream) {
            Iq.Module.require(stream);
            Iq.Module.get_module(stream).register_for_namespace(NS_URI, this);
            Presence.Module.require(stream);
            Presence.Module.get_module(stream).initial_presence_sent.connect(roster_get);
            stream.add_flag(new Flag());
        }

        public override void detach(XmppStream stream) {
            Presence.Module.get_module(stream).initial_presence_sent.disconnect(roster_get);
        }

        internal override string get_ns() { return NS_URI; }
        internal override string get_id() { return ID; }

        private void roster_get(XmppStream stream) {
            Flag.get_flag(stream).iq_id = UUID.generate_random_unparsed();
            StanzaNode query_node = new StanzaNode.build("query", NS_URI).add_self_xmlns();
            Iq.Stanza iq = new Iq.Stanza.get(query_node, Flag.get_flag(stream).iq_id);
            Iq.Module.get_module(stream).send_iq(stream, iq, new IqResponseListenerImpl());
        }

        private class IqResponseListenerImpl : Iq.ResponseListener, Object {
            public void on_result(XmppStream stream, Iq.Stanza iq) {
                Flag flag = Flag.get_flag(stream);
                if (iq.id == flag.iq_id) {
                    StanzaNode? query_node = iq.stanza.get_subnode("query", NS_URI);
                    foreach (StanzaNode item_node in query_node.sub_nodes) {
                        Item item = new Item.from_stanza_node(item_node);
                        flag.roster_items[item.jid] = item;
                    }
                    Module.get_module(stream).received_roster(stream, flag.roster_items.values);
                }
            }
        }

        private void roster_set(XmppStream stream, Item roster_item) {
            StanzaNode query_node = new StanzaNode.build("query", NS_URI).add_self_xmlns()
                                    .put_node(roster_item.stanza_node);
            Iq.Stanza iq = new Iq.Stanza.set(query_node);
            Iq.Module.get_module(stream).send_iq(stream, iq, null);
        }
    }
}