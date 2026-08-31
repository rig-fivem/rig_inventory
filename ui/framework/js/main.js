/*
----------------------------------------
RIG Framework (built for CFX Platforms)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig
License: https://github.com/rig-fivem/rig/blob/main/LICENSE
----------------------------------------
*/

import { Content } from "./components/content.js"
import { Footer } from "./components/footer.js"
import { Header } from "./components/header.js"
import { Tooltip } from "./components/tooltip.js"

export class UIBuilder {
    constructor({ header = null, footer = null, content = {} } = {}) {
        this.header_config = header; 
        this.footer_config = footer; 
        this.content_config = content; 
        this.tooltip = new Tooltip();
        window.ui_instance = this;
        this.main_container = $("#ui_main");
        this.build();
    }

    build() {
        this.main_container.empty().append(`
            <div class="vignette"></div>
            <div id="header_container"></div>
            <div id="content_container"></div>
            <div id="footer_container"></div>
        `);
        this.build_content();
        this.build_header();
        this.build_footer();
        const default_tab = this.get_default_page();
        this.adjust_vignette(default_tab ?? null);
    }

    build_header() {
        if (!this.header_config) return;

        const pages = this.content_config.pages;
        if (pages) {
            const tabs = Object.entries(pages).map(([id, cfg]) => ({ id, label: cfg.label ?? cfg.title ?? id, index: cfg.index ?? 999 })).sort((a, b) => a.index - b.index);
            const center = (this.header_config.elements ||= {}).center ||= [];
            const tab_elem = center.find(e => e.type === "tabs") || (center.push({ type: "tabs", tabs: [] }), center.at(-1));
            tab_elem.tabs = tabs;
            this.header_config.on_tab_click = id => this.content.show_page(id).then(() => this.adjust_vignette(id));
        }

        this.header = new Header(this.header_config);
        this.header.append_to("#header_container");
        this.header.trigger_default_tab?.();
    }

    build_footer() {
        if (!this.footer_config) return;
        this.footer = new Footer(this.footer_config);
        this.footer.append_to("#footer_container");
    }

    build_content() {
        if (!this.content_config.pages || typeof this.content_config.pages !== "object") return this.set_content();
        this.content = new Content(this.content_config.pages, "builder_content", undefined, this.content_config.hotbar);
        this.content.append_to("#content_container");

        const default_tab = this.get_default_page();
        if (default_tab) this.content.show_page(default_tab).then(() => this.adjust_vignette(default_tab));
    }

    get_default_page() {
        const entries = Object.entries(this.content_config.pages || {}).filter(([_, c]) => typeof c === "object" && c.index !== undefined).sort((a, b) => (a[1].index ?? 999) - (b[1].index ?? 999));

        return entries.length ? entries[0][0] : null;
    }

    set_content() {
        const html = this.content_config.html || `<div class="placeholder_content">No content defined.</div>`;
        this.content?.set_content(html);
    }

    adjust_vignette(page_id) {
        const $vignette = $(".vignette");

        if (!$vignette.length) { console.warn("[UIBuilder] No .vignette element found."); return; }

        const config = this.content_config.pages?.[page_id];
        const layout = config?.layout || {};

        const has_left = !!(layout.left && config?.left);
        const has_right = !!(layout.right && config?.right);

        if (has_left && has_right) {
            $vignette.css("background", "var(--gradient_fade_both)");
        } else if (has_right) {
            $vignette.css("background", "var(--gradient_fade_right)");
        } else {
            $vignette.css("background", "var(--gradient_fade_left)");
        }
    }

    destroy() {
        if ($("#tooltip").length) {
            $(document).off(".tooltip");
            $("#tooltip").remove();
        }

        if ($("#modal_container").length) {
            $("#modal_container").remove();
        }

        this.main_container.empty();
        this.header = null;
        this.footer = null;
        this.content = null;
        this.tooltip = null;
    }

    close() {
        $.post(`https://${GetParentResourceName()}/gui:remove_focus`, JSON.stringify({}));
    }
}