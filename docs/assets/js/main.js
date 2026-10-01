/* Page behaviour. All figures come from window.PCL (generated from the final,
   reconciled project outputs by tools/build_data.py). Nothing numeric is typed here
   except structural counts that are themselves in the data (e.g. number of combinations). */
(function () {
  "use strict";
  const P = window.PCL, C = window.PCLCharts, F = C.F, LINKS = window.PCL_LINKS || {};
  const $ = (s, r) => (r || document).querySelector(s), $$ = (s, r) => Array.from((r || document).querySelectorAll(s));
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const get = path => path.split(".").reduce((o, k) => (o == null ? o : o[k]), P);
  const isH2 = i => P.periods[i].startsWith("H2");
  const eurS = v => F.eurS(v), eur = v => (v < 0 ? "\u2212" : "") + "€" + F.int(Math.abs(v)) + "m";
  const eurSm = v => (Math.round(Math.abs(v)) === 0 ? "" : v > 0 ? "+" : "\u2212") + "€" + F.int(Math.abs(v)) + "m";
  const niceEur = s => s.replace(/EUR /g, "€").replace(/ x /g, " × ").replace(/€~/g, "~€").replace(/ -> /g, " → ").replace(/\+\/-/g, "±").replace(/(\d)-(\d)/g, "$1–$2").replace(/\.\.(?=\d)/g, " to ");
  const fmts = Object.assign({}, F, { ppAbs2: v => Math.abs(v).toFixed(2), pctAbs1: v => Math.abs(v * 100).toFixed(1) + "%" });

  /* ------------------------------------------------ bound values */
  $$("[data-v]").forEach(n => { const v = get(n.dataset.v); if (v != null) n.textContent = fmts[n.dataset.fmt || "int"](v); });
  const countMap = { m0py: "kpi.m0.0", m0: "kpi.m0.1", m1py: "kpi.m1.0", m1: "kpi.m1.1" };
  const counters = $$("[data-count]").map(n => { const v = get(countMap[n.dataset.count] || n.dataset.count); n.textContent = fmts[n.dataset.fmt](v); return { n, v, f: fmts[n.dataset.fmt] }; });
  function countUp(c) {
    if (reduce) return;
    const t0 = performance.now(), d = 1400;
    const step = t => { const k = Math.min(1, (t - t0) / d), e = 1 - Math.pow(1 - k, 3); c.n.textContent = c.f(c.v * e); if (k < 1) requestAnimationFrame(step); else c.n.textContent = c.f(c.v); };
    requestAnimationFrame(step);
  }

  /* ------------------------------------------------ 02 overview: KPIs + margin chart */
  const K = P.kpi;
  const kpis = [
    { t: "Group revenue", n: K.revenue[1], f: eur, d: `${P.prior}: ${eur(K.revenue[0])}` },
    { t: "Reported EBIT (L0)", n: K.l0[1], f: eur, d: `${eurSm(K.yoy_l0)} year on year`, c: "pos", line: "l0" },
    { t: "Reported margin (L0)", n: K.m0[1], f: F.pct1, d: F.pp2(K.yoy_m0_pp) + " year on year", c: "pos", line: "l0" },
    { t: "Underlying margin (L1)", n: K.m1[1], f: F.pct1, d: F.pp2(K.yoy_m1_pp) + " year on year", c: "neg", lv: "lvl-l1", line: "l1" },
    { t: "Margin excl. tariffs too (L2)", n: K.m2[1], f: F.pct1, d: F.pp2(K.yoy_m2_pp) + " year on year", c: "neg", line: "l2" },
    { t: "Automotive net cash flow margin", n: K.ncfm[1], f: F.pct1, d: `${P.prior}: ${F.pct1(K.ncfm[0])}`, c: "pos" },
  ];
  const disc = `<svg class="disc-mini" viewBox="0 0 22 22" aria-hidden="true"><circle cx="11" cy="11" r="10" stroke-width="1"/><circle cx="11" cy="11" r="4" stroke-width="1"/>${[0, 1, 2, 3, 4, 5].map(k => { const a = k * Math.PI / 3; return `<circle class="h" cx="${(11 + 7 * Math.cos(a)).toFixed(2)}" cy="${(11 + 7 * Math.sin(a)).toFixed(2)}" r="1"/>`; }).join("")}</svg>`;
  $("#kpis").innerHTML = kpis.map((k, i) => `<div class="${k.lv || ""}" ${k.line ? `data-line="${k.line}"` : ""}>${disc}<dt>${k.t}, ${P.latest}</dt><dd><span class="kv" data-kpi="${i}">${k.f(k.n)}</span><span class="delta ${k.c || ""}">${k.d}</span></dd></div>`).join("");

  const marginSeries = [
    { key: "l0", name: "L0 reported", short: "L0", cls: "s-l0", values: P.margins.l0 },
    { key: "l1", name: "L1 underlying", short: "L1", cls: "s-l1", values: P.margins.l1 },
    { key: "l2", name: "L2 excl. tariffs", short: "L2", cls: "s-l2", values: P.margins.l2 },
  ];
  let marginsAnimated = false;
  function drawMargins(animate) {
    C.line($("#chart-margins"), { labels: P.periods, series: marginSeries, yfmt: (v, d) => d ? F.pct1(v) : (v < 0 ? "−" : "") + Math.abs(Math.round(v * 100)) + "%", derived: isH2, animate });
  }
  $("#margin-legend").innerHTML = marginSeries.map(s => `<button type="button" aria-pressed="true" data-key="${s.key}"><i style="background:var(--${s.key === "l0" ? "bone" : s.key === "l1" ? "signal" : "rose"})"></i>${s.name}</button>`).join("");
  $$("#margin-legend button").forEach(b => b.addEventListener("click", () => {
    const s = marginSeries.find(x => x.key === b.dataset.key);
    if (!s.off && marginSeries.filter(x => !x.off).length === 1) return; // keep at least one line
    s.off = !s.off; b.setAttribute("aria-pressed", String(!s.off)); drawMargins(false);
  }));
  const marginHost = $("#chart-margins");
  $$("#kpis > div[data-line]").forEach(c => {
    c.addEventListener("pointerenter", () => { const s = marginSeries.find(x => x.key === c.dataset.line); if (!s.off) marginHost.dataset.focus = c.dataset.line; });
    c.addEventListener("pointerleave", () => { delete marginHost.dataset.focus; });
  });
  $("#table-margins").innerHTML = `<div class="table-wrap"><table><thead><tr><th>Half-year</th><th>Revenue €m</th><th>L0 EBIT €m</th><th>L0 margin</th><th>L1 margin</th><th>L2 margin</th></tr></thead><tbody>` +
    P.periods.map((p, i) => `<tr><th>${p}${isH2(i) ? " *" : ""}</th><td>${F.int(P.ebit.l0[i] / P.margins.l0[i])}</td><td>${F.eur(P.ebit.l0[i])}</td><td>${F.pct1(P.margins.l0[i])}</td><td>${F.pct1(P.margins.l1[i])}</td><td>${F.pct1(P.margins.l2[i])}</td></tr>`).join("") +
    `</tbody></table></div><p class="footnote">* H2 derived as FY − H1. L1 = L0 + realignment and battery items (net). L2 = L1 + US import tariffs. Before H1 2025 no such items were disclosed (A-01, A-02), so the three levels coincide.</p>`;

  /* ------------------------------------------------ 03 EBIT: level build + bridge */
  const LB = P.levelBridge;
  $("#level-bridge").innerHTML = [
    ["lv", "L0 reported EBIT", eur(LB.l0), `As published by Porsche, ${P.latest}. Margin ${F.pct1(K.m0[1])}.`],
    ["lv lv-step", "Add back realignment and battery items (net)", eurSm(LB.realign), "Disclosed by Porsche, rounded to €0.1bn."],
    ["lv l1", "L1 underlying EBIT", eur(K.l1[1]), `The headline underlying KPI. Margin ${F.pct1(K.m1[1])}.`],
    ["lv lv-step", "Add back US import tariffs", eurSm(LB.tariffs), "Disclosed by Porsche."],
    ["lv", "L2 EBIT excluding tariffs", eur(LB.l2), `Margin ${F.pct1(K.m2[1])}.`],
  ].map(r => `<div class="${r[0]}"><span class="lv-name">${r[1]}</span><span class="lv-val">${r[2]}</span><span class="lv-desc">${r[3]}</span></div>`).join("");

  const short = { start: "EBIT " + P.prior, exc: "Exceptional items", tar: "US tariffs", cap: "Capitalised dev. costs", da: "Clean D&A", fs: "Financial Services", res: "Residual", end: "EBIT " + P.latest };
  const kindLabel = { total: "Reported EBIT", adjust: "Disclosed one-off", accounting: "Accounting effect, non-cash", segment: "Financial Services segment", residual: "Residual: not separable with published data", denom: "Revenue denominator effect" };
  let bridgeUnit = "eur";
  const bridgeHost = $("#chart-bridge");
  const stageName = { total: null, adjust: "One-offs", accounting: "Accounting effects", segment: "Financial Services", residual: "Residual", denom: "Revenue denominator" };
  let bridgeCtl = null, bridgeShown = 0, bridgeItems = [];
  function drawBridge() {
    let items, o;
    if (bridgeUnit === "eur") {
      items = P.bridge.map(b => Object.assign({ short: short[b.key] }, b));
      o = { fmt: eurS, fmtTotal: v => F.eur(v), unitLabel: " € million" };
      $("#bridge-note").textContent = `The bridge closes exactly: ${F.eur(P.bridge[0].v)} + the six steps = ${F.eur(K.l0[1])}. The residual is ${eurSm(P.bridge[6].v)} under assumption A-04, and stays negative (${eurSm(P.residualAltA04)}) if the €61m of H1 2026 impairments are not inside automotive D&A. Tariffs were €0.4bn in both halves, so their year-on-year effect is zero.`;
    } else {
      const kinds = ["denom", "adjust", "adjust", "accounting", "accounting", "segment", "residual"];
      const sh = ["Revenue denominator", "Exceptional items", "US tariffs", "Capitalised dev. costs", "Clean D&A", "Financial Services", "Residual"];
      items = [{ label: `L0 margin ${P.prior}`, short: `Margin ${P.prior}`, v: K.m0[0] * 100, kind: "total" }]
        .concat(P.bridgePP.map((b, i) => ({ label: b.label, short: sh[i], v: b.v, kind: kinds[i] })))
        .concat([{ label: `L0 margin ${P.latest}`, short: `Margin ${P.latest}`, v: K.m0[1] * 100, kind: "total" }]);
      o = { fmt: v => F.pp2(v), fmtTotal: v => v.toFixed(2) + "%", unitLabel: "" };
      $("#bridge-note").textContent = `In margin points the same bridge gains one step: the revenue denominator, which is what prior-year EBIT would be worth as a margin on this year's lower revenue. ${(K.m0[0] * 100).toFixed(2)}% + the steps = ${(K.m0[1] * 100).toFixed(2)}%.`;
    }
    bridgeItems = items;
    bridgeCtl = C.waterfall(bridgeHost, Object.assign(o, { items, kindLabel, shown: false }));
    // stage chips follow the order of the rows
    const chips = [];
    items.forEach((it, i) => {
      const name = it.kind === "total" ? (i === 0 ? "Reported EBIT" : "Final result") : stageName[it.kind];
      if (!chips.length || chips[chips.length - 1].name !== name) chips.push({ name, from: i });
    });
    $("#bridge-stages").innerHTML = chips.map(c => `<li data-from="${c.from}"><span>${c.name}</span></li>`).join("");
    const n = bridgeShown; bridgeShown = -1; showBridge(reduce ? items.length : n);
  }
  function showBridge(n) {
    n = Math.max(0, Math.min(bridgeItems.length, n)); if (n === bridgeShown) return; bridgeShown = n;
    bridgeCtl.show(n);
    const lis = $$("#bridge-stages li");
    lis.forEach((li, j) => {
      const from = +li.dataset.from, next = lis[j + 1] ? +lis[j + 1].dataset.from : bridgeItems.length;
      li.classList.toggle("is-lit", n > from); li.classList.toggle("is-now", n > from && n <= next);
    });
  }
  drawBridge();
  $$("#bridge-unit button").forEach(b => b.addEventListener("click", () => {
    bridgeUnit = b.dataset.unit; $$("#bridge-unit button").forEach(x => x.setAttribute("aria-checked", String(x === b)));
    const done = bridgeShown >= bridgeItems.length; bridgeShown = 0; drawBridge();
    if (done) { bridgeShown = -1; requestAnimationFrame(() => showBridge(bridgeItems.length)); }
  }));
  // scroll position through the panel decides how many rows are built
  function bridgeProgress(vh) {
    if (reduce) return;
    const r = bridgeHost.getBoundingClientRect();
    if (r.top > vh || r.bottom < 0) { if (r.bottom < 0) showBridge(bridgeItems.length); return; }
    const p = (vh * .88 - r.top) / (r.height * .75 + vh * .18);
    showBridge(Math.ceil(Math.max(0, Math.min(1, p)) * bridgeItems.length));
  }

  /* ------------------------------------------------ 04 R&D scrollytelling */
  const R = P.rd, RL = R.latest;
  const rdChart = () => C.columns($("#chart-rd"), {
    labels: P.periods, height: 230, yfmt: v => F.int(v), tfmt: v => "€" + F.int(v) + "m", derived: isH2,
    series: [{ name: "Total R&D costs", cls: "b-rdtotal", values: R.total }, { name: "R&D charged to the P&L", cls: "b-rdpl", values: R.pl }],
    tipExtra: i => `<span style="display:block">Capitalised: <b>€${F.int(R.cap[i])}m</b> (${F.pct1(R.rate[i])})</span>`,
  });
  let rdc = rdChart(), activeStep = -1;
  const stepText = i => {
    const p = P.periods[i], base = `R&D costs €${F.int(R.total[i])}m, of which €${F.int(R.cap[i])}m capitalised. Charged to the P&L: €${F.int(R.pl[i])}m.`;
    if (i === P.periods.length - 1) return { h: `${p}: ${F.pct1(R.rate[i])}`, t: `Down from ${F.pct1(RL.ratePY)} a year earlier. The P&L charge of €${F.int(RL.pl)}m is now above the €${F.int(RL.total)}m of R&D costs, because amortisation of past capitalisation outweighs what is capitalised today (net capitalisation ${eurSm(RL.netCap)}).`, f: `Illustrative: at the prior-year rate, the P&L charge would have been €${RL.capFx.toFixed(1)}m lower.` };
    return { h: `${p}: ${F.pct1(R.rate[i])}`, t: base, f: isH2(i) ? "H2 derived as full year minus H1." : "" };
  };
  $("#rd-steps").innerHTML = P.periods.map((p, i) => { const s = stepText(i); return `<div class="step" data-i="${i}"><h3>${s.h} capitalised</h3><p>${s.t}</p>${s.f ? `<p class="step-fig">${s.f}</p>` : ""}</div>`; }).join("");
  const dial = $("#rate-dial"), DC = { x: 120, y: 128, r: 104 };
  const pol = (a, r) => [DC.x + r * Math.cos(a), DC.y + r * Math.sin(a)];
  const ang = v => Math.PI + v * Math.PI;      // 0% at the left, 100% at the right
  (function buildDial() {
    const NS = "http://www.w3.org/2000/svg", mk = (t, a) => { const e = document.createElementNS(NS, t); for (const k in a) e.setAttribute(k, a[k]); dial.appendChild(e); return e; };
    const defs = mk("defs", {}); defs.innerHTML = '<linearGradient id="dial-grad" x1="0" x2="1"><stop offset="0" stop-color="#6b0e1b"/><stop offset="1" stop-color="#ff3345"/></linearGradient>';
    const [ax, ay] = pol(Math.PI, DC.r), [bx, by] = pol(2 * Math.PI, DC.r);
    const arc = `M${ax},${ay} A${DC.r},${DC.r} 0 0 1 ${bx},${by}`;
    mk("path", { class: "d-track", d: arc });
    dial._fill = mk("path", { class: "d-fill", d: arc, pathLength: 100, "stroke-dasharray": "100 100", "stroke-dashoffset": 100 });
    for (let v = 0; v <= 100; v += 5) {
      const major = v % 25 === 0, a = ang(v / 100), [x1, y1] = pol(a, DC.r - 10), [x2, y2] = pol(a, DC.r - (major ? 22 : 16));
      mk("line", { class: "d-tick" + (major ? " major" : ""), x1, y1, x2, y2 });
      if (major) { const [lx, ly] = pol(a, DC.r - 34); const t = mk("text", { class: "d-lab", x: lx, y: ly + 3 }); t.textContent = v + "%"; }
    }
    dial._needle = mk("line", { class: "d-needle", x1: DC.x, y1: DC.y, x2: DC.x - DC.r + 14, y2: DC.y });
    mk("circle", { class: "d-hub", cx: DC.x, cy: DC.y, r: 6 });
  })();
  function setDial(v) { dial._fill.setAttribute("stroke-dashoffset", (100 - v * 100).toFixed(2)); dial._needle.setAttribute("transform", `rotate(${(v * 180).toFixed(2)} ${DC.x} ${DC.y})`); }
  let rateShown = R.rate[0];
  function setStep(i) {
    if (i === activeStep) return; activeStep = i;
    $$("#rd-steps .step").forEach(s => s.classList.toggle("is-active", +s.dataset.i === i));
    $("#rate-period").textContent = P.periods[i];
    const from = rateShown, to = R.rate[i], t0 = performance.now(), el = $("#rate-value");
    const tick = t => { const k = reduce ? 1 : Math.min(1, (t - t0) / 700), e = 1 - Math.pow(1 - k, 3); rateShown = from + (to - from) * e; el.textContent = F.pct1(rateShown); setDial(rateShown); if (k < 1) requestAnimationFrame(tick); };
    requestAnimationFrame(tick);
    rdc.highlight(i);
  }
  setStep(0);
  const stepObs = new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting) setStep(+e.target.dataset.i); }), { rootMargin: "-45% 0px -45% 0px" });
  $$("#rd-steps .step").forEach(s => stepObs.observe(s));

  $("#rd-figures").innerHTML = [
    [eur(RL.total), `Automotive R&D costs, ${P.latest}`],
    [eur(RL.cap), `Capitalised development costs (${F.pct1(RL.rate)})`],
    [eur(RL.pl), "R&D charged to the P&L: expensed R&D plus amortisation"],
    [eurSm(RL.netCap), "Net capitalisation: capitalised minus amortised. Below zero, the P&L charge exceeds R&D costs"],
  ].map(f => `<div><span class="f-val">${f[0]}</span><span class="f-lab">${f[1]}</span></div>`).join("");
  const daChart = () => C.columns($("#chart-da"), {
    labels: P.periods, stack: true, yfmt: v => F.int(v), tfmt: v => "€" + F.int(v) + "m", derived: isH2,
    series: [{ name: "Clean automotive D&A", cls: "b-da", values: R.cleanDA }, { name: "Impairments", cls: "b-imp", values: R.imp }],
    topLabel: i => F.int(R.cleanDA[i] + R.imp[i]),
    tipExtra: i => (i === 1 || i === 3) ? '<span class="tip-sub">Impairments taken as 0 where not disclosed (A-03)</span>' : i === 6 ? '<span class="tip-sub">€61m impairments assumed inside D&A (A-04)</span>' : "",
  });
  daChart();

  /* ------------------------------------------------ 05 commercial */
  const CM = P.commercial, revChg = CM.autoRev[1] - CM.autoRev[0], mx = Math.max(Math.abs(CM.volFx), Math.abs(CM.aspFx), Math.abs(revChg));
  $("#equation").innerHTML =
    `<div class="term neg" data-k="vol" tabindex="0" style="--w:${Math.abs(CM.volFx) / mx}"><span class="term-val">${F.eurS(CM.volFx)}</span><span class="term-lab">Volume effect, € million<br>${F.pctSigned1(CM.vsYoY)} vehicles sold, at last year's ASP</span><span class="term-bar"></span></div>` +
    `<span class="op" aria-hidden="true">+</span>` +
    `<div class="term pos" data-k="asp" tabindex="0" style="--w:${Math.abs(CM.aspFx) / mx}"><span class="term-val">${F.eurS(CM.aspFx)}</span><span class="term-lab">ASP effect, € million<br>${F.pctSigned1(CM.aspYoY)} per vehicle, on this year's units</span><span class="term-bar"></span></div>` +
    `<span class="op" aria-hidden="true">=</span>` +
    `<div class="term res" data-k="rev" tabindex="0" style="--w:${Math.abs(revChg) / mx}"><span class="term-val">${F.eurS(revChg)}</span><span class="term-lab">Automotive revenue change, € million<br>€${F.int(CM.autoRev[0])}m to €${F.int(CM.autoRev[1])}m</span><span class="term-bar"></span></div>`;
  $("#asp-cover").textContent = F.pct0(CM.aspFx / Math.abs(CM.volFx));
  const last = P.periods.length - 1, py = last - 2;
  const vsChart = () => C.columns($("#chart-vs"), { labels: P.periods, yw: 52, yfmt: v => F.int(v / 1000) + "k", tfmt: v => F.int(v) + " units", derived: isH2,
    series: [{ name: "Vehicle sales", cls: i => i === last ? "b-cur" : "b-py", values: CM.vs }], topLabel: i => (i === 0 || i === py || i === last) ? (Math.round(CM.vs[i] / 100) / 10).toFixed(1) + "k" : "" });
  const aspChart = () => C.columns($("#chart-asp"), { labels: P.periods, yfmt: v => F.int(v), tfmt: v => "€" + v.toFixed(1) + "k", derived: isH2,
    series: [{ name: "ASP", cls: i => i === last ? "b-cur" : "b-py", values: CM.asp }], topLabel: i => (i === 0 || i === py || i === last) ? CM.asp[i].toFixed(1) : "" });
  let vsCtl = vsChart(), aspCtl = aspChart();
  const revItems = [
    { key: "start", label: `Automotive revenue ${P.prior}`, short: `Revenue ${P.prior}`, v: CM.autoRev[0], kind: "total" },
    { key: "vol", label: "Volume effect", v: CM.volFx, kind: "vol" },
    { key: "asp", label: "ASP effect", v: CM.aspFx, kind: "asp" },
    { key: "end", label: `Automotive revenue ${P.latest}`, short: `Revenue ${P.latest}`, v: CM.autoRev[1], kind: "total" },
  ];
  let revCtl;
  const revChart = () => { revCtl = C.waterfall($("#chart-revbridge"), { items: revItems, fmt: eurS, fmtTotal: v => F.int(v), unitLabel: " € million",
    kindLabel: { total: "Automotive revenue", vol: "Change in units sold, at last year's ASP", asp: "Change in ASP, on this year's units" } }); };
  revChart();
  // same-half comparison: the prior-year bar and the latest bar
  const pair = [P.periods.length - 3, P.periods.length - 1];
  const eqMap = { vol: { rev: ["vol"], vs: pair }, asp: { rev: ["asp"], asp: pair }, rev: { rev: ["start", "end"], vs: pair, asp: pair } };
  function linkEq(k) {
    const m = k ? eqMap[k] : null;
    $("#equation").classList.toggle("has-hl", !!k);
    $$("#equation .term").forEach(t => t.classList.toggle("is-hl", t.dataset.k === k));
    revCtl.mark(m ? m.rev : null); vsCtl.mark(m && m.vs); aspCtl.mark(m && m.asp);
  }
  $$("#equation .term").forEach(t => {
    t.addEventListener("pointerenter", () => linkEq(t.dataset.k)); t.addEventListener("pointerleave", () => linkEq(null));
    t.addEventListener("focus", () => linkEq(t.dataset.k)); t.addEventListener("blur", () => linkEq(null));
  });
  let mixDim = "model";
  const mixChart = () => C.pairs($("#chart-mix"), { rows: CM.mix[mixDim].slice().sort((a, b) => b.cur - a.cur), curLabel: P.latest, pyLabel: P.prior });
  mixChart();
  $$("#mix-dim button").forEach(b => b.addEventListener("click", () => { mixDim = b.dataset.dim; $$("#mix-dim button").forEach(x => x.setAttribute("aria-checked", String(x === b))); mixChart(); }));

  /* ------------------------------------------------ 06 cash (actuals) */
  const CA = P.cash;
  $("#cash-figures").innerHTML = [
    [eur(CA.ncf), `Automotive net cash flow, ${P.latest}`],
    [F.pct1(K.ncfm[1]), `Automotive NCF margin (${P.prior}: ${F.pct1(K.ncfm[0])})`],
    [F.pct1(CA.ebitdamLatest), "Automotive EBITDA margin"],
    [CA.cfoEbitda.toFixed(2), "Cash from operations ÷ automotive EBITDA"],
  ].map(f => `<div><span class="f-val">${f[0]}</span><span class="f-lab">${f[1]}</span></div>`).join("");
  const cashSeries = [{ key: "e", name: "Automotive EBITDA margin", short: "EBITDA", cls: "s-l0", values: CA.ebitdam }, { key: "n", name: "Automotive NCF margin", short: "NCF", cls: "s-l2", values: CA.ncfm }];
  const cashChart = () => C.line($("#chart-cash"), { labels: P.periods, series: cashSeries, height: 260, yfmt: (v, d) => d ? F.pct1(v) : Math.round(v * 100) + "%", derived: isH2 });
  cashChart();
  const m = CA.note.match(/^Cash flow:\s*(.*?)\s*\[(S\d+)\s+slide\s+(\d+)\]$/);
  $("#cash-note").textContent = m ? `Porsche's commentary: ${niceEur(m[1]).replace(/\.$/, "")} (source ${m[2]}, slide ${m[3]}).` : niceEur(CA.note);

  /* ------------------------------------------------ 06 scenarios */
  const G = P.guidance, gin = id => G.inputs.find(x => x.id === id);
  const rev = gin("GD_REV"), ros = gin("GD_ROS"), ex = gin("GD_EXTRA");
  const ends = ["low", "mid", "high"], sel = { rev: "mid", ros: "mid", ex: "mid" };
  const ctl = (key, label, inp, f) => `<div class="ctl"><span class="ctl-lab" id="lab-${key}">${label}</span><div class="seg" role="radiogroup" aria-labelledby="lab-${key}">` +
    ends.map(e => `<button type="button" role="radio" aria-checked="${e === "mid"}" data-key="${key}" data-end="${e}">${e[0].toUpperCase() + e.slice(1)} ${f(inp[e])}</button>`).join("") + `</div></div>`;
  $("#explorer").innerHTML =
    `<p class="console-head"><span class="led"></span>Scenario console</p>` +
    ctl("rev", "FY2026 group revenue", rev, v => "€" + (v / 1000).toFixed(1) + "bn") +
    ctl("ros", "FY2026 return on sales", ros, v => v.toFixed(1) + "%") +
    ctl("ex", "FY2026 extraordinary expenses, net", ex, v => "€" + F.int(v) + "m") +
    `<div class="readouts" aria-live="polite"></div><p class="out-note">One of ${G.grid.length} combinations of published range ends (A-08). No probabilities are attached, and all midpoints is not a most-likely case. H2 = implied full year minus H1 2026 actuals.</p>`;
  let rangeCtl;
  function current() { return G.grid.find(g => g.rev === sel.rev && g.ros === sel.ros && g.ex === sel.ex); }
  function renderOut() {
    const g = current();
    $("#explorer .readouts").innerHTML = [
      ["l1", "Implied H2 margin, L1 underlying", F.gp(g.l1), "H1 2026 actual: " + F.pct2(G.h1.l1)],
      ["", "Implied H2 margin, L0", F.gp(g.l0), "H1: " + F.pct2(G.h1.l0)],
      ["", "Implied H2 margin, L2", F.gp(g.l2), "H1: " + F.pct2(G.h1.l2)],
      ["", "Implied H2 revenue", "€" + F.int(g.h2rev) + "m", "Full year minus H1"],
      ["", "Implied H2 reported EBIT", "€" + F.int(g.h2ebit) + "m", "Revenue × return on sales, minus H1"],
    ].map(r => `<div class="readout ${r[0]} flash"><span class="r-lab">${r[1]}</span><span class="r-val">${r[2]}</span><span class="r-cmp">${r[3]}</span></div>`).join("");
    if (rangeCtl) rangeCtl.update([g.l0, g.l1, g.l2]);
  }
  $$("#explorer .seg button").forEach(b => b.addEventListener("click", () => {
    sel[b.dataset.key] = b.dataset.end;
    $$(`#explorer button[data-key="${b.dataset.key}"]`).forEach(x => x.setAttribute("aria-checked", String(x === b)));
    renderOut();
  }));
  const rangeRows = () => { const g = current(); return ["l0", "l1", "l2"].map((lv, i) => ({
    name: ["L0 reported", "L1 underlying", "L2 excl. tariffs"][i], short: lv.toUpperCase(), sub: ["Revenue × return on sales", "L0 + implied H2 one-offs (A-06)", "L1 + H2 tariffs (A-07)"][i],
    min: G.range[lv].min * 100, mid: G.range[lv].mid * 100, max: G.range[lv].max * 100, h1: G.h1[lv] * 100, points: G.grid.map(x => x[lv]), sel: g[lv] })); };
  const rangeChart = () => { rangeCtl = C.ranges($("#chart-range"), { rows: rangeRows() }); };
  const autoChart = () => C.ranges($("#chart-auto"), { rows: [
    { name: "EBITDA margin", short: "EBITDA", min: G.autoRange.ebitda.min * 100, mid: G.autoRange.ebitda.mid * 100, max: G.autoRange.ebitda.max * 100, h1: G.h1.ebitda * 100, points: G.auto.map(a => a.ebitda) },
    { name: "NCF margin", short: "NCF", min: G.autoRange.ncf.min * 100, mid: G.autoRange.ncf.mid * 100, max: G.autoRange.ncf.max * 100, h1: G.h1.ncf * 100, points: G.auto.map(a => a.ncf) }] });
  rangeChart(); autoChart(); renderOut();

  const order = ["GD_REV", "GD_ROS", "GD_EXTRA", "GD_EBITDA", "GD_NCF", "GD_BEV"];
  const gv = (x, v) => x.unit === "%" ? v.toFixed(1) + "%" : "€" + F.int(v) + "m";
  $("#guidance-table").innerHTML = `<thead><tr><th>Metric</th><th>Low</th><th>Mid</th><th>High</th></tr></thead><tbody>` +
    order.map(id => gin(id)).filter(Boolean).map(x => `<tr><td>${x.metric}<br><span class="src">${x.source}, ${x.ref}</span></td><td>${gv(x, x.low)}</td><td>${gv(x, x.mid)}</td><td>${gv(x, x.high)}</td></tr>`).join("") + `</tbody>`;
  $("#assumptions-scenario").innerHTML = P.assumptions.filter(a => +a.id.slice(2) >= 5).map(a => `<li><b>${a.id}</b><span>${niceEur(a.statement)}</span></li>`).join("");

  /* ------------------------------------------------ 07 QA */
  const Q = P.qa;
  $("#ladder").innerHTML = [
    ["SQL", `${Q.sqlDQ} + ${Q.sqlMQ}`, `${Q.sqlDQ} data-quality and ${Q.sqlMQ} model-quality checks pass, 0 fail. PostgreSQL 16, ${Q.sqlViews} mart views.`],
    ["Excel", `${Q.excelChecks}/${Q.excelChecks}`, `Audit checks pass, and ${F.int(Q.excelValues)} displayed values match the SQL exports.`],
    ["Power BI", `${Q.measures}`, `DAX measures on ${Q.tables} tables and ${Q.relationships} relationships, loaded from the SQL exports.`],
    ["Reconciliation", F.int(Q.reconTotal), "Cross-tool comparisons between the report, live SQL and Excel, with 0 failures."],
    ["QA", `${Q.pbiQA}/${Q.pbiQATotal}`, "In-report checks: each measure recomputed and compared with the SQL reference."],
  ].map(r => `<li><span class="lad-top"><span class="lad-name">${r[0]}</span><svg class="lad-check" viewBox="0 0 22 22" aria-hidden="true"><circle cx="11" cy="11" r="10"/><path d="M6.5 11.5l3 3 6-7"/></svg></span><span class="lad-num">${r[1]}</span><span class="lad-desc">${r[2]}</span></li>`).join("");
  const reconChart = () => C.hbars($("#chart-recon"), { rows: Q.recon });

  /* ------------------------------------------------ method: timeline + architecture */
  const stages = [
    { n: "Source documents", tools: "Source register, Python extraction", p: `Every number starts in a registered public source. ${Q.sources} sources are registered with URL, type and period: ${Q.sourcesPorsche} from Porsche AG and one public earnings-call transcript, used only for the CFO's statement on extraordinary expenses.`,
      li: [`Fact-sheet Excel files extracted by script, checked against the file layout`, `${Q.manualInputs} manual input rows from PDFs: ${Q.manualValues} values and ${Q.gaps} gaps left blank, not estimated`, `${Q.sourceRefs} source-reference rows record where each variable was found`, "Every value labelled fact, derived, assumption or proxy"] },
    { n: "SQL data model", tools: "PostgreSQL 16, SQL, data modelling", p: `${Q.sqlScripts} scripts build staging, core, mart and audit schemas. H2 is derived as full year minus H1, for flow variables only; ratios are never derived that way.`,
      li: [`${Q.sqlViews} mart views: adjusted EBIT, clean D&A, R&D capitalisation, ASP and volume, delivery mix, cash, bridge, guidance`, `${Q.sqlDQ} data-quality and ${Q.sqlMQ} model-quality checks pass`, `${Q.auditFindings} audit findings documented`] },
    { n: "Excel reconciliation", tools: "Excel, financial analysis", p: `An audited business model imported from SQL, with ${F.int(Q.excelFormulas)} formulas across the analysis sheets for EBIT, R&D and D&A, commercial, cash and guidance.`,
      li: [`${Q.excelChecks} audit checks: imports, Excel vs SQL, identities, Porsche reconciliations, labelling`, `${Q.excelValues} displayed values verified against the SQL exports`] },
    { n: "Power BI model", tools: "Power BI, DAX, data modelling", p: `A star schema on a half-year period table: ${Q.tables} tables, ${Q.relationships} relationships and ${Q.measures} DAX measures. Guidance and level tables are disconnected, so period filters cannot alter the scenarios.`,
      li: ["Six report pages, from executive overview to QA and lineage", "Scenario slicers for the guidance combinations"] },
    { n: "QA and validation", tools: "Reconciliation, QA controls, Python", p: `${Q.pbiQA} in-report checks recompute each measure from base values and compare it with the SQL reference. A separate script runs ${F.int(Q.reconTotal)} comparisons across the tools.`,
      li: ["0 failures across SQL, Excel and Power BI", "Defects found in review were fixed and turned into permanent checks"] },
    { n: "Executive story", tools: "Data storytelling", p: "The analysis becomes findings management can act on, and a list of what to monitor at the FY2026 results.",
      li: ["L1 margin against the guidance-implied requirement", "Share of the EBIT change coming from one-offs", "Sign of the residual drivers", "ASP coverage of the volume decline", "Capitalisation rate and the amortisation overhang", "H2 cash conversion"] },
  ];
  const tl = $("#timeline");
  tl.innerHTML = stages.map((s, i) => `<li><button type="button" aria-expanded="${i === 0}" aria-controls="tl-p" data-i="${i}"><span class="tl-no">${String(i + 1).padStart(2, "0")}</span><span class="tl-name">${s.n}</span><span class="tl-tools">${s.tools}</span></button></li>`).join("") +
    `<li class="tl-panel" id="tl-p"></li>`;
  function openStage(i) {
    $$("#timeline button").forEach(b => b.setAttribute("aria-expanded", String(+b.dataset.i === i)));
    const s = stages[i];
    $("#tl-p").innerHTML = `<p class="fade">${s.p}</p><ul class="fade">${s.li.map(x => `<li>${x}</li>`).join("")}</ul>`;
    placeCar(i);
  }
  let stageNow = 0;
  function placeCar(i) {
    stageNow = i;
    const b = $$("#timeline button")[i], road = $(".road"), car = $("#road-car");
    if (!b || !road) return;
    const rb = road.getBoundingClientRect(), bb = b.getBoundingClientRect();
    car.style.setProperty("--car-x", Math.max(0, bb.left - rb.left + bb.width / 2 - car.getBoundingClientRect().width / 2) + "px");
  }
  $$("#timeline button").forEach(b => b.addEventListener("click", () => openStage(+b.dataset.i)));
  openStage(0);

  const nodes = [
    { n: "Data sources", meta: `${Q.sources} documents`, p: "Porsche AG half-year and annual reports, presentations, press releases and fact-sheet files, H1 2023 to H1 2026.", dl: [["Sources", Q.sources], ["From Porsche AG", Q.sourcesPorsche], ["Manual input rows", Q.manualInputs], ["Documented gaps", Q.gaps]] },
    { n: "SQL and data preparation", meta: "PostgreSQL 16", p: "Staging, core, mart and audit schemas. Each value keeps its source, page, unit, rounding and label.", dl: [["Scripts", Q.sqlScripts], ["Mart views", Q.sqlViews], ["Data-quality checks passed", Q.sqlDQ], ["Model-quality checks passed", Q.sqlMQ]] },
    { n: "Excel reconciliation", meta: "Audited model", p: "The business model rebuilt from the SQL exports, so every analytical figure can be traced and recalculated by hand.", dl: [["Formulas", F.int(Q.excelFormulas)], ["Audit checks passed", `${Q.excelChecks}/${Q.excelChecks}`], ["Values verified vs SQL", Q.excelValues]] },
    { n: "Power BI model", meta: "Star schema", p: "Half-year period dimension with fact tables for EBIT, R&D, commercial, cash and guidance. Scenario tables are disconnected from the period filter.", dl: [["Tables", Q.tables], ["Relationships", Q.relationships]] },
    { n: "DAX measures", meta: `${Q.measures} measures`, p: "Margin levels L0 to L3, the year-on-year bridge in € and margin points, volume and ASP effects, mix shares and the guidance arithmetic.", dl: [["Measures", Q.measures]] },
    { n: "QA engine", meta: `${Q.pbiQA}/${Q.pbiQATotal} pass`, p: "A reference table of SQL results drives an in-report QA page. Each measure is recomputed and compared, including every delivery-mix share.", dl: [["In-report checks", `${Q.pbiQA}/${Q.pbiQATotal}`], ["Cross-tool comparisons", F.int(Q.reconTotal)], ["Failures", 0]] },
    { n: "Executive dashboard", meta: "6 pages", p: "Executive Overview, EBIT Recovery, R&D and D&A, Commercial Drivers, Cash and Guidance, and QA and Lineage.", dl: [["Pages", 6]] },
  ];
  $("#arch-nodes").innerHTML = nodes.map((n, i) => `<li><button type="button" aria-pressed="${i === 0}" data-i="${i}"><span class="node-dot">${i + 1}</span><span class="node-name">${n.n}</span><span class="node-meta">${n.meta}</span></button></li>`).join("");
  function openNode(i) {
    $$("#arch-nodes button").forEach(b => b.setAttribute("aria-pressed", String(+b.dataset.i === i)));
    const n = nodes[i];
    $("#arch-detail").innerHTML = `<div class="fade"><h4>${n.n}</h4><p>${n.p}</p><dl>${n.dl.map(d => `<dt>${d[0]}</dt><dd>${d[1]}</dd>`).join("")}</dl></div>`;
  }
  $$("#arch-nodes button").forEach(b => { b.addEventListener("click", () => openNode(+b.dataset.i)); b.addEventListener("mouseenter", () => { if (window.matchMedia("(hover: hover)").matches) openNode(+b.dataset.i); }); });
  openNode(0);

  /* ------------------------------------------------ findings */
  const B = P.bridge, G1 = G.range.l1;
  const findings = [
    { cls: "red", fig: eurSm(B[1].v), lab: `lower one-offs, against a total reported EBIT gain of ${eurSm(K.yoy_l0)}`, h: "The margin recovery is driven by lower one-offs.",
      e: `The reported margin rose from ${F.pct1(K.m0[0])} to ${F.pct1(K.m0[1])}. With Porsche's own disclosed realignment and battery items removed, the underlying margin fell from ${F.pct1(K.m1[0])} to ${F.pct1(K.m1[1])}, and excluding tariffs too, from ${F.pct1(K.m2[0])} to ${F.pct1(K.m2[1])}. Smaller one-offs account for ${F.pct0(K.one_offs_share)} of the reported gain.`,
      c: `EBIT bridge, ${P.prior} to ${P.latest}. Exceptional items as disclosed by Porsche, rounded to €0.1bn.` },
    { fig: eurSm(B[6].v), lab: "residual: the drivers published data cannot separate", h: "The other EBIT drivers, taken together, are negative.",
      e: "Once one-offs, tariffs, capitalisation, D&A and Financial Services are separated, what remains moved EBIT down. Published data cannot split it into price, mix, volume, cost and FX, so it is reported as a residual, not as operating performance.",
      c: `It stays negative (${eurSm(P.residualAltA04)}) if the H1 2026 impairments are not inside D&A (assumption A-04).` },
    { fig: F.pct0(CM.aspFx / Math.abs(CM.volFx)), lab: "of the volume loss recovered by a higher ASP", h: "A higher price per car only partly offsets lower volume.",
      e: `Vehicle sales fell ${F.pct1(Math.abs(CM.vsYoY))} while the ASP rose ${F.pct1(CM.aspYoY)} to €${K.asp[1].toFixed(1)}k. The ASP effect (${eurSm(CM.aspFx)}) covers less than half of the volume effect (${eurSm(CM.volFx)}), and automotive revenue fell by €${F.int(Math.abs(revChg))}m. Deliveries shifted towards the 911 and the Cayenne.`,
      c: "ASP is automotive revenue per wholesale vehicle sold, Porsche's definition. The ASP effect includes model mix, options and FX, not only price." },
    { fig: F.pct1(RL.rate), lab: `of R&D capitalised, down from ${F.pct1(RL.ratePY)}`, h: "There is no accounting tailwind.",
      e: `Less development spend is being capitalised, and amortisation of earlier capitalisation now lifts the P&L charge (€${F.int(RL.pl)}m) above R&D costs (€${F.int(RL.total)}m).`,
      c: `Illustrative, with amortisation held fixed: at the prior-year rate, the P&L charge would have been €${RL.capFx.toFixed(1)}m lower.` },
    { fig: F.pct1(K.ncfm[1]), lab: `automotive net cash flow margin, up from ${F.pct1(K.ncfm[0])}`, h: "Cash conversion improved in H1 2026.",
      e: `Automotive net cash flow was €${F.int(CA.ncf)}m, despite about €0.4bn of cash-outs and about €0.3bn of pension funding disclosed by Porsche. The guidance arithmetic, by contrast, implies a much weaker H2 cash margin: ${F.pct1(G.autoRange.ncf.min)} to ${F.pct1(G.autoRange.ncf.max)}.`,
      c: "Actuals as published. The H2 range is scenario arithmetic using assumption A-05, not a forecast." },
    { cls: "scn", fig: F.pct1(G1.mid), lab: `implied H2 underlying margin with every guidance range at its midpoint, against ${F.pct1(K.m1[1])} in H1`, h: "Guidance at its midpoints requires the underlying margin to improve in H2.",
      e: `Holding the H1 level is not enough to meet the guidance midpoints. Across all ${G.grid.length} combinations the implied H2 L1 margin runs from ${F.pct1(G1.min)} to ${F.pct1(G1.max)}.`,
      c: "Arithmetic only — not forecasts — no probabilities. Based on FY2026 guidance (S016, slide 14) and the CFO's statement on extraordinary expenses (S027).", tag: "Scenario arithmetic" },
  ];
  $("#findings-list").innerHTML = findings.map(f => `<article class="finding ${f.cls || ""}"><div><p class="fd-fig">${f.fig}</p><p class="fd-figlab">${f.lab}</p></div><div class="fd-body">${f.tag ? `<span class="fd-tag">${f.tag}</span>` : ""}<h3 class="fd-insight">${f.h}</h3><p class="fd-expl">${f.e}</p><p class="fd-ctx">${f.c}</p></div></article>`).join("");

  /* ------------------------------------------------ explore the work */
  const cards = [
    ["powerbi", "Power BI", "The six-page management dashboard and its semantic model.", true],
    ["report", "Project report", "Methodology, KPI definitions, assumptions, findings and limitations."],
    ["presentation", "Presentation", "The executive storyline with speaker notes."],
    ["excel", "Excel", `The audited margin model: ${F.int(Q.excelFormulas)} formulas and ${Q.excelChecks} checks.`],
    ["sql", "SQL", `${Q.sqlScripts} PostgreSQL scripts: staging, core, mart and audit.`],
    ["caseStudy", "Case study", "The investigation, from business question to monitoring plan."],
    ["github", "GitHub repository", "SQL scripts, data exports, model files, QA outputs and documentation."],
  ];
  const safe = u => /^https?:\/\//i.test(u || "") ? u : "";
  $("#work-grid").innerHTML = cards.map(([k, n, d, preview], i) => {
    const u = safe(LINKS[k]), no = String(i + 1).padStart(2, "0");
    const head = `<span class="wc-no">${no}</span><span class="wc-name">${n}</span><span class="wc-desc">${d}</span>`;
    if (preview) {   // the dashboard card: its link (when published) plus a preview of the six report pages
      const link = u ? `<a class="wc-state wc-link" href="${u.replace(/"/g, "&quot;")}" target="_blank" rel="noopener">Open</a>` : `<span class="wc-state">Link not yet published</span>`;
      return `<div class="work-card has-preview${u ? "" : " is-pending"}">${head}<span class="wc-actions">${link}<button type="button" class="wc-preview" data-gallery="0">Preview the six pages</button></span></div>`;
    }
    return u ? `<a class="work-card" href="${u.replace(/"/g, "&quot;")}" target="_blank" rel="noopener">${head}<span class="wc-state">Open</span></a>`
             : `<div class="work-card is-pending">${head}<span class="wc-state">Link not yet published</span></div>`;
  }).join("");

  /* ------------------------------------------------ screenshots: framed like a display, opened in a gallery */
  const lb = $("#lightbox"), lbImg = $(".lb-stage img", lb), lbStage = $(".lb-stage", lb), lbCap = $(".lightbox-cap", lb), lbZoom = $(".lb-zoom", lb);
  let lastFocus = null, cur = 0, zoom = 1;
  // all six report pages stay available in the gallery; only the QA page is shown inline, as evidence
  const PAGES = [["01_executive_overview", "Executive Overview"], ["02_ebit_recovery", "EBIT Recovery"], ["03_rd_da", "R&D and D&A"],
                 ["04_commercial_drivers", "Commercial Drivers"], ["05_cash_guidance", "Cash and Guidance"], ["06_qa_lineage", "QA and Lineage", true]];
  const qaPass = Q.pbiQA === Q.pbiQATotal ? `ALL ${Q.pbiQA} QA CHECKS PASS (Power BI vs SQL mart)` : "";
  const gallery = PAGES.map(([f, cap, isQa], i) => ({ src: `assets/screenshots/${f}.png`, cap: `Page ${i + 1} of 6: ${cap}${isQa && qaPass ? ". " + qaPass : ""}`, pg: i + 1, w: 16, h: 9 }));
  gallery.forEach(g => { const probe = new Image(); probe.onload = () => { g.w = probe.naturalWidth; g.h = probe.naturalHeight; }; probe.src = g.src; });
  $$(".shot").forEach(f => {
    const src = f.dataset.shot, cap = f.dataset.caption, pg = f.dataset.page, probe = new Image();
    const pass = f.dataset.qa === "pass" ? qaPass : "";
    probe.onload = () => {
      f.innerHTML = `<div class="bezel"><div class="bezel-bar"><span class="led"></span>Power BI report${pass ? `<span class="pass-chip">${pass}</span>` : ""}<span class="pg">Page ${pg} of 6</span></div><button type="button" aria-label="Open larger view: ${cap}"><img src="${src}" alt="Screenshot of the final Power BI report, page ${pg}: ${cap}${pass ? ". The QA summary card reads " + pass : ""}" loading="lazy" width="${probe.naturalWidth}" height="${probe.naturalHeight}"></button></div><figcaption>Page ${pg}, ${cap}.${pass ? ` The QA summary card on this page reads ${pass}.` : ""} Select to open a larger view; all six report pages are in Explore the work.</figcaption>`;
      f.classList.add("is-ready");
      $("button", f).addEventListener("click", () => openLb(+pg - 1));
    };
    probe.src = src;
  });
  $$("[data-gallery]").forEach(b => b.addEventListener("click", () => openLb(+b.dataset.gallery)));
  function setZoom(z) {
    zoom = Math.max(1, Math.min(3, z)); lbZoom.textContent = Math.round(zoom * 100) + "%";
    lbStage.classList.toggle("is-zoomed", zoom > 1);
    if (zoom > 1) { const fit = Math.min(lbStage.clientWidth - 40, (lbStage.clientHeight - 40) * gallery[cur].w / gallery[cur].h); lbImg.style.width = Math.round(fit * zoom) + "px"; }
    else lbImg.style.width = "";
    $('[data-act="out"]', lb).disabled = zoom <= 1; $('[data-act="in"]', lb).disabled = zoom >= 3;
  }
  function showLb(i) {
    cur = (i + gallery.length) % gallery.length; const g = gallery[cur];
    lbImg.src = g.src; lbImg.alt = "Screenshot of the final Power BI report, " + g.cap; lbCap.textContent = g.cap;
    $('[data-act="prev"]', lb).disabled = $('[data-act="next"]', lb).disabled = gallery.length < 2;
    setZoom(1);
  }
  function openLb(i) { lastFocus = document.activeElement; lb.hidden = false; document.body.style.overflow = "hidden"; showLb(i); $(".lightbox-close", lb).focus(); }
  const closeLb = () => { lb.hidden = true; document.body.style.overflow = ""; if (lastFocus) lastFocus.focus(); };
  lb.addEventListener("click", e => {
    const a = e.target.closest("[data-act]"); if (!a) return;
    ({ close: closeLb, prev: () => showLb(cur - 1), next: () => showLb(cur + 1), in: () => setZoom(zoom + .5), out: () => setZoom(zoom - .5) })[a.dataset.act]();
  });
  lbImg.addEventListener("dblclick", () => setZoom(zoom > 1 ? 1 : 2));
  let drag = null;   // drag to pan when zoomed
  lbStage.addEventListener("pointerdown", e => { if (zoom <= 1) return; drag = { x: e.clientX, y: e.clientY, l: lbStage.scrollLeft, t: lbStage.scrollTop }; lbStage.classList.add("is-drag"); lbStage.setPointerCapture(e.pointerId); });
  lbStage.addEventListener("pointermove", e => { if (!drag) return; lbStage.scrollLeft = drag.l - (e.clientX - drag.x); lbStage.scrollTop = drag.t - (e.clientY - drag.y); });
  lbStage.addEventListener("pointerup", () => { drag = null; lbStage.classList.remove("is-drag"); });
  document.addEventListener("keydown", e => {
    if (lb.hidden) return;
    if (e.key === "Escape") closeLb(); else if (e.key === "ArrowRight") showLb(cur + 1); else if (e.key === "ArrowLeft") showLb(cur - 1);
    else if (e.key === "+" || e.key === "=") setZoom(zoom + .5); else if (e.key === "-") setZoom(zoom - .5);
    else if (e.key === "Tab") { const f = $$("button:not([disabled])", lb); if (!f.length) return; const i = f.indexOf(document.activeElement); if (e.shiftKey && i <= 0) { e.preventDefault(); f[f.length - 1].focus(); } else if (!e.shiftKey && i === f.length - 1) { e.preventDefault(); f[0].focus(); } }
  });

  /* ------------------------------------------------ navigation: chapter numbers, tachometer, progress */
  const topbar = $(".topbar"), bar = $(".progress span"), toggle = $(".nav-toggle"), list = $("#nav-list"), navCur = $("#nav-current");
  const tach = $("#nav-tach"), needle = $(".tach-needle", tach);
  (function buildTach() {
    const NS = "http://www.w3.org/2000/svg", g = $(".tach-ticks", tach), cx = 32, cy = 34, r = 24;
    for (let k = 0; k <= 7; k++) {
      const a = Math.PI + k / 7 * Math.PI, c = Math.cos(a), si = Math.sin(a);
      const l = document.createElementNS(NS, "line");
      l.setAttribute("x1", cx + (r - 1) * c); l.setAttribute("y1", cy + (r - 1) * si); l.setAttribute("x2", cx + (r - 5) * c); l.setAttribute("y2", cy + (r - 5) * si); g.appendChild(l);
    }
    const a0 = Math.PI + 6 / 7 * Math.PI;   // red zone: the last seventh
    $(".tach-red", tach).setAttribute("d", `M${cx + r * Math.cos(a0)} ${cy + r * Math.sin(a0)} A${r} ${r} 0 0 1 ${cx + r} ${cy}`);
  })();
  toggle.addEventListener("click", () => { const o = list.classList.toggle("open"); toggle.setAttribute("aria-expanded", String(o)); });
  $$("#nav-list a").forEach(a => a.addEventListener("click", () => { list.classList.remove("open"); toggle.setAttribute("aria-expanded", "false"); }));
  document.addEventListener("click", e => { if (!e.target.closest(".nav")) { list.classList.remove("open"); toggle.setAttribute("aria-expanded", "false"); } });

  const sections = $$("main section[id]"), navLinks = $$("#nav-list a");
  const secObs = new IntersectionObserver(es => es.forEach(e => {
    if (!e.isIntersecting) return;
    const id = e.target.id, idx = navLinks.findIndex(a => a.getAttribute("href") === "#" + id);
    navLinks.forEach((a, j) => { a.classList.toggle("is-active", j === idx); a.classList.toggle("is-done", idx >= 0 && j < idx && j < 7); });
    const no = e.target.dataset.chapter; navCur.textContent = no || (idx >= 0 ? navLinks[idx].textContent.slice(0, 5) : "00");
  }), { rootMargin: "-40% 0px -55% 0px" });
  sections.forEach(s => secObs.observe(s));

  /* ------------------------------------------------ one-time reveals */
  /* fires when the element enters view, or if a fast scroll jumped past it */
  /* checked on every scroll frame, so a fast jump can never skip an element */
  const pending = [];
  const once = (node, fn, margin) => { if (!node) return; const m = /-(\d+)%/.exec(margin || "-15%"); pending.push({ node, fn, at: 1 - (m ? +m[1] : 15) / 100 }); };
  function runPending(vh) {
    for (let i = pending.length - 1; i >= 0; i--) {
      const p = pending[i], r = p.node.getBoundingClientRect();
      if (r.top < vh * p.at && (r.bottom > 0 || r.top < 0)) { pending.splice(i, 1); p.fn(p.node); }
    }
  }
  const kpiCounters = $$("#kpis .kv").map(n => ({ n, v: kpis[+n.dataset.kpi].n, f: kpis[+n.dataset.kpi].f }));
  counters.concat(kpiCounters).forEach(c => { if (!reduce) c.n.textContent = c.f(0); once(c.n, () => countUp(c)); });
  once($("#chart-margins"), () => { marginsAnimated = true; drawMargins(!reduce); });
  once($("#equation"), n => n.classList.add("is-in"));
  once($("#chart-recon"), () => reconChart());
  $$(".finding").forEach(f => once(f, n => n.classList.add("is-in"), "0px 0px -12% 0px"));
  $$(".taillight").forEach(t => once(t, n => n.classList.add("is-on"), "0px 0px -20% 0px"));

  /* QA: the disc fills to the real result, the flow lights up in order, then PASS */
  const ring = $("#qa-ring");
  (function buildRing() {
    const NS = "http://www.w3.org/2000/svg", mk = (t, a) => { const e = document.createElementNS(NS, t); for (const k in a) e.setAttribute(k, a[k]); ring.appendChild(e); return e; };
    const defs = mk("defs", {}); defs.innerHTML = '<radialGradient id="disc-grad"><stop offset="0" stop-color="#1c1214"/><stop offset="1" stop-color="#0a0506"/></radialGradient>';
    mk("circle", { class: "r-track", cx: 110, cy: 110, r: 100 });
    ring._fill = mk("circle", { class: "r-fill", cx: 110, cy: 110, r: 100, pathLength: 100, "stroke-dasharray": "100 100", "stroke-dashoffset": 100 });
    mk("circle", { class: "r-inner", cx: 110, cy: 110, r: 86 });
    for (let k = 0; k < 30; k++) { const a = k / 30 * 2 * Math.PI; mk("circle", { class: "r-hole", cx: 110 + 76 * Math.cos(a), cy: 110 + 76 * Math.sin(a), r: 2.4 }); }
    for (let k = 0; k < 60; k++) { const a = k / 60 * 2 * Math.PI; mk("line", { class: "r-tick", x1: 110 + 88 * Math.cos(a), y1: 110 + 88 * Math.sin(a), x2: 110 + 92 * Math.cos(a), y2: 110 + 92 * Math.sin(a) }); }
  })();
  const qaHero = $("#qa-hero"), qaNum = $("#qa-num"), Qp = Q.pbiQA, Qt = Q.pbiQATotal;
  function finishQA() {
    ring._fill.setAttribute("stroke-dashoffset", 100 - 100 * Qp / Qt); qaNum.textContent = F.int(Qp);
    $$("#ladder li").forEach(li => li.classList.add("is-lit"));
    if (Qp === Qt) qaHero.classList.add("is-pass");     // the PASS state depends on the real result
  }
  once(qaHero, () => {
    if (reduce) return finishQA();
    const t0 = performance.now(), d = 1800;
    const step = t => {
      const k = Math.min(1, (t - t0) / d), e = 1 - Math.pow(1 - k, 3);
      ring._fill.setAttribute("stroke-dashoffset", 100 - 100 * (Qp / Qt) * e); qaNum.textContent = F.int(Qp * e);
      if (k < 1) requestAnimationFrame(step);
      else { $$("#ladder li").forEach((li, j) => setTimeout(() => li.classList.add("is-lit"), j * 380)); setTimeout(finishQA, 5 * 380 + 200); }
    };
    qaNum.textContent = "0"; requestAnimationFrame(step);
  }, "0px 0px -25% 0px");

  /* ------------------------------------------------ scroll: progress, tach, parallax, construction */
  const hero = $(".hero"), ghosts = $$(".ghost-no"), paras = $$(".poster-img img, .role-image img, .plate img");
  let ticking = false;
  function onScroll() {
    const y = window.scrollY, vh = window.innerHeight, H = document.documentElement.scrollHeight - vh, pr = H > 0 ? Math.min(1, y / H) : 0;
    bar.style.transform = `scaleX(${pr})`;
    needle.style.transform = `rotate(${pr * 180}deg)`;
    topbar.classList.toggle("at-top", y < 40);
    bridgeProgress(vh); if (pending.length) runPending(vh);
    if (!reduce) {
      if (y < vh * 1.3) hero.style.setProperty("--sy", y.toFixed(1));
      ghosts.forEach(g => { const r = g.parentElement.getBoundingClientRect(); if (r.bottom > 0 && r.top < vh) g.style.setProperty("--gy", ((r.top) * -.12).toFixed(1) + "px"); });
      paras.forEach(img => { const r = img.parentElement.getBoundingClientRect(); if (r.bottom > 0 && r.top < vh) img.style.setProperty("--py", (((r.top + r.height / 2) - vh / 2) * -.08).toFixed(1) + "px"); });
    }
    ticking = false;
  }
  window.addEventListener("scroll", () => { if (!ticking) { ticking = true; requestAnimationFrame(onScroll); } }, { passive: true });
  onScroll();
  // hero depth on pointer: the car moves most, the type least, the smoke on its own
  if (!reduce && window.matchMedia("(hover: hover)").matches) {
    let pt = false, mx = 0, my = 0;
    hero.addEventListener("pointermove", e => { mx = (e.clientX / window.innerWidth - .5) * 2; my = (e.clientY / window.innerHeight - .5) * 2;
      if (!pt) { pt = true; requestAnimationFrame(() => { hero.style.setProperty("--mx", mx.toFixed(3)); hero.style.setProperty("--my", my.toFixed(3)); pt = false; }); } });
    hero.addEventListener("pointerleave", () => { hero.style.setProperty("--mx", 0); hero.style.setProperty("--my", 0); });
  }
  // pause decorative animations in sections that are off-screen
  const idle = new IntersectionObserver(es => es.forEach(e => e.target.classList.toggle("is-idle", !e.isIntersecting)), { rootMargin: "100px 0px" });
  $$(".hero, .chapter, .interlude, .closing").forEach(n => idle.observe(n));

  /* ------------------------------------------------ responsive re-render */
  let lastW = window.innerWidth, rt;
  window.addEventListener("resize", () => {
    clearTimeout(rt);
    rt = setTimeout(() => {
      if (Math.abs(window.innerWidth - lastW) < 20) return; lastW = window.innerWidth; C.hideTip();
      if (marginsAnimated) drawMargins(false);
      drawBridge(); rdc = rdChart(); const a = activeStep; activeStep = -1; setStep(a);
      daChart(); vsCtl = vsChart(); aspCtl = aspChart(); revChart(); mixChart(); cashChart(); rangeChart(); autoChart(); renderOut();
      if ($("#chart-recon svg")) reconChart();
      placeCar(stageNow); onScroll();
    }, 180);
  });
  window.addEventListener("scroll", C.hideTip, { passive: true });
})();
