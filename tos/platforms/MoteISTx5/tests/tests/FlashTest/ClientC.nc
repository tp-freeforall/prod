
configuration ClientC{
  
}

implementation
{
  components new SettingsC();
  components ClientP;

  ClientP.FlashSettings -> SettingsC; 
}
