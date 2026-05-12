//+------------------------------------------------------------------+
//| OrderValidator.mqh                                               |
//+------------------------------------------------------------------+
#ifndef __SMM_ORDER_VALIDATOR_MQH__
#define __SMM_ORDER_VALIDATOR_MQH__

#include "../Models/SignalData.mqh"
#include "../Core/Logger.mqh"

class SMMOrderValidator
  {
public:
   static bool ValidateMarketStops(const string sym,const ENUM_ORDER_TYPE type,
                                   const double sl,const double tp,
                                   const string mod,SMMLogger &log,string &rej)
     {
      rej="";
      double point=SymbolInfoDouble(sym,SYMBOL_POINT);
      int stops=(int)SymbolInfoInteger(sym,SYMBOL_TRADE_STOPS_LEVEL);
      double ask=SymbolInfoDouble(sym,SYMBOL_ASK);
      double bid=SymbolInfoDouble(sym,SYMBOL_BID);
      double ref=(type==ORDER_TYPE_BUY)?ask:bid;

      if(sl>0.0)
        {
         double dist_pts=MathAbs(ref-sl)/point;
         if(dist_pts<(double)stops)
           {
            rej="STOPS_SL";
            log.Log(mod,"INF",StringFormat("SL too close dist=%.1f min=%d",dist_pts,stops));
            return false;
           }
        }
      if(tp>0.0)
        {
         double dist_pts=MathAbs(tp-ref)/point;
         if(dist_pts<(double)stops)
           {
            rej="STOPS_TP";
            log.Log(mod,"INF",StringFormat("TP too close dist=%.1f min=%d",dist_pts,stops));
            return false;
           }
        }
      return true;
     }
  };

#endif // __SMM_ORDER_VALIDATOR_MQH__
