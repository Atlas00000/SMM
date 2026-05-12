//+------------------------------------------------------------------+
//| EntryEvaluator.mqh                                               |
//+------------------------------------------------------------------+
#ifndef __SMM_ENTRY_EVALUATOR_MQH__
#define __SMM_ENTRY_EVALUATOR_MQH__

#include "../Models/SignalData.mqh"

class SMMEntryEvaluator
  {
public:
   static ENUM_SMM_SIGNAL Evaluate(const SMMIndicatorSnapshot &s,
                                    const double rsi_buy,const double rsi_sell,
                                    const double vol_mult,const double body_mult,
                                    string &reason)
     {
      reason="";
      if(!s.valid)
        {
         reason="IND";
         return SMM_SIGNAL_NONE;
        }

      const bool vol_ok=(s.vol_avg>0.0 && s.vol_1>s.vol_avg*vol_mult);
      const bool body_ok=(s.body_avg>0.0 && s.body_1>s.body_avg*body_mult);

      const bool long_trend=(s.ema_fast_1>s.ema_slow_1)&&(s.ema_fast_1>s.ema_fast_2);
      const bool long_mom=(s.rsi_1>rsi_buy)&&(s.macd_hist_1>0.0)&&(s.macd_hist_1>s.macd_hist_2);
      const bool long_break=(s.close_1>s.breakout_ref_high);

      const bool short_trend=(s.ema_fast_1<s.ema_slow_1)&&(s.ema_fast_1<s.ema_fast_2);
      const bool short_mom=(s.rsi_1<rsi_sell)&&(s.macd_hist_1<0.0)&&(s.macd_hist_1<s.macd_hist_2);
      const bool short_break=(s.close_1<s.breakout_ref_low);

      const bool long_all=long_trend&&long_mom&&long_break&&vol_ok&&body_ok;
      const bool short_all=short_trend&&short_mom&&short_break&&vol_ok&&body_ok;

      if(long_all && short_all)
        {
         reason="CONFLICT";
         return SMM_SIGNAL_NONE;
        }
      if(long_all)
         return SMM_SIGNAL_LONG;
      if(short_all)
         return SMM_SIGNAL_SHORT;

      if(!long_trend && !short_trend) reason+="TREND;";
      if(!long_mom && !short_mom)     reason+="MOM;";
      if(!long_break && !short_break)reason+="BRK;";
      if(!vol_ok)                    reason+="VOL;";
      if(!body_ok)                   reason+="BODY;";
      return SMM_SIGNAL_NONE;
     }
  };

#endif // __SMM_ENTRY_EVALUATOR_MQH__
