/*
----------------------------------------
RIG Framework (built for CFX Platforms)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig
License: https://github.com/rig-fivem/rig/blob/main/LICENSE
----------------------------------------
*/

import { Cards } from "./cards.js";
import { InventorySlot } from "./inventory_slot.js";
import { InventoryGrid } from "./inventory_grid.js";
import { Hotbar } from "./hotbar.js";
import { InputGroups } from "./input_groups.js";
import { send_nui_callback } from "../helpers.js";

const HOTBAR_SECTION = "hotbar";

export class Content {
    constructor(pages = {}, classes = "", layout = { left: 1, center: 2, right: 1 }, hotbar_config = null) {
        this.pages = pages;
        this.classes = classes;
        this.layout = layout;

        this.page_items = Object.create(null);

        this.current_slots_instances = [];
        this.current_grid_instances = [];
        this.current_page_id = null;

        this.hotbar_config = hotbar_config;
        this.hotbar_items = { [HOTBAR_SECTION]: hotbar_config?.items ? JSON.parse(JSON.stringify(hotbar_config.items)) : {} };
        this.hotbar_instance = null;
    }

    get_html() {
        const sections_html = ["left", "center", "right"].map(s => `
            <div class="content_section ${s}" style="grid-column: span ${this.layout[s] || 0};">
                <div class="content_title ${s}"></div><div class="content_body ${s}"></div>
            </div>`).join("");

        const hotbar_html = this.hotbar_config ? `<div id="hotbar_container"></div>` : "";

        return `<div class="content_grid ${this.classes}">${sections_html}</div>${hotbar_html}`.trim();
    }

    append_to(container = "#ui_main") {
        $(container).append(this.get_html());
        if (this.hotbar_config) this.build_hotbar();
    }

    build_hotbar() {
        this.hotbar_instance = new Hotbar({
            slot_count: this.hotbar_config.slot_count || 5,
            section_key: HOTBAR_SECTION,
            items: this.hotbar_items,
            show_slot_numbers: this.hotbar_config.show_slot_numbers !== false,
            layout: this.hotbar_config.layout || {},
            on_swap: this.create_unified_swap_handler(),
            on_drop_to_grid: this.create_hotbar_to_grid_handler()
        });
        this.hotbar_instance.append_to("#hotbar_container");
    }

