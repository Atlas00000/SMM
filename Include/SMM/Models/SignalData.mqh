//+------------------------------------------------------------------+
//| SignalData.mqh                                                   |
//+------------------------------------------------------------------+
#ifndef __SMM_SIGNAL_DATA_MQH__
#define __SMM_SIGNAL_DATA_MQH__

enum ENUM_SMM_SIGNAL
  {
   SMM_SIGNAL_NONE = 0,
   SMM_SIGNAL_LONG = 1,
   SMM_SIGNAL_SHORT = 2
  };

enum ENUM_SMM_TRADE_PERM
  {
   SMM_PERM_BOTH = 0,
   SMM_PERM_BUY_ONLY = 1,
   SMM_PERM_SELL_ONLY = 2
  };

enum ENUM_SMM_SL_MODE
  {
   SMM_SL_FIXED_POINTS = 0,
   SMM_SL_ATR = 1
  };

enum ENUM_SMM_LOG_LEVEL
  {
   SMM_LOG_MINIMAL = 0,
   SMM_LOG_VERBOSE = 1
  };

struct SMMIndicatorSnapshot
  {
   double            ema_fast_1;
   double            ema_fast_2;
   double            ema_slow_1;
   double            rsi_1;
   double            macd_hist_1;
   double            macd_hist_2;
   double            breakout_ref_high;
   double            breakout_ref_low;
   double            vol_1;
   double            vol_avg;
   double            body_1;
   double            body_avg;
   double            atr_1;
   double            close_1;
   double            open_1;
   bool              valid;
  };

struct SMMOrderPlan
  {
   ENUM_ORDER_TYPE   type;
   double            volume;
   double            price;
   double            sl;
   double            tp;
   bool              valid;
   string            reject;
  };

#endif // __SMM_SIGNAL_DATA_MQH__
