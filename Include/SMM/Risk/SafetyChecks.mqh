//+------------------------------------------------------------------+
//| SafetyChecks.mqh                                                 |
//+------------------------------------------------------------------+
#ifndef __SMM_SAFETY_CHECKS_MQH__
#define __SMM_SAFETY_CHECKS_MQH__

#include "../Core/Logger.mqh"
#include "../Core/StateManager.mqh"

class SMMSafetyChecks
  {
public:
   static void OnTickUpdateSession(SMMStateManager &st)
     {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(),dt);
      int ymd=dt.year*10000+dt.mon*100+dt.day;
      if(st.day_ymd!=ymd)
        {
         st.day_ymd=ymd;
         st.day_start_equity=AccountInfoDouble(ACCOUNT_EQUITY);
        }
      double eq=AccountInfoDouble(ACCOUNT_EQUITY);
      if(eq>st.peak_equity)
         st.peak_equity=eq;
     }

   static bool PassAll(SMMStateManager &st,
                       const double min_free_margin_pct,
                       const double max_daily_dd_pct,
                       const double max_float_dd_pct,
                       const bool use_loss_kill,const int max_consec,
                       const string mod,SMMLogger &log)
     {
      if(st.trading_disabled)
        {
         log.Log(mod,"INF","Trading disabled flag");
         return false;
        }
      double eq=AccountInfoDouble(ACCOUNT_EQUITY);
      double free=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(eq<=0.0)
         return false;
      double fm_pct=(free/eq)*100.0;
      if(fm_pct<(double)min_free_margin_pct)
        {
         log.Log(mod,"INF",StringFormat("Free margin low fm=%.2f%% need>=%.2f%%",fm_pct,min_free_margin_pct));
         return false;
        }
      if(st.day_start_equity>0.0 && max_daily_dd_pct>0.0)
        {
         double dd=(st.day_start_equity-eq)/st.day_start_equity*100.0;
         if(dd>max_daily_dd_pct)
           {
            log.Log(mod,"INF",StringFormat("Daily DD %.2f%%",dd));
            return false;
           }
        }
      if(st.peak_equity>0.0 && max_float_dd_pct>0.0)
        {
         double fd=(st.peak_equity-eq)/st.peak_equity*100.0;
         if(fd>max_float_dd_pct)
           {
            log.Log(mod,"INF",StringFormat("Floating DD %.2f%%",fd));
            return false;
           }
        }
      if(use_loss_kill && st.consecutive_losses>=max_consec)
        {
         log.Log(mod,"INF","Consecutive loss kill");
         return false;
        }
      return true;
     }
  };

#endif // __SMM_SAFETY_CHECKS_MQH__
