We are building an MT5 Expert Advisor (EA) centred around the following trading concept and system architecture:
[Scalping + Micro Momentum
(High-Frequency Intraday Engine)
Core Behavioral Edge
Short-term directional imbalance and liquidity bursts.

Best Indicator Blend
Trend Layer
EMA 9/21
Momentum Layer
RSI fast settings
MACD histogram
Execution Layer
micro breakout
volume burst
candle acceleration
Risk Layer
spread filter
session filter
volatility filter

Core Identity
This system exploits:
short-lived momentum bursts.

]
Current Development Scope (Phase 1):
The focus right now is strictly on building the automated execution engine based on the selected indicators and signal logic. We are intentionally keeping the system lightweight and modular at this stage.
Important:
Do NOT introduce advanced filtering, AI layers, session filters, portfolio management, adaptive optimisation, or overengineered logic yet.
Do NOT add unnecessary complexity outside the core execution workflow.
The goal is simply to automate trade execution reliably using the selected indicators and trading conditions.
Core Objective:
Build a configurable execution engine capable of:
Reading indicator values and market conditions in real time
Evaluating entry conditions
Executing buy/sell trades automatically
Managing basic trade risk
Providing clean parameter configuration for optimization and future scaling
Execution Engine Requirements:
Configurable indicator inputs
Configurable entry conditions
Buy/sell execution logic
Support for market orders initially
Clean order validation before execution
Low-latency and lightweight processing
Modular architecture for future expansion
Basic Risk Management & Position Sizing:
Include foundational risk and trade management features only, such as the following:
Fixed lot size input
Optional risk-based position sizing (% (risk per trade)
Stop Loss (fixed points/pips or ATR-based if applicable)
Take Profit configuration
Risk-to-reward ratio support
Maximum spread filter
Slippage control
Maximum simultaneous open trades
Basic cooldown between trades
Magic number management
Equity/balance safety checks
Configurable trading permissions (buy only / sell only / both)
One Symbol vs Multi-Symbol
Use:
Single symbol
Single timeframe
Based strictly on the current chart
This is the correct decision for Phase 1.
Benefits:
Simpler execution flow
Easier debugging
Lower CPU usage
Cleaner state management
More reliable order tracking
Avoids synchronization complexity
Architecture assumption:
One EA instance per chart
One symbol context
One timeframe context
Avoid for now:
multi-symbol scanning
centralized portfolio engine
cross-chart communication
symbol routing
correlation logic
Future extensibility:
Your modular structure should still isolate the following:
signal engine
execution engine
risk engine
This makes future multi-symbol expansion possible without rewriting the core.
The EA should:
Be modular and extensible
Use clean separation of concerns
Support future integration of:
filters
session logic
AI optimization
volatility layers
portfolio controls
advanced trade management
multi-strategy routing
Architecture Goals:
Clean and maintainable codebase
Production-style folder structure
Clear module responsibilities
Configurable engine design
Scalable architecture without premature complexity
High execution reliability
Easy debugging and testing
Suggested Focus Areas:
Signal evaluation pipeline
Indicator management system
Trade execution module
Risk management module
Position sizing engine
Configuration/input management
Logging and debugging utilities
State and trade tracking
What I need from you:
Design the execution engine architecture
Define module responsibilities and execution workflow
Recommend an MT5 production-grade folder structure
Suggest industry best practices for EA development
Keep implementation practical, scalable, and efficient
Avoid unnecessary abstraction or feature creep
Prioritize configurability, maintainability, and execution reliability
The current objective is NOT strategy perfection or advanced intelligence.
The objective is building a strong, configurable execution foundation first.



Gaps answered
Entry rule spec (core logic tree)
Trade evaluation occurs only on closed candles (shift=1) for Phase 1 stability.
Minimum history required before trading:
EMA 21 fully initialized
MACD signal initialized
RSI initialized
Minimum bars: max(EMA slow + 5, MACD slow + signal + 5) → typically ~40 bars.
Long setup:
Trend filter:
EMA 9 > EMA 21
EMA 9 slope > 0
Momentum confirmation:
RSI fast > 55
MACD histogram > 0
MACD histogram increasing vs previous candle
Execution trigger:
Micro breakout:
Close[1] > highest high of previous N candles
Volume burst:
Tick volume[1] > average volume × multiplier
Candle acceleration:
Candle body size > average body size × multiplier
Final logic:
(Trend AND Momentum AND Breakout AND VolumeBurst AND Acceleration)
Short setup:
Mirror opposite conditions.
Veto rules:
Spread > max spread
Existing open trade count exceeded
Cooldown active
Margin check failed
SL distance too small for broker stop level
Invalid lot after normalization
Optional relaxed mode later:
(Breakout AND (VolumeBurst OR Acceleration))
But Phase 1 should remain strict for cleaner testing.
Indicator defaults
Trend Layer
EMA Fast: 9
EMA Slow: 21
RSI Layer
RSI Period: 5
Buy threshold: 55
Sell threshold: 45
MACD Layer
Fast EMA: 12
Slow EMA: 26
Signal: 9
Use histogram only
Micro breakout
Breakout lookback: 3–5 candles
Default: 4
Volume burst
Average volume lookback: 20 bars
Burst multiplier: 1.5x
Formula:
Volume[1] > AvgVolume(20) * 1.5
Candle acceleration
Body lookback: 10 candles
Multiplier: 1.3x
Formula:
abs(Close[1]-Open[1]) > AvgBody(10) * 1.3
Signal timing
Core signal engine runs on:
New bar only
Reason:
Prevent duplicate entries
Improve tester consistency
Cleaner optimization results
Execution:
Order can be placed immediately after bar close confirmation.
Tester behavior:
Use:
Open prices only → early fast testing
Every tick based on real ticks → validation stage
Live execution:
Read closed candle
Execute on current market tick immediately after new bar detection.
Order pipeline
Use CTrade initially for simplicity and reliability.
Filling mode:
Prefer broker-supported:
ORDER_FILLING_FOK
fallback:
ORDER_FILLING_IOC
Slippage/deviation:
Configurable:
default: 5–10 points
Requote handling:
Retry attempts: 2–3 max
Small delay between retries
Idempotency protection:
Prevent duplicate execution on repeated OnTick
Use:
lastTradeBarTime
tradeInProgress flag
trade ticket confirmation before reset
Execution flow:
Validate signal
Validate risk
Validate symbol trading permissions
Build order request
Send order
Verify result code
Log result
Update internal state
Risk math
Two modes:
Fixed lot
% risk
% risk formula:
Risk amount:
AccountEquity * riskPercent
SL distance:
converted to points/ticks
Lot formula:
RiskAmount / (SLTicks * TickValue)
Must normalize against:
SYMBOL_VOLUME_MIN
SYMBOL_VOLUME_MAX
SYMBOL_VOLUME_STEP
Invalid computed lots:
Below min:
skip trade
Above max:
clamp to max
Margin validation:
Use:
OrderCalcMargin()
Always normalize:
NormalizeDouble(volume, volumeDigits)
SL / TP / R:R
SL modes:
Fixed points
ATR-based
ATR defaults:
ATR period: 14
ATR timeframe:
current chart timeframe
Precedence:
If fixed TP explicitly enabled:
use fixed TP
Else if R:R enabled:
TP = SL distance × RR
Recommended hierarchy:
Determine SL
Determine TP from explicit fixed TP OR RR
SL representation:
Internally use price distance
User inputs:
points/pips
or ATR multiplier
Cooldown
Phase 1 recommendation:
Bar-based cooldown
Default:
3–5 candles
Simpler and more deterministic than time-based.
Interaction rules:
Cooldown starts after successful entry.
Partial closes do NOT reset cooldown.
If max open trades reached:
block new entries regardless of cooldown.
Equity / balance safety
Minimum protections:
Minimum free margin %
Maximum daily drawdown %
Maximum floating drawdown %
Suggested defaults:
Stop trading below:
30% free margin
Pause trading if:
equity drawdown > 10%
Optional Phase 1 emergency kill switch:
Disable trading after X consecutive losses.
State and recovery
On terminal restart:
Re-scan existing positions by:
symbol
magic number
Rebuild state from live positions.
Never rely solely on runtime memory flags.
Recovery tasks:
Detect active trades
Restore cooldown timing
Restore “already in trade” logic
Avoid:
orphan state variables
assuming EA was continuously running
Logging and diagnostics
Log categories:
Signal accepted
Signal rejected
Spread block
Cooldown block
Risk block
Invalid volume
Order success/failure
Broker retcodes
Modes:
Minimal logging:
optimization/testing
Verbose logging:
live/debugging
Output targets:
Journal logs initially
Optional CSV/file logs later
Suggested log structure:
[TIME][MODULE][LEVEL] Message
Folder/module layout
Recommended MT5 structure:
MQL5/
├── Experts/
│   └── AtlasMomentum/
│       └── AtlasMomentumEA.mq5
│
├── Include/
│   └── AtlasMomentum/
│       ├── Config/
│       │   └── Inputs.mqh
│       │
│       ├── Indicators/
│       │   ├── EMAEngine.mqh
│       │   ├── RSIEngine.mqh
│       │   ├── MACDEngine.mqh
│       │   └── VolumeEngine.mqh
│       │
│       ├── Signals/
│       │   ├── TrendSignal.mqh
│       │   ├── MomentumSignal.mqh
│       │   ├── BreakoutSignal.mqh
│       │   └── EntryEvaluator.mqh
│       │
│       ├── Risk/
│       │   ├── RiskManager.mqh
│       │   ├── PositionSizer.mqh
│       │   └── SafetyChecks.mqh
│       │
│       ├── Execution/
│       │   ├── TradeExecutor.mqh
│       │   ├── OrderValidator.mqh
│       │   └── PositionTracker.mqh
│       │
│       ├── Core/
│       │   ├── StateManager.mqh
│       │   ├── Logger.mqh
│       │   └── Utilities.mqh
│       │
│       └── Models/
│           ├── SignalData.mqh
│           └── TradeData.mqh
Testing (operator-owned)
Testing methodology, tester stages, and result interpretation are handled outside this specification. The notes below are optional reference only for whoever runs validation.
Initial validation symbol:
XAUUSD
EURUSD
NAS100
Initial timeframe:
M1 or M5
Strategy tester stages:
Compile validation
Smoke test
Open prices only
Real tick validation
Parameter optimization
Forward test
Initial optimization ranges:
EMA fast:
5–15
EMA slow:
20–50
RSI threshold:
50–65
Breakout lookback:
2–10
Volume multiplier:
1.2–2.5
Phase 1 completion (execution-focused, not strategy metrics):
No duplicate trades
Stable execution
Proper SL/TP placement
Correct lot sizing
No invalid volume errors
Clean restart recovery
Deterministic tester behavior
Profit factor, win rate, and forward-test performance are not Phase 1 gates; they belong to later phases once execution is proven.