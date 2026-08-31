/*
----------------------------------------
RIG Framework (built for CFX Platforms)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig
License: https://github.com/rig-fivem/rig/blob/main/LICENSE
----------------------------------------
*/

export function extract_dataset($el) {
    const data = {};
    $.each($el.data(), (k, v) => {
        const snake_key = k.replace(/([A-Z])/g, '_$1').toLowerCase();
        data[snake_key] = v;
    });
    return data;
}

export async function send_nui_callback(action, dataset = {}, additional = {}) {
    const payload = {
        action,
        dataset,
        should_close: additional.should_close || false
    };

    const res = await fetch(`https://${GetParentResourceName()}/nui:handler`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
    });

    if (!res.ok) return null;
    return await res.json();
}

export function resolve_image_path(image, base = "/ui/assets/images/") {
    if (!image || typeof image !== "string") return "";
    if (/^(gui:\/\/|https?:\/\/)/i.test(image)) return image;
    if (/^\//.test(image)) return image;
    return base + image;
}

export function get_base_path() {
    const url = new URL(import.meta.url);
    const match = url.pathname.match(/^(.*?)(\/ui\/)/);
    return match ? match[1] : "";
}