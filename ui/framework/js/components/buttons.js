/*
----------------------------------------
RIG Framework (built for CFX Platforms)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig
License: https://github.com/rig-fivem/rig/blob/main/LICENSE
----------------------------------------
*/

import { Modal } from "../../../modal/js/modal.js"
import { send_nui_callback } from "../helpers.js";

export class Buttons {
    constructor({ buttons = [], classes = "", global = true }) {
        this.buttons = Array.isArray(buttons) ? buttons : Object.values(buttons);
        this.classes = classes;
        this.global = global;
    }

    get_html() {
        return `<div class="button_group ${this.classes}">` + this.buttons.map((b, i) => {
            const id = b.id || `btn_${i}`;
            const dataset = Object.entries(b.dataset || {}).map(([k, v]) => `data-${k}="${v}"`).join(" ");
            const modal = b.modal ? JSON.stringify(b.modal).replace(/'/g, "&apos;").replace(/"/g, "&quot;") : "";
            const icon = b.icon ? `<i class="${b.icon}"></i>` : "";
            return `<button id="${id}" class="${this.global ? "btn" : ""} ${b.class || ""}" data-button="${id}" data-action="${b.action || ""}" ${b.should_close ? 'data-should_close="true"' : ""} ${dataset} data-modal="${modal}">${icon}${b.label || ""}</button>`;
        }).join("") + `</div>`;
    }

    append_to(container = ".content") {
        $(container).append($(this.get_html()));
    }
}

$(document).off("click", ".btn").on("click", ".btn", function () {
    const $btn = $(this);
    const $modal = $btn.closest(".modal");
    const is_modal = $modal.length > 0;
    const action = $btn.data("action");
    const should_close = $btn.attr("data-should_close") === "true";

    const handle_close = () => {
        if (is_modal) {
            $modal.remove();
            if ($(".modal").length === 0) {
                $("#ui_focus").removeClass("active").empty();
            }
        } else {
            if (window.audio_player) {
                window.audio_player.destroy();
                window.audio_player = null;
            }
            if (window.ui_instance) {
                window.ui_instance.destroy();
                window.ui_instance = null;
            }
            $("#ui_focus").removeClass("active").empty();
        }
    };

    const modal_raw = $btn.attr("data-modal");
    if (modal_raw && !is_modal) {
        try {
            const parsed = JSON.parse(modal_raw.replace(/&quot;/g, '"').replace(/&apos;/g, "'"));
            Modal.show(parsed);
            return;
        } catch (e) {
            console.error("[Buttons] Failed to parse modal JSON:", e);
            return;
        }
    }

    if (action === "close_modal" && is_modal) {
        handle_close();
        return;
    }

    if (action === "close_builder" && window.ui_instance) {
        handle_close();
        return;
    }

    if (!action) {
        if (should_close) {
            handle_close();
            return;
        }
        console.warn("[Buttons] No action defined on clicked button.");
        return;
    }

    const dataset = {};

    for (const attr of $btn[0].attributes) {
        if (attr.name.startsWith("data-") && !["data-modal", "data-action", "data-action_type", "data-button", "data-should_close"].includes(attr.name)) {
            const key = attr.name.replace("data-", "").replace(/-+/g, "_");
            dataset[key] = attr.value;
        }
    }

    if (is_modal) {
        $modal.find("input, select, textarea").each(function () {
            const $el = $(this);
            const key = $el.attr("name") || $el.attr("id");
            if (!key) return;

            let val;
            if ($el.is(":checkbox")) val = $el.is(":checked");
            else val = $el.val();

            dataset[key] = val;

            for (const attr of $el[0].attributes) {
                if (attr.name.startsWith("data-")) {
                    const key = attr.name.slice(5).replace(/-+/g, "_");
                    dataset[key] = attr.value;
                }
            }
        });

        $modal.find(".modal_select").each(function () {
            const id = $(this).data("id");
            const val = $(this).attr("data-value");
            const source = $(this).attr("data-source");
            if (id) dataset[id] = val;
            if (source) dataset.source = source;
        });
    }

    if (should_close) {
        handle_close();
    }

    send_nui_callback(action, dataset, { should_close }).catch((err) => {
        console.error("[Buttons] Callback failed:", err);
    });
});