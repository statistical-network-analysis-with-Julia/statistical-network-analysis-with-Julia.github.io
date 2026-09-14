(() => {
    "use strict";

    // Keep absolute ecosystem links on this origin in the combined preview.
    // Hash-only Documenter permalinks retain their native click handling.
    document.querySelectorAll("a[href]").forEach((anchor) => {
        const href = anchor.getAttribute("href");
        if (
            !/^https?:\/\/statistical-network-analysis-with-julia\.github\.io(?:\/|$)/i.test(
                href,
            )
        )
            return;
        const url = new URL(href);
        if (
            url.hostname.toLowerCase() ===
            "statistical-network-analysis-with-julia.github.io"
        ) {
            anchor.setAttribute("href", url.pathname + url.search + url.hash);
        }
    });

    document.documentElement.classList.add("has-js");
    const menu = document.querySelector(".menu-toggle");
    const navigation = document.querySelector(".site-navigation");
    if (menu && navigation) {
        menu.hidden = false;
        menu.addEventListener("click", () => {
            const open = menu.getAttribute("aria-expanded") !== "true";
            menu.setAttribute("aria-expanded", String(open));
            navigation.classList.toggle("is-open", open);
        });
        document.addEventListener("keydown", (event) => {
            if (
                event.key === "Escape" &&
                menu.getAttribute("aria-expanded") === "true"
            ) {
                menu.setAttribute("aria-expanded", "false");
                navigation.classList.remove("is-open");
                menu.focus();
            }
        });
        navigation.querySelectorAll("a").forEach((link) => {
            if (
                link.origin === location.origin &&
                location.pathname.startsWith(link.pathname)
            ) {
                link.setAttribute("aria-current", "page");
            }
        });
    }

    const sectionLinks = [...document.querySelectorAll('.sidebar a[href^="#"]')]
        .map((link) => ({
            link,
            section: document.getElementById(link.hash.slice(1)),
        }))
        .filter((item) => item.section);
    if (sectionLinks.length) {
        let scheduled = false;
        const updateSection = () => {
            scheduled = false;
            let current = sectionLinks[0];
            for (const item of sectionLinks) {
                if (item.section.getBoundingClientRect().top <= 140)
                    current = item;
            }
            sectionLinks.forEach((item) => {
                item.link.classList.toggle("active", item === current);
                if (item === current)
                    item.link.setAttribute("aria-current", "location");
                else item.link.removeAttribute("aria-current");
            });
        };
        window.addEventListener(
            "scroll",
            () => {
                if (!scheduled) {
                    scheduled = true;
                    requestAnimationFrame(updateSection);
                }
            },
            { passive: true },
        );
        updateSection();
    }

    const search = document.querySelector("#package-search");
    const group = document.querySelector("#package-group");
    if (search && group) {
        const cards = [...document.querySelectorAll("[data-package]")];
        const status = document.querySelector("#catalog-status");
        const empty = document.querySelector("#catalog-empty");
        const update = () => {
            const words = search.value
                .trim()
                .toLowerCase()
                .split(/\s+/)
                .filter(Boolean);
            let count = 0;
            cards.forEach((card) => {
                const matches =
                    (!group.value || card.dataset.group === group.value) &&
                    words.every((word) =>
                        (card.textContent + " " + card.dataset.keywords)
                            .toLowerCase()
                            .includes(word),
                    );
                card.hidden = !matches;
                count += Number(matches);
            });
            status.textContent = `${count} of ${cards.length} packages shown`;
            empty.hidden = count !== 0;
            const query = new URLSearchParams();
            if (search.value.trim()) query.set("q", search.value.trim());
            if (group.value) query.set("group", group.value);
            history.replaceState(
                null,
                "",
                location.pathname +
                    (query.size ? "?" + query : "") +
                    location.hash,
            );
        };
        const query = new URLSearchParams(location.search);
        search.value = query.get("q") || "";
        const requestedGroup = query.get("group") || "";
        group.value = [...group.options].some(
            (option) => option.value === requestedGroup,
        )
            ? requestedGroup
            : "";
        search.addEventListener("input", update);
        group.addEventListener("change", update);
        document
            .querySelector("#clear-filters")
            .addEventListener("click", () => {
                search.value = "";
                group.value = "";
                update();
                search.focus();
            });
        document.querySelector(".catalog-controls").hidden = false;
        update();
    }

    document.querySelectorAll(".page-content table").forEach((table) => {
        const wrapper = document.createElement("div");
        wrapper.className = "table-scroll";
        wrapper.setAttribute("role", "region");
        wrapper.setAttribute("aria-label", "Scrollable table");
        wrapper.tabIndex = 0;
        table.before(wrapper);
        wrapper.append(table);
    });

    document.querySelectorAll("pre").forEach((pre) => {
        pre.tabIndex = 0;
        pre.setAttribute("role", "region");
        pre.setAttribute("aria-label", "Code example");
    });

    if (navigator.clipboard && window.isSecureContext) {
        document.querySelectorAll("pre > code").forEach((code) => {
            const pre = code.parentElement;
            const wrapper = document.createElement("div");
            wrapper.className = "code-wrap";
            pre.before(wrapper);
            wrapper.append(pre);
            const button = document.createElement("button");
            button.className = "copy-code";
            button.textContent = "Copy";
            button.setAttribute("aria-label", "Copy code to clipboard");
            button.addEventListener("click", async () => {
                try {
                    await navigator.clipboard.writeText(code.textContent);
                    button.textContent = "Copied";
                    button.setAttribute("aria-label", "Copied to clipboard");
                } catch {
                    button.textContent = "Select code to copy";
                    button.setAttribute("aria-label", "Select code to copy");
                }
                setTimeout(() => {
                    button.textContent = "Copy";
                    button.setAttribute("aria-label", "Copy code to clipboard");
                }, 2500);
            });
            wrapper.append(button);
        });
    }
})();
