# Roadmap — Phase 1 execution engine (MT5)

This roadmap builds **only** the automated execution engine described in `concept.md`: single chart/symbol/timeframe, closed-bar signals, market orders, modular signal / risk / execution separation, and operator-owned testing.

## Phase 1 goal (in scope)

- One Expert Advisor project that **compiles as a single target** and runs on the attached chart.
- Signal stack (EMA, RSI, MACD histogram, breakout, volume, body acceleration) evaluated on **shift 1**, **new bar only**.
- Risk gates (spread, max positions, cooldown, margin, lot normalization, SL/TP / R:R per spec).
- Order path via **CTrade**, validation, retries/idempotency flags, basic logging.
- Restart recovery by **symbol + magic** position scan; no reliance on memory-only flags for safety.

## Explicitly out of scope (do not build in Phase 1)

- Multi-symbol scanning, portfolio, correlation, cross-chart sync.
- Session filters, AI, adaptive optimization, volatility regime engines beyond what is already in `concept.md` for SL (ATR optional only if already specified).
- Pending orders, grid/pyramiding logic, advanced trade management (trailing armies, partial TP ladders).
- CSV/database analytics dashboards, external DLLs, Telegram/discord unless you add a later phase.
- “Perfect” strategy metrics as a gate (PF, forward performance) — testing and interpretation stay with you; Phase 1 completes on **execution correctness**.

## Principles (avoid overengineering)

- **Trunk always compiles**: every week ends with **one** MetaEditor build of the same `.mq5` (all new `.mqh` files already `#include` from that Expert or from includes it pulls). No orphan headers sitting unused until “integration week.”
- **Vertical slice over horizontal layers**: prefer a thin working path (bar → signal stub → “would trade” log) early, then deepen modules without breaking the build.
- **One public entry**: the Expert file owns lifecycle (`OnInit` / `OnDeinit` / `OnTick`); libraries stay dumb and testable.
- **No speculative hooks**: do not add “plugin registries,” scriptable DSLs, or extra abstraction layers “for later.”
- **Stop at working**: when the engine meets `concept.md` Phase 1 behavior, stop adding features; polish logging and edge cases only.

## Suggested folder layout (adjust names to match your tree)

Align with `concept.md` (e.g. `Include/AtlasMomentum/...` and `Experts/.../YourEA.mq5`). If your repo folder is `SMM`, keep **one** EA file under `Experts/SMM/` and mirror includes under `Include/SMM/` — names matter less than **one compile root**.

---

## Weekly implementation (compile once, then test)

Rule for each week: **integrate all work into the main EA before you stop.** Open MetaEditor → **Build once** (F7) → if clean, run Strategy Tester / demo **once** for that week’s smoke checks. Do not leave mid-week code paths that only compile in a side branch.

### Week 1 — Scaffolding and tick discipline

**In scope**

- New EA project: `#property` lines, `OnInit` / `OnDeinit` / `OnTick`.
- Input group for **magic, slippage, logging verbosity, max spread** (even if unused yet).
- **New-bar detection** only (`static` last bar time or `Bars` comparison); no indicator calls required yet.
- Stub includes: e.g. `Logger.mqh` (no-op or `Print` wrapper), `StateManager.mqh` with `lastTradeBarTime` / `tradeInProgress` fields initialized.
- Journal line proving “new bar” fires once per bar.

**Out of scope**

- Real signals, orders, risk math.

**Compile-once gate**

- EA attaches to chart; journal shows one log line per new bar; zero warnings.

---

### Week 2 — Indicators and signal evaluation (no orders)

**In scope**

- Indicator handles or thin wrappers: EMA fast/slow, RSI, MACD (histogram), ATR if SL mode needs it later.
- History / minimum bars guard per `concept.md`.
- `EntryEvaluator` (or equivalent) returning **long / short / none** from **shift 1** only, full AND chain (strict mode).
- Log **accepted** vs **rejected** signal with short reason codes (no broker calls).

**Out of scope**

- `OrderSend`, position sizing beyond placeholders, equity guards.

**Compile-once gate**

- On history and live ticks, evaluator runs; logs show coherent rejections (e.g. “spread” can be stubbed as pass if not wired — better: wire spread read only, still no orders).

---

### Week 3 — Risk, sizing, and prices (still no live orders)

**In scope**

- Spread filter, max simultaneous trades count (by symbol + magic), trading permission flags.
- Fixed lot and **% risk** path with normalization, min/max/step, skip on invalid lot.
- SL/TP price computation: fixed points and/or ATR per spec; R:R vs fixed TP precedence.
- `OrderCalcMargin` check path; stop-level / freeze distance validation.
- Bar-based cooldown bookkeeping (in memory is OK this week; recovery comes Week 5).

**Out of scope**

- Actual `Buy`/`Sell`; retry loops (can stub `CTrade` include without calling send).

**Compile-once gate**

- On signal + pass risk, log **would-open** prices, volume, SL, TP. Still no orders.

---

### Week 4 — Execution path (first live orders optional but compiles)

**In scope**

- `CTrade` wiring: filling mode probe (FOK → IOC fallback), deviation, **2–3** retries with small delay.
- `OrderValidator` before send: recheck spread, permissions, margin, stops.
- Successful path: market order + SL/TP set per computed prices.
- Idempotency: `tradeInProgress`, `lastTradeBarTime`, confirm ticket before clearing in-flight flag.

**Out of scope**

- Restart recovery beyond “fresh attach” behavior, file logging, optimization harnesses.

**Compile-once gate**

- **Single build** → attach on **demo** → one controlled scenario opens at most one position per signal bar; duplicate fire on same bar blocked by flags.

---

### Week 5 — Safety, recovery, and logging polish

**In scope**

- Equity / free-margin / drawdown guards per `concept.md` (thresholds as inputs).
- **OnInit** (and optionally timer) **position rescan**: rebuild open count, cooldown anchor from last entry bar if you persist it in `GlobalVariable` or derive from position open time — pick **one** simple rule and document it in code comment.
- Logging modes: minimal vs verbose; broker retcodes on failure.
- Optional consecutive-loss kill switch if you keep it in Phase 1 (input-gated, default off).

**Out of scope**

- New signal types, relaxed OR-mode entry, session filters.

**Compile-once gate**

- **Single build** → restart terminal or reattach EA with open position(s) → EA recognizes positions, does not double-enter, cooldown respected.

---

### Week 6 — Integration hardening and Phase 1 closure

**In scope**

- Walk the full pipeline order: signal → risk → validator → order → state update → log.
- Remove dead code and unused inputs; align all defaults with `concept.md`.
- Deinit cleanup: release indicator handles, clear timers.
- Final pass on **tester vs live** differences (new bar timing, filling mode) — document one paragraph in code header or `concept.md` if behavior differs.

**Out of scope**

- Any feature not listed in Phase 1 of `concept.md`.

**Compile-once gate**

- **One production build** of the EA → you run your own test matrix (symbols, open prices vs ticks, etc.) **without further code changes** until you collect results. Further changes start Phase 1.1 or Phase 2 planning, not endless “tiny tweaks” mid-test.

---

## Definition of done (Phase 1)

- Meets **Phase 1 completion** checklist in `concept.md` (execution-focused).
- Operator can test without maintaining a patch queue of compile fixes.
- Codebase remains **three engines** (signal / risk / execution) plus thin core — no extra architectural tiers.

## After Phase 1

Only then: relaxed entry mode, session filters, multi-symbol, richer analytics — each as its own small roadmap with the same **weekly compile-once** rule.
