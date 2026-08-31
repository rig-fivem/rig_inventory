/*
----------------------------------------
RIG Framework (built for CFX Platforms)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig
License: https://github.com/rig-fivem/rig/blob/main/LICENSE
----------------------------------------
*/

import { InventorySlot } from "./inventory_slot.js";

export class Hotbar {
    constructor({
        slot_count = 5,
        section_key = "hotbar",
        items = {},
        show_slot_numbers = true,
        layout = {},
        on_swap = null,
        on_drop_to_grid = null,
        draggable = true
    } = {}) {
        this.slot_count = slot_count;
        this.section_key = section_key;

        this.slots = new InventorySlot({
            layout,
            section_key,
            page_items: items,
            groups: [{
                id: section_key,
                title: "",
                collapsible: false,
                slot_count,
                columns: slot_count,
                slot_size: layout.slot_size || "58px",
                show_slot_numbers
            }],
            on_swap,
            on_drop_to_grid,
            draggable
        });
    }

    append_to(selector) {
        const $target = $(selector);
        if ($target.length === 0) return;

        $target.addClass("hotbar_wrapper");
        this.slots.render_to(selector);
    }

    update_items(items) {
        this.slots.update_items(items || {});
    }
}