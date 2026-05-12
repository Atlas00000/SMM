//+------------------------------------------------------------------+
//| TradeExecutor.mqh                                                |
//+------------------------------------------------------------------+
#ifndef __SMM_TRADE_EXECUTOR_MQH__
#define __SMM_TRADE_EXECUTOR_MQH__

#include <Trade/Trade.mqh>
#include "../Models/SignalData.mqh"
#include "../Core/Logger.mqh"

ENUM_ORDER_TYPE_FILLING SMM_PickOrderFilling(const string sym)
  {
   uint fm=(uint)SymbolInfoInteger(sym,SYMBOL_FILLING_MODE);
   if((fm&SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   if((fm&SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC)
      return ORDER_FILLING_IOC;
   return ORDER_FILLING_RETURN;
  }

class SMMTradeExecutor
  {
private:
   CTrade            m_trade;
public:
   void              Configure(const long magic,const int deviation_points,const string sym)
     {
      m_trade.SetExpertMagicNumber((ulong)magic);
      m_trade.SetDeviationInPoints(deviation_points);
      m_trade.SetTypeFilling(SMM_PickOrderFilling(sym));
      m_trade.LogLevel(LOG_LEVEL_ERRORS);
     }

   bool              OpenMarket(const string sym,const ENUM_SMM_SIGNAL sig,
                                const double vol,const double sl,const double tp,
                                const int retries,const int delay_ms,
                                ulong &out_ticket,const string mod,SMMLogger &log)
     {
      out_ticket=0;
      string cmt="SMM";
      bool ok=false;
      for(int a=0;a<retries;a++)
        {
         if(sig==SMM_SIGNAL_LONG)
            ok=m_trade.Buy(vol,sym,0.0,sl,tp,cmt);
         else if(sig==SMM_SIGNAL_SHORT)
            ok=m_trade.Sell(vol,sym,0.0,sl,tp,cmt);
         else
            return false;
         if(ok)
           {
            out_ticket=m_trade.ResultOrder();
            log.Log(mod,"INF",StringFormat("Order OK ticket=%s ret=%u",(string)out_ticket,(uint)m_trade.ResultRetcode()));
            return true;
           }
         uint rc=m_trade.ResultRetcode();
         log.Log(mod,"WRN",StringFormat("Order fail try=%d ret=%u",a+1,rc));
         if(a+1<retries)
            Sleep(delay_ms);
        }
      return false;
     }
  };

#endif // __SMM_TRADE_EXECUTOR_MQH__
