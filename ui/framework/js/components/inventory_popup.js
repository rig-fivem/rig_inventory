/*
----------------------------------------
RIG Framework (built for CFX Platforms)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig
License: https://github.com/rig-fivem/rig/blob/main/LICENSE
----------------------------------------
*/

import { resolve_image_path } from "../helpers.js";

export class InventorySlot {
    constructor(config = {}) {
        this.position = config.position || "top-center";
        this.container = null;
        this.init();
    }

    init() {
        if (this.container) return;

        this.container = $('<div>', {
            class: `slot_popups slot_popups_${this.position}`
        });
        $('body').append(this.container);
    }

    show({ item_id, image, quantity, action, rarity = "common" }) {
        const action_symbol = action === "added" ? "+" : "-";
        const action_class = action === "added" ? "action_added" : "action_removed";

        const notification = $('<div>', {
            class: `inventory_popup rarity_${rarity} slot_popup_${action}`,
            html: `
                <div class="slot_popup_inner">
                    <div class="slot_popup_image">
                        <img src="${resolve_image_path(image, "/pluck/ui/assets/items/")}" />
                    </div>
                    <div class="slot_popup_quantity ${action_class}">
                        ${action_symbol}${Math.abs(quantity)}
                    </div>
                </div>
            `
        });

        this.container.append(notification);

        setTimeout(() => notification.addClass("visible"), 10);

        setTimeout(() => {
            notification.removeClass("visible");
            setTimeout(() => notification.remove(), 300);
        }, 2000);
    }

    destroy() {
        if (this.container) {
            this.container.remove();
            this.container = null;
        }
    }
}