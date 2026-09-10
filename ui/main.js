/*
----------------------------------------
RIG Framework (built for CFX Platforms)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig
License: https://github.com/rig-fivem/rig/blob/main/LICENSE
----------------------------------------
*/

// Imports

import { Modal } from "./modal/js/modal.js";
import { UIBuilder } from "./framework/js/main.js";
import { SlotPopup } from "./framework/js/components/inventory_popup.js";

// Handler Functions

const inventory_popup = new SlotPopup({
    position: "bottom-center"
});

const HANDLERS = {}

/** Modal */

HANDLERS.build_modal = (data) => {
    if (!data || !data.payload) {
        console.warn("[Modal] Missing payload.");
        return;
    }

    Modal.show({
        title: data.payload.title,
        options: data.payload.options || [],
        buttons: data.payload.buttons || []
    });
};

HANDLERS.remove_modal = (data) => {
    const container = data && data.payload && data.payload.container ? data.payload.container : "#ui_focus";
    Modal.remove(container);
};

/** UI Framework */

HANDLERS.build_ui = (data) => {

    if (!data.payload) {
        console.warn("[UI Builder] No UI data provided");
        return;
    }

    if (window.ui_instance && typeof window.ui_instance.destroy === "function") {
        window.ui_instance.destroy();
        window.ui_instance = null;
    }

    const builder = new UIBuilder(data.payload);
    window.ui_instance = builder;
};

HANDLERS.close_ui = () => {
    if (window.ui_instance && typeof window.ui_instance.destroy === "function") {
        window.ui_instance.close();
        window.ui_instance.destroy();
        window.ui_instance = null;
    }
};

/** Inventory */

HANDLERS.update_grid = (data) => {
    if (!data || !data.items || !data.section_key) return;

    const ui = window.ui_instance;
    if (!ui || !ui.content) return;

    ui.content.update_grid_from_server(data.items, data.section_key);
};

HANDLERS.update_slots = (data) => {
    if (!data || !data.items) { return; }

    const ui = window.ui_instance;
    if (!ui || !ui.content) { return; }
    
    ui.content.update_slots_from_server(data.items);
};

HANDLERS.inventory_popup = (data) => {
    if (!data) return;
    inventory_popup.show(data.payload);
};

/**
 * Global message listener for all NUI messages.
 * Routes each message to its corresponding handler.
 */
window.addEventListener("message", (event) => {
    const { func } = event.data;
    const handler = HANDLERS[func];

    if (typeof handler !== "function") {
        console.warn(`Handler missing: ${func}`);
        return;
    }

    handler(event.data);
});