    async show_page(id) {
    this.current_page_id = id;

    const config = this.pages[id];
    if (!config || typeof config !== "object") {
        $(".content_body.center").html(`<div class="placeholder_content"></div>`);
        return;
    }

    if (!this.page_items) this.page_items = {};
    if (!this.page_items[id]) this.page_items[id] = {};

    for (const section_key of Object.keys(config)) {
        if (section_key === "layout" || section_key === "layout_order") continue;
        const sec = config[section_key];
        if (!sec || typeof sec !== "object") continue;

        if (!this.page_items[id][section_key]) {
            this.page_items[id][section_key] = {};
        }

        if (Array.isArray(sec.groups)) {
            sec.groups.forEach(group => {
                if (group && group.id !== undefined && group.items) {
                    this.page_items[id][section_key][group.id] = JSON.parse(JSON.stringify(group.items));
                }
            });
        } else if (sec.items) {
            this.page_items[id][section_key]["_default"] = JSON.parse(JSON.stringify(sec.items));
        }
    }

    const slots_instances = [];
    const grid_instances = [];

    $(".content_section").hide();

    const layout = config.layout || this.layout || { left: 4, center: 6, right: 4 };

    let layout_entries = [];
    if (Array.isArray(layout)) {
        layout_entries = layout.map(item => {
            if (typeof item === "string") return { key: item, span: Number(config[item]?.span) || 4 };
            if (typeof item === "object" && item !== null) {
                if (item.key) return { key: item.key, span: Number(item.span) || 0 };
                const k = Object.keys(item)[0];
                return { key: k, span: Number(item[k]) || 0 };
            }
            return null;
        }).filter(Boolean);
    } else if (typeof layout === "object" && layout !== null) {
        const preferred_order = config.layout_order || config.order || ["spacer1", "spacer_1", "left", "spacer2", "spacer_2", "center", "spacer3", "spacer_3", "right"];
        const keys = Object.keys(layout);
        const sorted_keys = [];

        for (const pKey of preferred_order) {
            if (keys.includes(pKey) && !sorted_keys.includes(pKey)) {
                sorted_keys.push(pKey);
            }
        }
        for (const key of keys) {
            if (!sorted_keys.includes(key)) {
                sorted_keys.push(key);
            }
        }

        layout_entries = sorted_keys.map(key => ({ key: key, span: Number(layout[key]) || 0 }));
    }

    let total_cols = 0;
    layout_entries.forEach(entry => total_cols += entry.span);
    if (total_cols > 0) {
        $(".content_grid").css({
            "display": "grid",
            "grid-template-columns": `repeat(${total_cols}, 1fr)`
        });
    }

    let current_col = 1;

    for (const entry of layout_entries) {
        const key = entry.key;
        const span = entry.span;
        if (span <= 0) continue;

        if (key.startsWith("spacer") || key.startsWith("placeholder")) {
            current_col += span;
            continue;
        }

        const section = config[key] || null;
        const $section = $(`.content_section.${key}`);

        if ($section.length === 0) {
            current_col += span;
            continue;
        }

        let $title = $section.find(`.content_title.${key}`);
        if ($title.length === 0) $title = $section.find(".content_title");

        let $body = $section.find(`.content_body.${key}`);
        if ($body.length === 0) $body = $section.find(".content_body");

        $section.css("grid-column", `${current_col} / span ${span}`).show();
        $title.empty();
        $body.empty();

        if (!section) {
            $body.html(`<div class="placeholder_section"></div>`);
            current_col += span;
            continue;
        }

        if (section.title) {
            $title.html(
                typeof section.title === "object"
                    ? `<h3>${section.title.text || ""}${section.title.span ? ` <span>${section.title.span}</span>` : ""}</h3>`
                    : `<h3>${section.title}</h3>`
            );
        }

        if (section.type === "slots") {
            const slots_instance = new InventorySlot({
                ...section,
                section_key: key,
                page_items: (this.page_items[id] && this.page_items[id][key]) || {},
                on_swap: this.create_unified_swap_handler(),
                on_drop_to_grid: this.create_slot_to_grid_handler()
            });
            slots_instance.render_to($body);
            slots_instances.push(slots_instance);
        } else if (section.type === "grid") {
            if (section.groups && Array.isArray(section.groups)) {
                const $groups_wrapper = $(`<div class="grid_groups_wrapper"></div>`);
                $body.append($groups_wrapper);

                for (const group of section.groups) {
                    if (!group) continue;
                    const group_key = `${key}_${group.id}`;
                    const container_id = `grid_group_${group_key}`;
                    const collapsible = group.collapsible !== false;
                    const collapsed = group.collapsed === true;
                    const span_html = group.span ? `<span>${group.span}</span>` : "";
                    const title_html = group.title ? `<div class="grid_group_title${collapsible ? " collapsible" : ""}" data-target="${container_id}"><div class="grid_group_title_inner"><div class="grid_group_title_label">${group.title}</div></div>${span_html}</div>` : "";

                    const $group_el = $(`<div class="grid_group">${title_html}<div class="grid_container${collapsed ? " collapsed" : ""}" id="${container_id}"></div></div>`);
                    $groups_wrapper.append($group_el);

                    const items = (this.page_items[id] && this.page_items[id][key] && this.page_items[id][key][group.id]) || [];
                    const grid_instance = new InventoryGrid({
                        layout: { ...(section.layout || {}), ...(group.layout || {}) },
                        items: Array.isArray(items) ? items : Object.values(items),
                        section_key: group_key,
                        on_move: this.create_move_handler(id),
                        on_drop_to_slot: this.create_grid_to_hotbar_handler(),
                        draggable: group.draggable ?? true
                    });
                    grid_instance.render_to(`#${container_id}`);
                    grid_instances.push(grid_instance);
                }

                $groups_wrapper.off("click", ".grid_group_title.collapsible").on("click", ".grid_group_title.collapsible", function() {
                    $(`#${$(this).data("target")}`).toggleClass("collapsed");
                });
            } else {
                const items = (this.page_items[id] && this.page_items[id][key] && this.page_items[id][key]["_default"]) || [];
                const flat_container_id = `grid_flat_${key}`;
                $body.append(`<div class="grid_container" id="${flat_container_id}"></div>`);
                const grid_instance = new InventoryGrid({
                    layout: section.layout || {},
                    section_key: section.section_key || key,
                    items: Array.isArray(items) ? items : Object.values(items),
                    on_move: this.create_move_handler(id),
                    on_drop_to_slot: this.create_grid_to_hotbar_handler()
                });
                grid_instance.render_to(`#${flat_container_id}`);
                grid_instances.push(grid_instance);
            }
        } else {
            const html = await this.render_content(section);
            $body.html(html);
        }

        current_col += span;
    }

    this.current_slots_instances = slots_instances;
    this.current_grid_instances = grid_instances;
    window.ui_instance?.tooltip?.bind_tooltips();
}

