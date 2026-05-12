//+------------------------------------------------------------------+
//| IndicatorManager.mqh                                             |
//+------------------------------------------------------------------+
#ifndef __SMM_INDICATOR_MANAGER_MQH__
#define __SMM_INDICATOR_MANAGER_MQH__

#include "../Models/SignalData.mqh"

class SMMIndicatorManager
  {
private:
   string            m_sym;
   ENUM_TIMEFRAMES   m_tf;
   int               m_ema_fast;
   int               m_ema_slow;
   int               m_rsi_period;
   int               m_macd_f;
   int               m_macd_s;
   int               m_macd_sig;
   int               m_atr_period;
   int               m_h_ma_fast;
   int               m_h_ma_slow;
   int               m_h_rsi;
   int               m_h_macd;
   int               m_h_atr;
public:
                     SMMIndicatorManager(void):
                        m_sym(NULL),m_tf(PERIOD_CURRENT),
                        m_ema_fast(9),m_ema_slow(21),m_rsi_period(5),
                        m_macd_f(12),m_macd_s(26),m_macd_sig(9),m_atr_period(14),
                        m_h_ma_fast(INVALID_HANDLE),m_h_ma_slow(INVALID_HANDLE),
                        m_h_rsi(INVALID_HANDLE),m_h_macd(INVALID_HANDLE),m_h_atr(INVALID_HANDLE)
                       {}

   void              Configure(const string sym,const ENUM_TIMEFRAMES tf,
                               const int emaF,const int emaS,const int rsiP,
                               const int mf,const int ms,const int msi,const int atrP)
     {
      m_sym=sym;
      m_tf=tf;
      m_ema_fast=emaF;
      m_ema_slow=emaS;
      m_rsi_period=rsiP;
      m_macd_f=mf;
      m_macd_s=ms;
      m_macd_sig=msi;
      m_atr_period=atrP;
     }

   bool              Init(void)
     {
      Deinit();
      m_h_ma_fast=iMA(m_sym,m_tf,m_ema_fast,0,MODE_EMA,PRICE_CLOSE);
      m_h_ma_slow=iMA(m_sym,m_tf,m_ema_slow,0,MODE_EMA,PRICE_CLOSE);
      m_h_rsi=iRSI(m_sym,m_tf,m_rsi_period,PRICE_CLOSE);
      m_h_macd=iMACD(m_sym,m_tf,m_macd_f,m_macd_s,m_macd_sig,PRICE_CLOSE);
      m_h_atr=iATR(m_sym,m_tf,m_atr_period);
      return m_h_ma_fast!=INVALID_HANDLE && m_h_ma_slow!=INVALID_HANDLE &&
             m_h_rsi!=INVALID_HANDLE && m_h_macd!=INVALID_HANDLE && m_h_atr!=INVALID_HANDLE;
     }

   void              Deinit(void)
     {
      if(m_h_ma_fast!=INVALID_HANDLE){IndicatorRelease(m_h_ma_fast);m_h_ma_fast=INVALID_HANDLE;}
      if(m_h_ma_slow!=INVALID_HANDLE){IndicatorRelease(m_h_ma_slow);m_h_ma_slow=INVALID_HANDLE;}
      if(m_h_rsi!=INVALID_HANDLE){IndicatorRelease(m_h_rsi);m_h_rsi=INVALID_HANDLE;}
      if(m_h_macd!=INVALID_HANDLE){IndicatorRelease(m_h_macd);m_h_macd=INVALID_HANDLE;}
      if(m_h_atr!=INVALID_HANDLE){IndicatorRelease(m_h_atr);m_h_atr=INVALID_HANDLE;}
     }

   bool              BuildSnapshot(SMMIndicatorSnapshot &snap,
                                   const int breakoutLookback,
                                   const int volLookback,
                                   const int bodyLookback) const
     {
      ZeroMemory(snap);
      snap.valid=false;
      int need=MathMax(m_ema_slow+5,m_macd_s+m_macd_sig+5)+MathMax(breakoutLookback+2,MathMax(volLookback+2,bodyLookback+2))+5;
      if(Bars(m_sym,m_tf)<need)
         return false;

      double ema_f[];
      double ema_s[];
      double rsi[];
      double macd[];
      double atr[];
      ArraySetAsSeries(ema_f,true);
      ArraySetAsSeries(ema_s,true);
      ArraySetAsSeries(rsi,true);
      ArraySetAsSeries(macd,true);
      ArraySetAsSeries(atr,true);

      if(CopyBuffer(m_h_ma_fast,0,1,3,ema_f)<3) return false;
      if(CopyBuffer(m_h_ma_slow,0,1,1,ema_s)<1) return false;
      if(CopyBuffer(m_h_rsi,0,1,1,rsi)<1) return false;
      if(CopyBuffer(m_h_macd,2,1,2,macd)<2) return false;
      if(CopyBuffer(m_h_atr,0,1,1,atr)<1) return false;

      snap.ema_fast_1=ema_f[0];
      snap.ema_fast_2=ema_f[1];
      snap.ema_slow_1=ema_s[0];
      snap.rsi_1=rsi[0];
      snap.macd_hist_1=macd[0];
      snap.macd_hist_2=macd[1];
      snap.atr_1=atr[0];
      snap.close_1=iClose(m_sym,m_tf,1);
      snap.open_1=iOpen(m_sym,m_tf,1);
      snap.vol_1=(double)iTickVolume(m_sym,m_tf,1);

      snap.breakout_ref_high=-DBL_MAX;
      snap.breakout_ref_low=DBL_MAX;
      for(int i=2;i<=breakoutLookback+1;i++)
        {
         double hh=iHigh(m_sym,m_tf,i);
         double ll=iLow(m_sym,m_tf,i);
         if(hh>snap.breakout_ref_high) snap.breakout_ref_high=hh;
         if(ll<snap.breakout_ref_low)  snap.breakout_ref_low=ll;
        }

      double vsum=0.0;
      for(int j=2;j<=volLookback+1;j++)
         vsum+=(double)iTickVolume(m_sym,m_tf,j);
      snap.vol_avg=vsum/(double)volLookback;

      double bsum=0.0;
      for(int k=2;k<=bodyLookback+1;k++)
        {
         double o=iOpen(m_sym,m_tf,k);
         double c=iClose(m_sym,m_tf,k);
         bsum+=MathAbs(c-o);
        }
      snap.body_avg=bsum/(double)bodyLookback;
      snap.body_1=MathAbs(snap.close_1-snap.open_1);

      snap.valid=true;
      return true;
     }
  };

#endif // __SMM_INDICATOR_MANAGER_MQH__
