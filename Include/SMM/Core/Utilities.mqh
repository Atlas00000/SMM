//+------------------------------------------------------------------+
//| Utilities.mqh                                                    |
//+------------------------------------------------------------------+
#ifndef __SMM_UTILITIES_MQH__
#define __SMM_UTILITIES_MQH__

bool SMM_IsNewBar(const string sym,const ENUM_TIMEFRAMES tf,datetime &out_bar0_time)
  {
   datetime t=iTime(sym,tf,0);
   if(t==0)
      return false;
   static datetime last=0;
   if(t==last)
     {
      out_bar0_time=t;
      return false;
     }
   last=t;
   out_bar0_time=t;
   return true;
  }

int SMM_VolumeDigitsFromStep(const double step)
  {
   if(step<=0.0)
      return 2;
   if(step>=1.0)
      return 0;
   return (int)MathRound(-MathLog10(step));
  }

double SMM_NormalizeVolume(const string sym,const double vol)
  {
   double step=SymbolInfoDouble(sym,SYMBOL_VOLUME_STEP);
   double vmin=SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN);
   double vmax=SymbolInfoDouble(sym,SYMBOL_VOLUME_MAX);
   if(step<=0.0)
      step=0.01;
   double n=MathFloor(vol/step+1e-12)*step;
   if(n<vmin)
      return 0.0;
   if(n>vmax)
      n=vmax;
   int vd=SMM_VolumeDigitsFromStep(step);
   return NormalizeDouble(n,vd);
  }

#endif // __SMM_UTILITIES_MQH__
