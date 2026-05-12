//+------------------------------------------------------------------+
//| PositionSizer.mqh                                                |
//+------------------------------------------------------------------+
#ifndef __SMM_POSITION_SIZER_MQH__
#define __SMM_POSITION_SIZER_MQH__

#include "../Models/SignalData.mqh"
#include "../Core/Utilities.mqh"

class SMMPositionSizer
  {
public:
   static bool ComputeStopsAndVolume(const string sym,
                                     const ENUM_SMM_SIGNAL sig,
                                     const ENUM_SMM_SL_MODE sl_mode,
                                     const int sl_points,
                                     const double sl_atr_mult,
                                     const bool use_fixed_tp,const int tp_points,
                                     const bool use_rr,const double rr,
                                     const bool use_risk_pct,const double risk_pct,
                                     const double fixed_lots,
                                     const double atr_1,
                                     double &out_price,double &out_sl,double &out_tp,
                                     double &out_vol,string &reject)
     {
      reject="";
      int dg=(int)SymbolInfoInteger(sym,SYMBOL_DIGITS);
      double point=SymbolInfoDouble(sym,SYMBOL_POINT);
      if(point<=0.0){reject="POINT";return false;}

      double ask=SymbolInfoDouble(sym,SYMBOL_ASK);
      double bid=SymbolInfoDouble(sym,SYMBOL_BID);
      ENUM_ORDER_TYPE otype=(sig==SMM_SIGNAL_LONG)?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
      double entry=(sig==SMM_SIGNAL_LONG)?ask:bid;

      double sl_dist_price=0.0;
      if(sl_mode==SMM_SL_FIXED_POINTS)
         sl_dist_price=(double)sl_points*point;
      else
        {
         if(atr_1<=0.0){reject="ATR";return false;}
         sl_dist_price=atr_1*sl_atr_mult;
        }

      double sl_price=0.0,tp_price=0.0;
      if(sig==SMM_SIGNAL_LONG)
        {
         sl_price=NormalizeDouble(entry-sl_dist_price,dg);
         if(use_fixed_tp)
            tp_price=NormalizeDouble(entry+(double)tp_points*point,dg);
         else if(use_rr)
           {
            double d=MathAbs(entry-sl_price);
            tp_price=NormalizeDouble(entry+d*rr,dg);
           }
        }
      else
        {
         sl_price=NormalizeDouble(entry+sl_dist_price,dg);
         if(use_fixed_tp)
            tp_price=NormalizeDouble(entry-(double)tp_points*point,dg);
         else if(use_rr)
           {
            double d=MathAbs(sl_price-entry);
            tp_price=NormalizeDouble(entry-d*rr,dg);
           }
        }

      double vol=fixed_lots;
      if(use_risk_pct)
        {
         double equity=AccountInfoDouble(ACCOUNT_EQUITY);
         double risk_money=equity*risk_pct/100.0;
         double profit=0.0;
         if(!OrderCalcProfit(otype,sym,1.0,entry,sl_price,profit))
           {reject="CALC_PROFIT";return false;}
         double loss_per_lot=-profit;
         if(loss_per_lot<=0.0)
           {reject="SL_TOO_TIGHT";return false;}
         vol=risk_money/loss_per_lot;
        }

      vol=SMM_NormalizeVolume(sym,vol);
      if(vol<=0.0)
        {reject="VOL_NORM";return false;}

      double margin=0.0;
      if(!OrderCalcMargin(otype,sym,vol,entry,margin))
        {reject="CALC_MARGIN";return false;}
      double free=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(margin>free)
        {reject="MARGIN";return false;}

      out_price=0.0;
      out_sl=sl_price;
      out_tp=tp_price;
      out_vol=vol;
      return true;
     }
  };

#endif // __SMM_POSITION_SIZER_MQH__
