//+------------------------------------------------------------------+
//| Inputs.mqh — Phase 1 inputs (included from SMM.mq5)              |
//+------------------------------------------------------------------+
#ifndef __SMM_INPUTS_MQH__
#define __SMM_INPUTS_MQH__

#include "../Models/SignalData.mqh"

input group "General"
input long               InpMagic             = 260512;
input ENUM_SMM_LOG_LEVEL InpLogLevel         = SMM_LOG_VERBOSE;
input int                InpSlippagePoints   = 10;
input int                InpMaxSpreadPoints  = 50;
input int                InpOrderRetries   = 3;
input int                InpRetryDelayMs   = 250;

input group "Indicators"
// Defaults tuned for M1/M5: more reactive EMA/RSI/MACD, looser burst/breakout filters → more signals for data collection
input int                InpEmaFast         = 8;
input int                InpEmaSlow         = 18;
input int                InpRsiPeriod       = 4;
input double             InpRsiBuyAbove     = 51.0;
input double             InpRsiSellBelow    = 49.0;
input int                InpMacdFast        = 10;
input int                InpMacdSlow        = 22;
input int                InpMacdSignal      = 7;
input int                InpBreakoutLookback= 3;
input int                InpVolAvgLookback  = 12;
input double             InpVolBurstMult    = 1.12;
input int                InpBodyAvgLookback= 6;
input double             InpBodyBurstMult   = 1.06;
input int                InpAtrPeriod       = 10;

input group "Risk & sizing"
input ENUM_SMM_TRADE_PERM InpTradePerm       = SMM_PERM_BOTH;
input bool               InpUseRiskPercent  = false;
input double             InpRiskPercent     = 1.0;
input double             InpFixedLots       = 0.10;
input ENUM_SMM_SL_MODE   InpSlMode          = SMM_SL_FIXED_POINTS;
input int                InpSlPoints        = 200;
input double             InpSlAtrMult       = 1.5;
input bool               InpUseFixedTpPoints= false;
input int                InpTpPoints        = 200;
input bool               InpUseRiskReward   = true;
input double             InpRiskReward      = 2.0;
input int                InpMaxOpenTrades   = 2;
input int                InpCooldownBars    = 2;

input group "Safety"
input double             InpMinFreeMarginPct= 30.0;
input double             InpMaxDailyDdPct   = 10.0;
input double             InpMaxFloatingDdPct= 15.0;
input bool               InpUseLossKill     = false;
input int                InpMaxConsecLosses = 5;

#endif // __SMM_INPUTS_MQH__
