global class operateUsageMetrics
  implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
	public String query;

	global Database.QueryLocator start(Database.BatchableContext BC) {
        Config_Metrics_Data_File__c configMetrics = Config_Metrics_Data_File__c.getInstance('Push');
        //configMetrics.Batch_Id__c = BC.getJobId();
        upsert configMetrics;
        
		return Database.getQueryLocator(query);
	}
        
	global void execute(Database.BatchableContext BC, List<MetricsDataFile__C> fileList) 
	{
		System.debug('**Execute start***');
        usageMetrics um = new usageMetrics();
        um.execute(fileList, true);
	}
        
	global void finish (Database.BatchableContext BC) 
	{
        Config_Metrics_Data_File__c configMetrics = Config_Metrics_Data_File__c.getInstance('Push');
        //configMetrics.Batch_Id__c = '';
        upsert configMetrics;
	}
 }