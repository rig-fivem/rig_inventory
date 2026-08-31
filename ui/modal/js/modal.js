/*
----------------------------------------
RIG Framework (built for CFX Platforms)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig
License: https://github.com/rig-fivem/rig/blob/main/LICENSE
----------------------------------------
*/

import { Buttons } from "../../framework/js/components/buttons.js"
import { send_nui_callback } from "../../framework/js/helpers.js";

export class Modal {
    constructor({ title = "Input Required", options = [], buttons = [], classes = "" } = {}) {
        this.title = title;
        this.options = Array.isArray(options) ? options : Object.values(options);
        this.buttons = Array.isArray(buttons) ? buttons : Object.values(buttons);
        this.classes = classes;
    }

    get_input_html(opt) {
        const common = `id="${opt.id}" class="modal_input"`;
        let dataset_attrs = "";

        if (opt.dataset && typeof opt.dataset === "object") {
            for (const [k, v] of Object.entries(opt.dataset)) {
                dataset_attrs += ` data-${k.replace(/_/g, "-")}="${v}"`;
            }
        }

        if (opt.type === "select" && Array.isArray(opt.options)) {
            const opts = opt.options.map(o =>
                `<div class="custom_option" data-value="${o.value}" data-source="${o.source || o.value}">${o.label}</div>`
            ).join("");

            return `<div class="modal_field">
                <label for="${opt.id}">${opt.label || opt.id}</label>
                <div class="modal_select_wrapper">
                    <div class="modal_select" data-id="${opt.id}">Select a value...</div>
                    <div class="modal_select_options">${opts}</div>
                </div>
            </div>`;
        }

        if (opt.type === "textarea") {
            return `<div class="modal_field">
                <label for="${opt.id}">${opt.label || opt.id}</label>
                <textarea ${common}${dataset_attrs} placeholder="${opt.placeholder || ""}"></textarea>
            </div>`;
        }

        if (opt.type === "range") {
            const start = opt.value ?? opt.min ?? 0;
            return `<div class="modal_field">
                <label for="${opt.id}">
                    ${opt.label || opt.id}
                    <span class="slider_value" data-for="${opt.id}">${start}</span>
                </label>
                <input type="range" ${common} ${dataset_attrs} min="${opt.min ?? 0}" max="${opt.max ?? 100}" step="${opt.step ?? 1}" value="${start}"/>
            </div>`;
        }

        const attrs = [`type="${opt.type || "text"}"`, common, dataset_attrs, opt.placeholder ? `placeholder="${opt.placeholder}"` : "", opt.min !== undefined ? `min="${opt.min}"` : "", opt.max !== undefined ? `max="${opt.max}"` : ""].join(" ");

        return `<div class="modal_field">
            <label for="${opt.id}">${opt.label || opt.id}</label>
            <input ${attrs.trim()} />
        </div>`;
    }

    get_html() {
        const inputs = this.options.map(opt => this.get_input_html(opt)).join("\n");
        const buttons = new Buttons({ buttons: this.buttons, classes: "modal_button_group" }).get_html();
        return `<div id="modal_container">
            <div class="modal ${this.classes}">
                <h2 class="modal_title">${this.title}</h2>
                <div class="modal_inputs">${inputs}</div>
                <div class="modal_actions">${buttons}</div>
            </div>
        </div>`.trim();
    }

    append_to(container = "#ui_focus") {
        // Force cleanup any existing modal elements or stray listeners before rendering a new one
        Modal.remove(container);

        $(container).html(this.get_html()).addClass("active");

        $(".modal_select").off("click").on("click", function () {
            const $w = $(this).closest(".modal_select_wrapper");
            $(".modal_select_options").not($w.find(".modal_select_options")).hide();
            $w.find(".modal_select_options").toggle();
        });

        $(".modal_select_options .custom_option").off("click").on("click", function () {
            const val = $(this).data("value");
            const source = $(this).data("source");
            const label = $(this).text();
            const $w = $(this).closest(".modal_select_wrapper");
            const $sel = $w.find(".modal_select");
            $sel.text(label).attr("data-value", val).attr("data-source", source);
            $w.find(".modal_select_options").hide();
        });

        $(".modal_field input[type='range']").off("input").on("input", function () {
            const id = $(this).attr("id");
            $(`.slider_value[data-for="${id}"]`).text($(this).val());
        });

        $(document).on("click.modal", e => {
            if (!$(e.target).closest(".modal_select_wrapper").length) {
                $(".modal_select_options").hide();
            }
        });
    }

    remove(container = "#ui_focus") {
        Modal.remove(container);
    }

    static remove(container = "#ui_focus") {
        $(container).removeClass("active");
        $("#modal_container").remove();
        $(document).off("click.modal");
    }

    static show({ title = "Input Required", options = [], buttons = [] }) {
        new Modal({ title, options, buttons }).append_to("#ui_focus");
    }
}