    create_unified_swap_handler() {
        return async (from_slot_num, to_slot_num, from_group_id, to_group_id, from_section, to_section) => {
            const page_id = this.current_page_id;

            const get_bucket = (section, group) => {
                if (section === HOTBAR_SECTION) {
                    this.hotbar_items[group] ??= {};
                    return this.hotbar_items[group];
                }
                const items = this.page_items[page_id];
                if (!items) return null;
                items[section] ??= {};
                items[section][group] ??= {};
                return items[section][group];
            };

            const src = get_bucket(from_section, from_group_id);
            const dst = get_bucket(to_section, to_group_id);
            if (!src || !dst) return;

            const from_item = src[from_slot_num];
            if (!from_item) return;

            const to_item = dst[to_slot_num];

            if (to_item) {
                src[from_slot_num] = to_item;
                dst[to_slot_num] = from_item;
            } else {
                dst[to_slot_num] = from_item;
                delete src[from_slot_num];
            }

            const hotbar_involved = from_section === HOTBAR_SECTION || to_section === HOTBAR_SECTION;

            this.on_item_moved({
                page_id,
                from_section,
                to_section,
                from_group: from_group_id,
                to_group: to_group_id,
                from_slot: from_slot_num,
                to_slot: to_slot_num,
                swap: !!to_item,
                hotbar_involved
            });

            for (const inst of this.current_slots_instances) {
                inst.update_items(this.page_items[page_id]?.[inst.section_key]);
            }
            if (this.hotbar_instance) this.hotbar_instance.update_items(this.hotbar_items);
        };
    }

    create_move_handler(page_id) {
        return async (item_id, from_col, from_row, to_col, to_row, from_section, to_section, dataset) => {
            const page = this.page_items[page_id];
            if (page) {
                const resolve = (section_key) => {
                    for (const s of ["left", "center", "right"]) {
                        if (section_key === s) return { bucket: page[s], key: "_default" };
                        if (section_key.startsWith(`${s}_`)) {
                            const group_id = section_key.slice(s.length + 1);
                            return { bucket: page[s], key: group_id };
                        }
                    }
                    return null;
                };

                const src = resolve(from_section);
                const dst = resolve(to_section);

                if (src && dst) {
                    const src_items = src.bucket[src.key];
                    const dst_items = dst.bucket[dst.key];

                    if (Array.isArray(src_items)) {
                        const item = src_items.find(i => String(i.col) === String(from_col) && String(i.row) === String(from_row));
                        if (item) {
                            if (from_section !== to_section) {
                                src_items.splice(src_items.indexOf(item), 1);
                                if (Array.isArray(dst_items)) {
                                    item.col = Number(to_col);
                                    item.row = Number(to_row);
                                    dst_items.push(item);
                                }
                            } else {
                                item.col = Number(to_col);
                                item.row = Number(to_row);
                            }
                        }
                    }
                }
            }

            this.on_grid_item_moved({
                page_id,
                item_id,
                from_col,
                from_row,
                to_col,
                to_row,
                from_section,
                to_section,
                dataset
            });
        };
    }

    _resolve_grid_bucket(section_key) {
        const page = this.page_items[this.current_page_id];
        if (!page) return null;
        for (const s of ["left", "center", "right"]) {
            if (section_key === s) return { bucket: page[s], key: "_default" };
            if (section_key.startsWith(`${s}_`)) {
                return { bucket: page[s], key: section_key.slice(s.length + 1) };
            }
        }
        return null;
    }

    create_grid_to_hotbar_handler() {
        return async (item_id, from_col, from_row, from_section, to_slot_num, to_group, to_section) => {
            if (to_section !== HOTBAR_SECTION) return;

            const src = this._resolve_grid_bucket(from_section);
            if (!src) return;

            const src_items = src.bucket[src.key];
            if (!Array.isArray(src_items)) return;

            const item = src_items.find(i => String(i.col) === String(from_col) && String(i.row) === String(from_row));
            if (!item) return;

            this.hotbar_items[to_group] ??= {};
            if (this.hotbar_items[to_group][to_slot_num]) return;

            src_items.splice(src_items.indexOf(item), 1);
            this.hotbar_items[to_group][to_slot_num] = {
                id: item.id,
                image: item.image,
                label: item.label,
                quantity: item.quantity,
                category: item.category,
                on_hover: item.on_hover,
                dataset: item.dataset,
                slot_num: to_slot_num,
                group_id: to_group
            };

            this.on_item_moved({
                page_id: this.current_page_id,
                from_section,
                to_section,
                to_group,
                to_slot: to_slot_num,
                from_col,
                from_row,
                item_id,
                hotbar_involved: true
            });

            for (const inst of this.current_grid_instances) {
                if (inst.section_key === from_section) inst.update_items(src_items);
            }
            if (this.hotbar_instance) this.hotbar_instance.update_items(this.hotbar_items);
        };
    }

