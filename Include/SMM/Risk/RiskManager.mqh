//+------------------------------------------------------------------+
//| RiskManager.mqh                                                  |
//+------------------------------------------------------------------+
#ifndef __SMM_RISK_MANAGER_MQH__
#define __SMM_RISK_MANAGER_MQH__

#include "../Models/SignalData.mqh"
#include "../Core/Logger.mqh"
#include "../Core/StateManager.mqh"
#include "../Execution/PositionTracker.mqh"

class SMMRiskManager
  {
public:
   static int SpreadPoints(const string sym)
     {
      double a=SymbolInfoDouble(sym,SYMBOL_ASK);
      double b=SymbolInfoDouble(sym,SYMBOL_BID);
      double p=SymbolInfoDouble(sym,SYMBOL_POINT);
      if(p<=0.0)
         return 999999;
      return (int)MathRound((a-b)/p);
     }

   static bool PassSpread(const string sym,const int max_spread,const string mod,SMMLogger &log)
     {
      int sp=SpreadPoints(sym);
      if(sp>max_spread)
        {
         log.Log(mod,"INF",StringFormat("Spread block sp=%d max=%d",sp,max_spread));
         return false;
        }
      return true;
     }

   static bool PassCooldown(const string sym,const ENUM_TIMEFRAMES tf,
                            SMMStateManager &st,const int cooldown_bars,
                            const string mod,SMMLogger &log)
     {
      if(st.last_entry_signal_bar_time==0)
         return true;
      int sh=iBarShift(sym,tf,st.last_entry_signal_bar_time,true);
      if(sh<0)
         return true;
      if(sh<=cooldown_bars)
        {
         log.Log(mod,"DBG",StringFormat("Cooldown sh=%d need>%d",sh,cooldown_bars));
         return false;
        }
      return true;
     }

   static bool PassMaxTrades(const string sym,const long magic,const int max_tr,
                             const string mod,SMMLogger &log)
     {
      int c=SMM_PositionsTotal(sym,magic);
      if(c>=max_tr)
        {
         log.Log(mod,"INF","Max open trades");
         return false;
        }
      return true;
     }

   static bool PassPermissions(const ENUM_SMM_SIGNAL sig,const ENUM_SMM_TRADE_PERM perm,
                               const string mod,SMMLogger &log)
     {
      if(perm==SMM_PERM_BUY_ONLY && sig==SMM_SIGNAL_SHORT)
        {
         log.Log(mod,"INF","Sell blocked by permission");
         return false;
        }
      if(perm==SMM_PERM_SELL_ONLY && sig==SMM_SIGNAL_LONG)
        {
         log.Log(mod,"INF","Buy blocked by permission");
         return false;
        }
      return true;
     }
  };

#endif // __SMM_RISK_MANAGER_MQH__
