//+------------------------------------------------------------------+
//| Logger.mqh                                                       |
//+------------------------------------------------------------------+
#ifndef __SMM_LOGGER_MQH__
#define __SMM_LOGGER_MQH__

#include "../Models/SignalData.mqh"

class SMMLogger
  {
private:
   ENUM_SMM_LOG_LEVEL m_level;
public:
                     SMMLogger(void):m_level(SMM_LOG_MINIMAL) {}
   void              SetLevel(const ENUM_SMM_LOG_LEVEL lvl) { m_level = lvl; }
   ENUM_SMM_LOG_LEVEL Level(void) const { return m_level; }

   void              Log(const string module,const string level,const string msg)
     {
      if(m_level==SMM_LOG_MINIMAL && level=="DBG")
         return;
      string t=TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS);
      PrintFormat("[%s][%s][%s] %s",t,module,level,msg);
     }
  };

#endif // __SMM_LOGGER_MQH__
