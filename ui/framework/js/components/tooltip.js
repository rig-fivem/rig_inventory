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

export class Tooltip {
    constructor(selector = "#tooltip") {
        this.$el = $(selector);
        if (!this.$el.length) {
            $("body").append(`<div id="tooltip" style="display:none;"></div>`);
            this.$el = $('#tooltip');
        }
        this.bind_keypress();
    }

    set_content({ on_hover = {}, suppress_actions = false }) {
        const { title = "Details", description = [], values = [], actions = [], rarity = "common" } = on_hover;

        const rarity_color = rarity.toLowerCase() !== "common" ? `var(--rarity_${rarity.toLowerCase()})` : "var(--accent)";
        this.$el.css("--tooltip_rarity_colour", rarity_color);

        const desc_html = description.length
            ? `<div class="tooltip_subtitle">Description</div><div class="tooltip_description">${description.map(d => `<p>${d}</p>`).join("")}</div>`
            : "";

        const val_html = values.length
            ? `<div class="tooltip_subtitle">Details</div><div class="tooltip_values"><ul>${values.map(v => `<li>${v.key}: <span style="color:${rarity_color}">${v.value}</span></li>`).join("")}</ul></div>`
            : "";

        const acts_html = actions.length && !suppress_actions
            ? `<div class="tooltip_subtitle">Actions</div><div class="tooltip_actions">${actions.map(a =>
                `<div class="tooltip_key_hint" data-action-id="${a.id}">
                    <span class="tooltip_key" style="color:${rarity_color}">${a.key}</span> ${a.label}
                </div>`).join("")}</div>`
            : "";

        const header_html = `<div class="tooltip_title">${title}<div class="tooltip_rarity">${rarity}</div></div>`;

        this.$el.html(`${header_html}${desc_html}${val_html}${acts_html}`);
        this.$el.data("tooltip_actions", actions);
    }

    show(x, y) {
        if ($('#modal_container').length > 0) return;
        const win_w = $(window).width(), win_h = $(window).height();
        const w = this.$el.outerWidth(), h = this.$el.outerHeight();
        const left = (x + 15 + w > win_w) ? x - 15 - w : x + 15;
        const top = (y + 15 + h > win_h) ? y - 15 - h : y + 15;
        this.$el.css({ left, top }).show();
    }

    hide() {
        this.$el.hide().removeData("tooltip_actions").removeData("tooltip_element");
    }

    attach_mousemove() {
        $(document).on("mousemove.tooltip", e => this.show(e.pageX, e.pageY));
    }

    detach_mousemove() {
        $(document).off("mousemove.tooltip");
    }

    bind_tooltips() {
        $(".body_card[data-tooltip], .body_slot[data-tooltip], .grid_item[data-tooltip]").each((_, el) => {
            let data = $(el).data("tooltip");

            if (typeof data === "string") {
                try {
                    data = JSON.parse(data);
                } catch (err) {
                    console.error("[Tooltip] Failed to parse tooltip:", err);
                    return;
                }
            }

            if (!data || typeof data !== "object") return;

            $(el)
                .off("mouseenter mouseleave")
                .on("mouseenter", () => {
                    this.set_content(data);
                    this.$el.data("tooltip_element", el);
                    this.attach_mousemove();
                })
                .on("mouseleave", () => {
                    this.hide();
                    this.detach_mousemove();
                });
        });
    }

    bind_keypress() {
        $(document).off("keydown.tooltip_actions").on("keydown.tooltip_actions", (e) => {
            if (!this.$el.is(":visible")) return;

            const key = e.key.toUpperCase();
            const actions = this.$el.data("tooltip_actions") || [];
            const el = this.$el.data("tooltip_element");

            const action = actions.find(a => a.key.toUpperCase() === key);
            if (!action) return;

            let dataset = {};
            let should_close = action.should_close === true;

            if (el && el.dataset) {
                for (const [k, v] of Object.entries(el.dataset)) {
                    const key = k.replace(/[A-Z]/g, l => `_${l.toLowerCase()}`);
                    if (key === "should_close") {
                        should_close = v === "true";
                    } else {
                        dataset[key] = v;
                    }
                }
            }

            if (action.modal && typeof action.modal === "object") {
                this.hide();
                Modal.show(action.modal);
                return;
            }

            send_nui_callback(action.action, dataset, { should_close }).then(() => {
                if (should_close && window.ui_instance?.destroy) {
                    window.ui_instance.destroy();
                    window.ui_instance = null;
                }
            });
        });
    }
}