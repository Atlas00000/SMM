//+------------------------------------------------------------------+
//| PositionTracker.mqh                                              |
//+------------------------------------------------------------------+
#ifndef __SMM_POSITION_TRACKER_MQH__
#define __SMM_POSITION_TRACKER_MQH__

int SMM_PositionsTotal(const string sym,const long magic)
  {
   int total=0;
   const int n=(int)PositionsTotal();
   for(int i=n-1;i>=0;i--)
     {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=sym)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=magic)
         continue;
      total++;
     }
   return total;
  }

bool SMM_PositionSelectByTicket(const ulong ticket)
  {
   return PositionSelectByTicket(ticket);
  }

#endif // __SMM_POSITION_TRACKER_MQH__