    create_hotbar_to_grid_handler() {
        return async (from_slot_num, from_group, from_section, to_col, to_row, to_section) => {
            if (from_section !== HOTBAR_SECTION) return;

            const item = this.hotbar_items[from_group]?.[from_slot_num];
            if (!item) return;

            const dst = this._resolve_grid_bucket(to_section);
            if (!dst) return;

            dst.bucket[dst.key] ??= [];
            if (!Array.isArray(dst.bucket[dst.key])) return;

            delete this.hotbar_items[from_group][from_slot_num];
            dst.bucket[dst.key].push({
                ...item,
                col: Number(to_col),
                row: Number(to_row),
                w: item.w || 1,
                h: item.h || 1
            });

            this.on_item_moved({
                page_id: this.current_page_id,
                from_section,
                to_section,
                from_group,
                from_slot: from_slot_num,
                to_col,
                to_row,
                hotbar_involved: true
            });

            if (this.hotbar_instance) this.hotbar_instance.update_items(this.hotbar_items);
            for (const inst of this.current_grid_instances) {
                if (inst.section_key === to_section) inst.update_items(dst.bucket[dst.key]);
            }
        };
    }

    create_slot_to_grid_handler() {
        return async (from_slot_num, from_group, from_section, to_col, to_row, to_section, dataset) => {
            if (from_section === HOTBAR_SECTION) {
                return this.create_hotbar_to_grid_handler()(from_slot_num, from_group, from_section, to_col, to_row, to_section, dataset);
            }
            // Non-hotbar slots-to-grid isn't wired to a schema by default - left as an extension point.
        };
    }

    on_item_moved(move_data) {
        send_nui_callback("slots_moved_item", move_data);
    }

    on_grid_item_moved(move_data) {
        send_nui_callback("grid_moved_item", move_data);
    }

    update_slots_from_server(server_items) {
        if (!this.current_page_id) return;

        const page = this.page_items[this.current_page_id];
        if (!page) return;

        for (const section of ["left", "center", "right"]) {
            const sec = page[section];
            if (!sec) continue;

            for (const [group_id, slots] of Object.entries(server_items)) {
                if (sec[group_id] !== undefined) {
                    sec[group_id] = JSON.parse(JSON.stringify(slots));
                } else {
                    sec[group_id] = JSON.parse(JSON.stringify(slots));
                }
            }
        }

        for (const inst of this.current_slots_instances) {
            inst.update_items(page[inst.section_key]);
        }
    }

    update_grid_from_server(server_items, section_key = "center") {
        if (!this.current_page_id) return;

        const page = this.page_items[this.current_page_id];
        if (!page) return;

        for (const s of ["left", "center", "right"]) {
            if (section_key === s) {
                page[s]["_default"] = JSON.parse(JSON.stringify(server_items));
                break;
            }
            if (section_key.startsWith(`${s}_`)) {
                const group_id = section_key.slice(s.length + 1);
                if (page[s]) page[s][group_id] = JSON.parse(JSON.stringify(server_items));
                break;
            }
        }

        for (const inst of this.current_grid_instances) {
            if (inst.section_key === section_key) {
                inst.update_items(server_items);
            }
        }
    }

    update_hotbar_from_server(server_items) {
        const actual_items = (server_items && server_items.items) ? server_items.items : server_items;
        
        this.hotbar_items[HOTBAR_SECTION] = actual_items ? JSON.parse(JSON.stringify(actual_items)) : {};
        
        if (this.hotbar_instance) {
            this.hotbar_instance.update_items(this.hotbar_items);
        }
    }
    
    set_content(html, section = "center") {
        $(`.content_body.${section}`).html(html);
    }

    clear() {
        $(".content_body, .content_title").empty();
    }

    async render_content(data) {
        const map = {
            cards: () => this.build_cards(data),
            slots: () => this.build_slots(data),
            grid: () => this.build_grid(data),
            input_groups: () => this.build_input_groups(data)
        };
        return map[data.type]?.() || "";
    }

    build_cards(data) {
        return new Cards(data).get_html();
    }

    build_slots(data) {
        return new InventorySlot(data).get_html();
    }

    build_grid(data) {
        return new InventoryGrid(data).get_html();
    }

    build_input_groups(data) {
        return new InputGroups({
            id: data.id || "input_groups",
            title: data.title || "",
            layout: data.layout || {},
            groups: Array.isArray(data.groups) ? data.groups : Object.values(data.groups || {}),
            buttons: Array.isArray(data.buttons) ? data.buttons : Object.values(data.buttons || {})
        }).get_html();
    }
}