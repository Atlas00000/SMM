//+------------------------------------------------------------------+
//| StateManager.mqh                                                 |
//+------------------------------------------------------------------+
#ifndef __SMM_STATE_MANAGER_MQH__
#define __SMM_STATE_MANAGER_MQH__

class SMMStateManager
  {
public:
   bool              trade_in_progress;
   datetime          last_trade_bar_time;
   datetime          last_entry_signal_bar_time;
   double            day_start_equity;
   int               day_ymd;
   double            peak_equity;
   int               consecutive_losses;
   bool              trading_disabled;

                     SMMStateManager(void):
                        trade_in_progress(false),
                        last_trade_bar_time(0),
                        last_entry_signal_bar_time(0),
                        day_start_equity(0.0),
                        day_ymd(0),
                        peak_equity(0.0),
                        consecutive_losses(0),
                        trading_disabled(false)
                       {}

   string            GvLastEntryKey(const long magic) const
     {
      return "SMM_"+IntegerToString(magic)+"_"+_Symbol+"_lastEntrySig";
     }

   void              LoadFromGlobal(const long magic)
     {
      string k=GvLastEntryKey(magic);
      if(GlobalVariableCheck(k))
         last_entry_signal_bar_time=(datetime)GlobalVariableGet(k);
     }

   void              SaveLastEntryBarTime(const long magic,const datetime sig_bar_time)
     {
      last_entry_signal_bar_time=sig_bar_time;
      GlobalVariableSet(GvLastEntryKey(magic),(double)sig_bar_time);
     }

   void              ResetProgress(void)
     {
      trade_in_progress=false;
     }
  };

#endif // __SMM_STATE_MANAGER_MQH__
