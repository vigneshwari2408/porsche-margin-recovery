/* Small, dependency-free SVG chart kit. Every chart renders at its container's
   real pixel width, so text stays legible on phones, and re-renders on resize. */
(function () {
  "use strict";
  const NS = "http://www.w3.org/2000/svg";
  const MINUS = "−";

  /* ---------- formatting (shared with main.js) ---------- */
  const nf0 = new Intl.NumberFormat("en-GB", { maximumFractionDigits: 0 });
  const rnd = v => Math.sign(v) * Math.round(Math.abs(v)); /* half away from zero, as Excel/SQL round */
  const sign = (v, s) => (v > 0 ? "+" : v < 0 ? MINUS : "") + s;
  const F = {
    int: v => nf0.format(rnd(v)),
    eur: v => (v < 0 ? MINUS : "") + nf0.format(Math.round(Math.abs(v))),
    eurS: v => sign(rnd(v), nf0.format(Math.round(Math.abs(v)))),
    pct0: v => nf0.format(Math.round(v * 100)) + "%",
    pct1: v => (v < 0 ? MINUS : "") + Math.abs(v * 100).toFixed(1) + "%",
    pct2: v => (v < 0 ? MINUS : "") + Math.abs(v * 100).toFixed(2) + "%",
    pctSigned1: v => sign(v, Math.abs(v * 100).toFixed(1) + "%"),
    pp1: v => sign(v, Math.abs(v).toFixed(1)) + " pp",
    pp2: v => sign(v, Math.abs(v).toFixed(2)) + " pp",
    k1: v => v.toFixed(1),
    /* guidance grid values arrive in percent units already */
    gp: v => (v < 0 ? MINUS : "") + Math.abs(v).toFixed(2) + "%",
  };

  /* ---------- helpers ---------- */
  function el(tag, attrs, parent) {
    const n = document.createElementNS(NS, tag);
    if (attrs) for (const k in attrs) if (attrs[k] !== undefined && attrs[k] !== null) n.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(n);
    return n;
  }
  function txt(parent, x, y, s, attrs) { const t = el("text", Object.assign({ x, y }, attrs || {}), parent); t.textContent = s; return t; }
  function scale(d0, d1, r0, r1) { const k = (r1 - r0) / (d1 - d0 || 1); const f = v => r0 + (v - d0) * k; f.inv = p => d0 + (p - r0) / k; return f; }
  function nice(lo, hi, n) {
    const span = hi - lo, step0 = span / (n || 5), mag = Math.pow(10, Math.floor(Math.log10(step0)));
    const step = [1, 2, 2.5, 5, 10].map(m => m * mag).find(s => s >= step0) || mag * 10;
    const a = Math.floor(lo / step) * step, b = Math.ceil(hi / step) * step, ticks = [];
    for (let v = a; v <= b + step / 2; v += step) ticks.push(+v.toFixed(10));
    return { lo: a, hi: b, ticks };
  }
  function svgFor(host, h) {
    host.innerHTML = "";
    const w = Math.max(280, host.clientWidth || 600);
    const s = el("svg", { viewBox: `0 0 ${w} ${h}`, width: w, height: h, "aria-hidden": "true", focusable: "false" }, host);
    const defs = el("defs", null, s);
    const hp = (id, color, gap) => {
      const p = el("pattern", { id, width: gap, height: gap, patternUnits: "userSpaceOnUse", patternTransform: "rotate(45)" }, defs);
      el("rect", { width: gap, height: gap, fill: "rgba(6,3,4,.2)" }, p);
      el("line", { x1: 0, y1: 0, x2: 0, y2: gap, stroke: color, "stroke-width": 1.4 }, p);
    };
    hp("hatch-res", "#C9B9B4", 5); hp("hatch-scn", "rgba(238,230,226,.55)", 6);
    return { s, w, h };
  }

  /* ---------- tooltip ---------- */
  const tip = () => document.getElementById("tip");
  function showTip(html, x, y) {
    const t = tip(); if (!t) return;
    t.innerHTML = html; t.classList.add("show");
    const r = t.getBoundingClientRect(), vw = window.innerWidth;
    let left = x + 14, top = y - r.height - 12;
    if (left + r.width > vw - 8) left = x - r.width - 14;
    if (top < 70) top = y + 18;
    t.style.transform = `translate(${Math.max(8, left)}px, ${top}px)`;
  }
  function hideTip() { const t = tip(); if (t) t.classList.remove("show"); }
  function bindTip(node, html) {
    node.addEventListener("pointermove", e => showTip(typeof html === "function" ? html() : html, e.clientX, e.clientY));
    node.addEventListener("pointerleave", hideTip);
    node.addEventListener("pointerdown", e => showTip(typeof html === "function" ? html() : html, e.clientX, e.clientY));
  }

  /* ---------- line chart (margins, cash) ---------- */
  function line(host, o) {
    const narrow = host.clientWidth < 560;
    const H = o.height || (narrow ? 300 : 380);
    const { s, w, h } = svgFor(host, H);
    const m = { t: 18, r: narrow ? 84 : 110, b: 40, l: 46 };
    const all = o.series.flatMap(se => se.values);
    const ax = nice(Math.min(0, ...all), Math.max(...all), 5);
    const x = scale(0, o.labels.length - 1, m.l, w - m.r), y = scale(ax.lo, ax.hi, h - m.b, m.t);
    const g = el("g", { class: "grid" }, s);
    ax.ticks.forEach(t => {
      el("line", { x1: m.l, x2: w - m.r, y1: y(t), y2: y(t) }, g);
      txt(s, m.l - 8, y(t) + 4, o.yfmt(t), { "text-anchor": "end" });
    });
    if (ax.lo < 0) el("line", { class: "zero", x1: m.l, x2: w - m.r, y1: y(0), y2: y(0) }, s);
    el("line", { class: "axis-base", x1: m.l, x2: w - m.r, y1: h - m.b + .5, y2: h - m.b + .5 }, s);
    o.labels.forEach((lab, i) => {
      if (narrow && i % 2 === 1 && i !== o.labels.length - 1) return;
      txt(s, x(i), h - m.b + 22, narrow ? lab.replace(" 20", " ’") : lab, { "text-anchor": "middle" });
    });
    // shaded marker for derived half-years
    const ends = [];
    o.series.forEach(se => {
      const gg = el("g", { "data-key": se.key, class: se.off ? "is-off" : "" }, s);
      const d = se.values.map((v, i) => (i ? "L" : "M") + x(i).toFixed(1) + "," + y(v).toFixed(1)).join("");
      const p = el("path", { d, class: "line " + se.cls }, gg);
      if (o.animate) { const L = p.getTotalLength(); p.style.strokeDasharray = L; p.style.strokeDashoffset = L; p.getBoundingClientRect(); p.style.transition = "stroke-dashoffset 1.8s cubic-bezier(.2,.7,.1,1)"; requestAnimationFrame(() => (p.style.strokeDashoffset = 0)); }
      se.values.forEach((v, i) => el("circle", { cx: x(i), cy: y(v), r: i === se.values.length - 1 ? 4.5 : 3, class: "dot " + se.cls }, gg));
      ends.push({ key: se.key, gg, y: y(se.values[se.values.length - 1]), label: (narrow ? se.short : se.name) + " " + o.yfmt(se.values[se.values.length - 1], true), cls: se.cls, off: se.off });
    });
    // direct end labels, nudged apart
    const vis = ends.filter(e => !e.off).sort((a, b) => a.y - b.y);
    for (let i = 1; i < vis.length; i++) if (vis[i].y - vis[i - 1].y < 15) vis[i].y = vis[i - 1].y + 15;
    vis.forEach(e => txt(e.gg, w - m.r + 10, e.y + 4, e.label, { class: "t-strong", fill: e.cls === "s-l1" ? "#ff5a67" : undefined }));
    // hover columns
    const hv = el("line", { x1: 0, x2: 0, y1: m.t, y2: h - m.b, stroke: "rgba(238,230,226,.25)", opacity: 0 }, s);
    o.labels.forEach((lab, i) => {
      const cw = (w - m.l - m.r) / (o.labels.length - 1);
      const r = el("rect", { class: "hit", x: x(i) - cw / 2, y: m.t, width: cw, height: h - m.t - m.b }, s);
      bindTip(r, () => `<b>${lab}</b>${o.derived && o.derived(i) ? '<span class="tip-sub">H2 derived as FY − H1</span>' : ""}` +
        o.series.filter(se => !se.off).map(se => `<span style="display:block">${se.name}: <b>${o.yfmt(se.values[i], true)}</b></span>`).join(""));
      r.addEventListener("pointerenter", () => { hv.setAttribute("x1", x(i)); hv.setAttribute("x2", x(i)); hv.setAttribute("opacity", 1); });
      r.addEventListener("pointerleave", () => hv.setAttribute("opacity", 0));
    });
  }

  /* ---------- horizontal waterfall (EBIT bridge) ---------- */
  function waterfall(host, o) {
    const narrow = host.clientWidth < 620;
    const rowH = narrow ? 50 : 46, n = o.items.length;
    const H = n * rowH + 36;
    const { s, w, h } = svgFor(host, H);
    const lw = narrow ? Math.min(150, w * .42) : Math.min(300, w * .34);
    const m = { l: lw + 16, r: narrow ? 56 : 80, t: 8 };
    // cumulative positions
    const groups = [];
    let run = 0; const rows = o.items.map(it => {
      if (it.kind === "total") { run = it.v; return Object.assign({ a: 0, b: it.v }, it); }
      const a = run; run += it.v; return Object.assign({ a, b: run }, it);
    });
    const lo = Math.min(0, ...rows.map(r => Math.min(r.a, r.b))), hi = Math.max(...rows.map(r => Math.max(r.a, r.b)));
    const x = scale(lo, hi * 1.02, m.l, w - m.r);
    el("line", { class: "axis-base", x1: x(0), x2: x(0), y1: m.t - 4, y2: h - 24 }, s);
    rows.forEach((r, i) => {
      const g = el("g", { class: "bstep" + (o.shown === false ? "" : " is-shown"), "data-k": r.key || r.kind }, s); groups.push(g);
      const y0 = m.t + i * rowH, bh = rowH - 18;
      const label = narrow && r.short ? r.short : r.label;
      // label (wrap to two lines if needed)
      const words = label.split(" "); let l1 = "", l2 = ""; const maxc = Math.floor(lw / 7.2);
      words.forEach(wd => { if ((l1 + " " + wd).trim().length <= maxc && !l2) l1 = (l1 + " " + wd).trim(); else l2 = (l2 + " " + wd).trim(); });
      const cls = r.kind === "total" ? "t-strong" : "";
      if (l2) { txt(g, 0, y0 + bh / 2 - 2, l1, { class: cls }); txt(g, 0, y0 + bh / 2 + 12, l2, { class: cls }); }
      else txt(g, 0, y0 + bh / 2 + 4, l1, { class: cls });
      const xa = x(Math.min(r.a, r.b)), xb = x(Math.max(r.a, r.b));
      const bw = Math.max(r.v === 0 ? 0 : 2, xb - xa);
      const rect = el("rect", { class: "bar b-" + r.kind, x: xa, y: y0, width: bw, height: bh, rx: 1 }, g);
      if (r.v === 0 && r.kind !== "total") el("line", { x1: x(r.a), x2: x(r.a), y1: y0 - 2, y2: y0 + bh + 2, stroke: "var(--signal)", "stroke-width": 2 }, g);
      const vs = r.kind === "total" ? o.fmtTotal(r.v) : o.fmt(r.v);
      txt(g, Math.max(xa, xb) + 8, y0 + bh / 2 + 4, vs, { class: r.kind === "total" ? "t-strong" : r.v < 0 ? "t-red" : "t-strong" });
      if (i < rows.length - 1) el("line", { class: "conn", x1: x(r.b), x2: x(r.b), y1: y0 + bh, y2: y0 + rowH }, g);
      bindTip(rect, `<b>${r.label}</b><span class="tip-sub">${o.kindLabel[r.kind]}</span>${vs}${o.unitLabel}`);
    });
    txt(s, x(0), h - 6, "0", { "text-anchor": "middle" });
    return { groups, rows,
      show(n) { groups.forEach((g, i) => g.classList.toggle("is-shown", i < n)); },
      mark(keys) { host.toggleAttribute("data-hl", !!keys); groups.forEach(g => g.classList.toggle("is-hl", !!keys && keys.includes(g.dataset.k))); } };
  }

  /* ---------- grouped / single columns ---------- */
  function columns(host, o) {
    const narrow = host.clientWidth < 520;
    const H = o.height || (narrow ? 240 : 280);
    const { s, w, h } = svgFor(host, H);
    const m = { t: 22, r: 8, b: 38, l: o.yw || 44 };
    const maxv = Math.max(...o.series.flatMap(se => o.stack ? o.labels.map((_, i) => o.series.reduce((a, q) => a + q.values[i], 0)) : se.values));
    const ax = nice(o.min || 0, maxv, 4);
    const y = scale(ax.lo, ax.hi, h - m.b, m.t);
    const bandW = (w - m.l - m.r) / o.labels.length, inner = bandW * (narrow ? .78 : .66);
    const g = el("g", { class: "grid" }, s);
    ax.ticks.forEach(t => { el("line", { x1: m.l, x2: w - m.r, y1: y(t), y2: y(t) }, g); txt(s, m.l - 8, y(t) + 4, o.yfmt(t), { "text-anchor": "end" }); });
    el("line", { class: "axis-base", x1: m.l, x2: w - m.r, y1: y(ax.lo) + .5, y2: y(ax.lo) + .5 }, s);
    const groups = [];
    o.labels.forEach((lab, i) => {
      const gx = m.l + i * bandW + (bandW - inner) / 2;
      const gg = el("g", { "data-i": i }, s); groups.push(gg);
      if (o.stack) {
        let acc = 0;
        o.series.forEach(se => {
          const v = se.values[i]; if (!v) return;
          el("rect", { class: "bar " + se.cls, x: gx, y: y(acc + v), width: inner, height: y(acc) - y(acc + v) }, gg); acc += v;
        });
        if (o.topLabel) txt(gg, gx + inner / 2, y(acc) - 6, o.topLabel(i), { "text-anchor": "middle", class: "t-strong" });
      } else {
        const k = o.series.length, bw = inner / k;
        o.series.forEach((se, j) => {
          const v = se.values[i];
          const cls = typeof se.cls === "function" ? se.cls(i) : se.cls;
          el("rect", { class: "bar " + cls, x: gx + j * bw + (k > 1 ? 1 : 0), y: y(Math.max(0, v)), width: bw - (k > 1 ? 2 : 0), height: Math.abs(y(v) - y(0)) }, gg);
        });
        if (o.topLabel) { const t = o.topLabel(i); if (t) txt(gg, gx + inner / 2, y(Math.max(...o.series.map(se => se.values[i]))) - 6, t, { "text-anchor": "middle", class: o.topCls ? o.topCls(i) : "t-strong" }); }
      }
      if (!(narrow && i % 2 === 1 && i !== o.labels.length - 1)) txt(gg, m.l + i * bandW + bandW / 2, h - m.b + 20, narrow ? lab.replace(" 20", " ’") : lab, { "text-anchor": "middle" });
      const hit = el("rect", { class: "hit", x: m.l + i * bandW, y: m.t, width: bandW, height: h - m.t - m.b }, gg);
      bindTip(hit, () => `<b>${lab}</b>${o.derived && o.derived(i) ? '<span class="tip-sub">H2 derived as FY − H1</span>' : ""}` + o.series.map(se => `<span style="display:block">${se.name}: <b>${o.tfmt(se.values[i])}</b></span>`).join("") + (o.tipExtra ? o.tipExtra(i) : ""));
    });
    return { groups, highlight(i) { groups.forEach((gg, j) => gg.setAttribute("class", i == null ? "" : j === i ? "hl" : "dim")); },
      mark(idx) { groups.forEach((gg, j) => gg.classList.toggle("col-hl", !!idx && idx.includes(j))); } };
  }

  /* ---------- paired horizontal bars (mix) ---------- */
  function pairs(host, o) {
    const narrow = host.clientWidth < 560;
    const rowH = 46, H = o.rows.length * rowH + 30;
    const { s, w, h } = svgFor(host, H);
    const lw = narrow ? 138 : 200, m = { l: lw, r: narrow ? 96 : 130, t: 24 };
    const max = Math.max(...o.rows.flatMap(r => [r.cur, r.py]));
    const x = scale(0, max * 1.04, m.l, w - m.r);
    txt(s, m.l, 12, o.curLabel, { class: "t-red" });
    txt(s, m.l + (narrow ? 80 : 90), 12, o.pyLabel, {});
    el("rect", { x: m.l - 14, y: 4, width: 9, height: 9, class: "b-cur" }, s);
    el("rect", { x: m.l + (narrow ? 66 : 76), y: 4, width: 9, height: 9, class: "b-py" }, s);
    el("line", { class: "axis-base", x1: x(0), x2: x(0), y1: m.t - 2, y2: h - 4 }, s);
    o.rows.forEach((r, i) => {
      const y0 = m.t + i * rowH + 6, g = el("g", { class: "mrow" }, s);
      g.addEventListener("pointerenter", () => { s.classList.add("has-hl"); g.classList.add("is-hl"); });
      g.addEventListener("pointerleave", () => { s.classList.remove("has-hl"); g.classList.remove("is-hl"); });
      txt(g, 0, y0 + 15, r.name, { class: "t-strong" });
      const bc = el("rect", { class: "bar b-cur", x: x(0), y: y0, width: 0, height: 13 }, g);
      const bp = el("rect", { class: "bar b-py", x: x(0), y: y0 + 16, width: 0, height: 8 }, g);
      requestAnimationFrame(() => { bc.style.transition = bp.style.transition = "width .9s cubic-bezier(.2,.7,.1,1)"; bc.setAttribute("width", x(r.cur) - x(0)); bp.setAttribute("width", x(r.py) - x(0)); });
      const d = (r.cur - r.py) * 100;
      txt(g, x(r.cur) + 8, y0 + 11, F.pct1(r.cur), { class: "t-strong" });
      txt(g, w - 2, y0 + 15, F.pp1(d), { "text-anchor": "end", class: d < 0 ? "t-red" : "t-strong" });
      const hit = el("rect", { class: "hit", x: 0, y: y0 - 6, width: w, height: rowH }, g);
      bindTip(hit, `<b>${r.name}</b><span style="display:block">${o.curLabel}: <b>${F.pct1(r.cur)}</b></span><span style="display:block">${o.pyLabel}: <b>${F.pct1(r.py)}</b></span><span style="display:block">Change: <b>${F.pp1(d)}</b></span>`);
    });
  }

  /* ---------- range chart (scenarios) ---------- */
  function ranges(host, o) {
    const narrow = host.clientWidth < 560;
    const rowH = narrow ? 76 : 70, H = o.rows.length * rowH + 44;
    const { s, w, h } = svgFor(host, H);
    const m = { l: narrow ? 64 : 150, r: 20, t: 10, b: 30 };
    const vals = o.rows.flatMap(r => [r.min, r.max, r.h1, ...(r.points || [])]);
    const ax = nice(Math.min(...vals), Math.max(...vals), narrow ? 4 : 7);
    const x = scale(ax.lo, ax.hi, m.l, w - m.r);
    const g = el("g", { class: "grid" }, s);
    ax.ticks.forEach(t => { el("line", { x1: x(t), x2: x(t), y1: m.t, y2: h - m.b }, g); txt(s, x(t), h - 10, (t < 0 ? "\u2212" : "") + Math.abs(Math.round(t * 10) / 10) + "%", { "text-anchor": "middle" }); });
    if (ax.lo < 0) el("line", { class: "zero", x1: x(0), x2: x(0), y1: m.t, y2: h - m.b }, s);
    el("line", { class: "axis-base", x1: m.l, x2: w - m.r, y1: h - m.b + .5, y2: h - m.b + .5 }, s);
    const rings = [];
    o.rows.forEach((r, i) => {
      const cy = m.t + i * rowH + rowH / 2, gg = el("g", null, s);
      txt(gg, 0, cy - 2, narrow ? r.short : r.name, { class: "t-strong" });
      if (!narrow && r.sub) txt(gg, 0, cy + 14, r.sub, {});
      const band = el("rect", { class: "band-range", x: x(r.min), y: cy - 13, width: Math.max(2, x(r.max) - x(r.min)), height: 26, rx: 1 }, gg);
      (r.points || []).forEach(p => el("line", { x1: x(p), x2: x(p), y1: cy - 9, y2: cy + 9, stroke: "rgba(238,230,226,.45)", "stroke-width": 1 }, gg));
      const dm = x(r.mid);
      el("path", { class: "mid-diamond", d: `M${dm},${cy - 8}L${dm + 8},${cy}L${dm},${cy + 8}L${dm - 8},${cy}Z` }, gg);
      el("line", { class: "h1-line", x1: x(r.h1), x2: x(r.h1), y1: cy - 22, y2: cy + 22 }, gg);
      txt(gg, x(r.h1), cy - 26, (narrow ? "H1 " : "H1 2026 ") + F.gp(r.h1), { "text-anchor": x(r.h1) > w - 90 ? "end" : "middle", class: "t-strong", "font-size": 11 });
      txt(gg, x(r.min) - 6, cy + 4, F.gp(r.min), { "text-anchor": "end", "font-size": 11 });
      txt(gg, x(r.max) + 6, cy + 4, F.gp(r.max), { "font-size": 11 });
      if (r.sel != null) rings.push(el("circle", { class: "sel-ring", cx: x(r.sel), cy, r: 11 }, gg));
      bindTip(band, `<b>${r.name}</b><span class="tip-sub">Arithmetic only, not a forecast</span>Min ${F.gp(r.min)}, all midpoints ${F.gp(r.mid)}, max ${F.gp(r.max)}<span style="display:block">H1 2026 actual: <b>${F.gp(r.h1)}</b></span>`);
    });
    return { update(sel) { rings.forEach((c, i) => c.setAttribute("cx", x(sel[i]))); } };
  }

  /* ---------- simple horizontal bars (reconciliation) ---------- */
  function hbars(host, o) {
    const narrow = host.clientWidth < 480;
    const rowH = 38, H = o.rows.length * rowH + 10;
    const { s, w } = svgFor(host, H);
    const lw = narrow ? 140 : 180, max = Math.max(...o.rows.map(r => r[1]));
    const x = scale(0, max, lw, w - 60);
    el("line", { class: "axis-base", x1: lw, x2: lw, y1: 0, y2: H - 6 }, s);
    o.rows.forEach((r, i) => {
      const y0 = i * rowH + 8;
      txt(s, 0, y0 + 14, r[0], { class: "t-strong" });
      const b = el("rect", { class: "bar b-recon", x: lw, y: y0 + 2, width: 0, height: 16 }, s);
      requestAnimationFrame(() => { b.style.transition = `width 1s ${i * .1}s cubic-bezier(.2,.7,.1,1)`; b.setAttribute("width", x(r[1]) - lw); });
      txt(s, x(r[1]) + 8, y0 + 15, F.int(r[1]), { class: "t-strong" });
      bindTip(b, `<b>${r[0]}</b>${F.int(r[1])} comparisons, 0 failures`);
    });
  }

  window.PCLCharts = { F, line, waterfall, columns, pairs, ranges, hbars, hideTip };
})();
