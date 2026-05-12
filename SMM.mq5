//+------------------------------------------------------------------+
//|                                                          SMM.mq5 |
//|                        Phase 1 execution engine (see concept.md)|
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property description "SMM: modular signal / risk / execution"

#include "Include/SMM/Models/SignalData.mqh"
#include "Include/SMM/Config/Inputs.mqh"
#include "Include/SMM/Core/Utilities.mqh"
#include "Include/SMM/Core/Logger.mqh"
#include "Include/SMM/Core/StateManager.mqh"
#include "Include/SMM/Indicators/IndicatorManager.mqh"
#include "Include/SMM/Signals/EntryEvaluator.mqh"
#include "Include/SMM/Execution/PositionTracker.mqh"
#include "Include/SMM/Risk/PositionSizer.mqh"
#include "Include/SMM/Risk/RiskManager.mqh"
#include "Include/SMM/Risk/SafetyChecks.mqh"
#include "Include/SMM/Execution/OrderValidator.mqh"
#include "Include/SMM/Execution/TradeExecutor.mqh"

SMMLogger           g_log;
SMMStateManager     g_state;
SMMIndicatorManager g_ind;
SMMTradeExecutor    g_exec;
datetime            g_last_bar0_processed=0;

void RecoverFromPositions(const long magic)
  {
   int total=(int)PositionsTotal();
   datetime oldest=0;
   for(int i=0;i<total;i++)
     {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=magic)
         continue;
      datetime t=(datetime)PositionGetInteger(POSITION_TIME);
      if(oldest==0 || t<oldest)
         oldest=t;
     }
   if(oldest>0 && g_state.last_entry_signal_bar_time==0)
     {
      int sh=iBarShift(_Symbol,_Period,oldest,true);
      if(sh>=0)
         g_state.last_entry_signal_bar_time=iTime(_Symbol,_Period,sh);
     }
  }

void OnNewBar(const datetime bar0_open)
  {
   const string mod="SIG";
   g_last_bar0_processed=bar0_open;

   SMMIndicatorSnapshot snap;
   if(!g_ind.BuildSnapshot(snap,InpBreakoutLookback,InpVolAvgLookback,InpBodyAvgLookback))
     {
      g_log.Log(mod,"DBG","Snapshot not ready");
      return;
     }

   string why;
   ENUM_SMM_SIGNAL sig=SMMEntryEvaluator::Evaluate(snap,InpRsiBuyAbove,InpRsiSellBelow,
                                                   InpVolBurstMult,InpBodyBurstMult,why);
   if(sig==SMM_SIGNAL_NONE)
     {
      if(g_log.Level()==SMM_LOG_VERBOSE)
         g_log.Log(mod,"DBG",StringFormat("No signal [%s]",why));
      return;
     }

   if(!SMMRiskManager::PassSpread(_Symbol,InpMaxSpreadPoints,"RISK",g_log))
      return;
   if(!SMMRiskManager::PassMaxTrades(_Symbol,InpMagic,InpMaxOpenTrades,"RISK",g_log))
      return;
   if(!SMMRiskManager::PassCooldown(_Symbol,_Period,g_state,InpCooldownBars,"RISK",g_log))
      return;
   if(!SMMRiskManager::PassPermissions(sig,InpTradePerm,"RISK",g_log))
      return;

   if(g_state.trade_in_progress)
      return;

   double price=0.0,sl=0.0,tp=0.0,vol=0.0;
   string rej;
   if(!SMMPositionSizer::ComputeStopsAndVolume(_Symbol,sig,InpSlMode,InpSlPoints,InpSlAtrMult,
         InpUseFixedTpPoints,InpTpPoints,InpUseRiskReward,InpRiskReward,
         InpUseRiskPercent,InpRiskPercent,InpFixedLots,
         snap.atr_1,price,sl,tp,vol,rej))
     {
      g_log.Log("RISK","INF",StringFormat("Plan reject %s",rej));
      return;
     }

   ENUM_ORDER_TYPE otype=(sig==SMM_SIGNAL_LONG)?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
   if(!SMMOrderValidator::ValidateMarketStops(_Symbol,otype,sl,tp,"EXEC",g_log,rej))
      return;

   g_state.trade_in_progress=true;
   ulong ticket=0;
   datetime sig_bar_time=iTime(_Symbol,_Period,1);
   bool opened=g_exec.OpenMarket(_Symbol,sig,vol,sl,tp,InpOrderRetries,InpRetryDelayMs,ticket,"EXEC",g_log);
   g_state.trade_in_progress=false;

   if(opened)
      g_state.SaveLastEntryBarTime(InpMagic,sig_bar_time);
  }

int OnInit()
  {
   g_log.SetLevel(InpLogLevel);
   g_state.LoadFromGlobal(InpMagic);
   RecoverFromPositions(InpMagic);

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt);
   g_state.day_ymd=dt.year*10000+dt.mon*100+dt.day;
   g_state.day_start_equity=AccountInfoDouble(ACCOUNT_EQUITY);
   g_state.peak_equity=g_state.day_start_equity;

   g_ind.Configure(_Symbol,_Period,InpEmaFast,InpEmaSlow,InpRsiPeriod,
                   InpMacdFast,InpMacdSlow,InpMacdSignal,InpAtrPeriod);
   if(!g_ind.Init())
     {
      Print("SMM: indicator init failed");
      return(INIT_FAILED);
     }

   g_exec.Configure(InpMagic,InpSlippagePoints,_Symbol);
   Print("SMM: initialized");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   g_ind.Deinit();
  }

void OnTick()
  {
   SMMSafetyChecks::OnTickUpdateSession(g_state);
   if(!SMMSafetyChecks::PassAll(g_state,InpMinFreeMarginPct,InpMaxDailyDdPct,InpMaxFloatingDdPct,
        InpUseLossKill,InpMaxConsecLosses,"SAFE",g_log))
      return;

   datetime bar0;
   if(!SMM_IsNewBar(_Symbol,_Period,bar0))
      return;

   OnNewBar(bar0);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD)
      return;
   if(!HistoryDealSelect(trans.deal))
      return;

   string dsym=HistoryDealGetString(trans.deal,DEAL_SYMBOL);
   if(dsym!=_Symbol)
      return;
   long mg=(long)HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
   if(mg!=InpMagic)
      return;

   ENUM_DEAL_ENTRY dentry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
   if(dentry!=DEAL_ENTRY_OUT && dentry!=DEAL_ENTRY_OUT_BY && dentry!=DEAL_ENTRY_INOUT)
      return;

   double profit=HistoryDealGetDouble(trans.deal,DEAL_PROFIT)
                  +HistoryDealGetDouble(trans.deal,DEAL_SWAP)
                  +HistoryDealGetDouble(trans.deal,DEAL_COMMISSION);
   if(profit<0.0)
      g_state.consecutive_losses++;
   else
      g_state.consecutive_losses=0;
  }
