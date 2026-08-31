/*
----------------------------------------
RIG Framework (built for CFX Platforms)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig
License: https://github.com/rig-fivem/rig/blob/main/LICENSE
----------------------------------------
*/

import { Buttons } from "./buttons.js"
import { send_nui_callback } from "../helpers.js";

export class Footer {
    constructor({ layout = {}, elements = {}, on_action = null, on_button_action = null }) {
        this.layout = layout;
        this.elements = elements;
        this.on_action = on_action;
        this.on_button_action = on_button_action;
        this.action_callbacks = {};
    }

    get_section_style(section) {
        const c = this.layout[section] || {};
        return `justify-content:${c.justify || "center"};align-items:${c.align || "center"};gap:${c.gap || "1vw"}`;
    }

    build_element(elem) {
        const { type } = elem;
        if (type === "text") return `<div class="footer_text">${elem.text}</div>`;
        if (type === "actions") {
            const actions = Array.isArray(elem.actions) ? elem.actions : [elem];
            return `
                <div class="footer_actions_group">
                    ${actions.map((a, idx) => {
                        let action_key = a.action;
                        if (typeof a.action === "function") {
                            action_key = `action_${idx}`;
                            this.action_callbacks[action_key] = a.action;
                        }
                        return `
                        <div class="footer_action ${a.class || ""}" ${a.id ? `id="${a.id}"` : ""} data-action="${action_key}" data-key="${a.key}" ${a.should_close ? 'data-should_close="true"' : ""}>
                            <span class="footer_key">${a.key}</span><span class="footer_label">${a.label}</span>
                        </div>`;
                    }).join("")}
                </div>
            `.trim();
        }
        if (type === "buttons") {
            const buttons = Array.isArray(elem.buttons) ? elem.buttons : Object.values(elem.buttons || {});
            return new Buttons({ buttons, classes: "footer_button_group" }).get_html();
        }
        if (type === "group") {
            const items = Array.isArray(elem.items) ? elem.items : Object.values(elem.items || {});
            return `<div class="footer_group">${items.map(i => this.build_element(i)).join("")}</div>`;
        }
        return "";
    }

    get_html() {
        return `
            <div class="footer">
                ${["left", "center", "right"].map(s => {
                    const items = Array.isArray(this.elements[s]) ? this.elements[s] : Object.values(this.elements[s] || {});
                    return `<div class="footer_section ${s}" style="${this.get_section_style(s)}">${items.map(e => this.build_element(e)).join("")}</div>`;
                }).join("")}
            </div>`.trim();
    }

    append_to(container = "#ui_main") {
        $(container).append(this.get_html());
        this.bind_events();
    }

    bind_events() {
        $(".footer_button_group .btn").off("click").on("click", e => {
            const id = $(e.currentTarget).data("button");
            const action = $(e.currentTarget).data("action");
            if (this.on_button_action) return this.on_button_action(id, action);
            if (action) {
                send_nui_callback(action, { source: "footer_button", id });
            }
        });

        $(document).off("keydown.footer").on("keydown.footer", e => {
            if ($("#modal_container").length || $("#ui_focus").hasClass("active")) return;

            const tag = e.target.tagName;
            if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT" || e.target.isContentEditable) return;

            const key = e.key.toUpperCase();
            const $match = $(`.footer_action[data-key="${key}"]`);
            if ($match.length) {
                const action = $match.data("action");
                if (action) {
                    e.preventDefault();
                    const should_close = $match.data("should_close") === true;

                    if (this.action_callbacks[action]) {
                        this.action_callbacks[action]();

                        if (should_close && window.ui_instance) {
                            window.ui_instance.destroy();
                            window.ui_instance = null;
                        }
                    } else {
                        if (this.on_action) {
                            this.on_action(action, { should_close });
                        } else {
                            send_nui_callback(action, { keypress: true }, { should_close }).then(() => {
                                if (should_close && window.ui_instance) {
                                    window.ui_instance.destroy();
                                    window.ui_instance = null;
                                }
                            });
                        }
                    }
                }
            }
        });
    }
}