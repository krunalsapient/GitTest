global with sharing class usageMetricsScheduleJob implements Schedulable {

  	global void execute(SchedulableContext SC) {
        operateUsageMetrics opUM = new operateUsageMetrics();
		
        Config_Metrics_Data_File__c configMetrics = Config_Metrics_Data_File__c.getInstance('Push');
        String batchId = 'asdsad';
        
        if(batchId == NULL || batchId == '')
        {
            String headerId = configMetrics.Last_Processed_Id__c;
            Integer recordLimit =  50;
            
			String query = 'select ID FROM MetricsDataFile__C';
            String whereClause = ' WHERE  MetricsDataFileLength > 0 ';
            if(headerId != NULL && headerId != ''){
                whereClause += ' AND ID > \'' + headerId + '\' ';
            }
            query += whereClause + ' Order By ID ';
    
            opUM.query= query;
            ID opUMBatchId = Database.executeBatch(opUM, 1);
        }
    }
    
    /* helper method to schedule this scheduler class */
  	/*public static void scheduleJob() {
        String CRON_EXP = '0 5 * * * ?';
        usageMetricsScheduleJob job = new usageMetricsScheduleJob();
        System.schedule('Usage Metrics Job', CRON_EXP, new usageMetricsScheduleJob());
    }*/
}