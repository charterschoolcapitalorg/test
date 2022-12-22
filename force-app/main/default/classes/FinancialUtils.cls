public class FinancialUtils {
    
    //for Budget items the date is the start of the period, otherwise it is the last date in the period
    public static Date getPeriodComparisonDate(Financial__c f) {
        Date d = null;
        if (f.recordtypeid == FinancialCtrl.monthlyRecType()) {
            if (f.fiscal_year__c!=null && f.month__c!=null) {
                Integer month =FinancialCtrl.monthsMap.get(f.month__c);
                Integer yr = (month >=7 ? (2000+ Integer.valueOf(f.fiscal_year__c.left(2))) : (2000+ Integer.valueOf(f.fiscal_year__c.right(2))) );
                d = Date.newInstance(yr,month,Date.daysInMonth(yr,month));
            }
        } else if (f.recordtypeid == FinancialCtrl.quarterlyRecType()) {
            if (f.fiscal_year__c!=null && f.fiscal_quarter__c!=null) {
                Integer month =(f.fiscal_quarter__c=='Q1' ? 9 : (f.fiscal_quarter__c=='Q2' ? 12 : (f.fiscal_quarter__c=='Q3' ? 3 : 6)));
                Integer yr = (month >=7 ? (2000+ Integer.valueOf(f.fiscal_year__c.left(2))) : (2000+ Integer.valueOf(f.fiscal_year__c.right(2))) );
                d = Date.newInstance(yr,month,Date.daysInMonth(yr,month));
            }
        } else if (f.recordtypeid == FinancialCtrl.annualRecType() && f.Data_Source__c == 'Budget') {
             Integer yr =  (2000+ Integer.valueOf(f.fiscal_year__c.right(2)));
             //date from the start of the period for Annual Budget items
             d = Date.newInstance(yr - 1,7,1);
        } else if (f.recordtypeid == FinancialCtrl.annualRecType()) {
             Integer yr =  (2000+ Integer.valueOf(f.fiscal_year__c.right(2)));
             d = Date.newInstance(yr,6,Date.daysInMonth(yr,6));
        }
        System.debug('last day of period: ' + d + ' for record: ' + f.fiscal_year__c + ' - '+ f.fiscal_quarter__c + ' - '+ f.month__c );
        return d;
    }
        
    public static Financial__c getLatestFinRecord (List<Financial__c> records)  {
        Financial__c result = null;
        Date periodComparisonDate = null;
        for (Financial__c f : records) {
            
            if (result==null) {result=f;periodComparisonDate = getPeriodComparisonDate(f);}
            else {
                Integer resultTypeValue = ((result.recordtypeid == FinancialCtrl.annualRecType() && result.Data_Source__c != 'Budget') ? 3 : (result.recordtypeid == FinancialCtrl.quarterlyRecType() ? 2 : 1));
            	Integer thisTypeValue = ((f.recordtypeid == FinancialCtrl.annualRecType() && f.Data_Source__c != 'Budget') ? 3 : (f.recordtypeid == FinancialCtrl.quarterlyRecType() ? 2 : 1));
                Date newDate = getPeriodComparisonDate(f);
                if (newDate>periodComparisonDate) {System.debug('new fin result: ' + f);result=f;periodComparisonDate = newDate;}
                //for same date, check which type it is - Annual>Quarterly>Monthly
                else if (newDate==periodComparisonDate && thisTypeValue>resultTypeValue) {System.debug('same date: new fin result: ' + f);result=f;periodComparisonDate = newDate;}
            }
        }
        return result;
    }
       
        
	public static void afterTrigger (List<Financial__c> newFinancials, Map<Id,Financial__c> oldFinancials)  {
        
        //link to previous Financial record
        Set<Id> finIds = new Set<Id>();
        Set<Id> acctIds = new Set<Id>();
        for (Financial__c f : newFinancials) {
            if (oldFinancials==null||oldFinancials.size()==0) {
                //annual
                if (f.recordtypeid==FinancialCtrl.annualRecType() && f.Fiscal_Year__c!=null) { finIds.add(f.Id); if (f.account__c!=null) acctIds.add(f.account__c);}
                //quarterly
                if (f.recordtypeid==FinancialCtrl.quarterlyRecType() && f.Fiscal_Year__c!=null && f.Fiscal_Quarter__c!=null) { finIds.add(f.Id); if (f.account__c!=null) acctIds.add(f.account__c);}
                //monthly
                if (f.recordtypeid==FinancialCtrl.monthlyRecType() && f.Fiscal_Year__c!=null && f.month__c!=null) { finIds.add(f.Id); if (f.account__c!=null) acctIds.add(f.account__c);}
            } else {
                //annual
                if (f.recordtypeid==FinancialCtrl.annualRecType() &&f.Fiscal_Year__c!=null && oldFinancials.get(f.Id).Fiscal_Year__c !=f.Fiscal_Year__c) { finIds.add(f.Id); if (f.account__c!=null &&f.Fiscal_Year__c!=null) acctIds.add(f.account__c);}
                //quarterly
                if (f.recordtypeid==FinancialCtrl.quarterlyRecType() &&f.Fiscal_Year__c!=null&& f.Fiscal_Quarter__c!=null && (oldFinancials.get(f.Id).Fiscal_Year__c!=f.Fiscal_Year__c || oldFinancials.get(f.Id).Fiscal_Quarter__c !=f.Fiscal_Quarter__c)) { finIds.add(f.Id); if (f.account__c!=null &&f.Fiscal_Year__c!=null) acctIds.add(f.account__c);}
                //monthly
                if (f.recordtypeid==FinancialCtrl.monthlyRecType() &&f.Fiscal_Year__c!=null&& f.month__c!=null && (oldFinancials.get(f.Id).Fiscal_Year__c!=f.Fiscal_Year__c || oldFinancials.get(f.Id).month__c !=f.month__c)) { finIds.add(f.Id); if (f.account__c!=null &&f.Fiscal_Year__c!=null) acctIds.add(f.account__c);}
            }
        }
        Map<Id, Financial__c> existing = new Map<Id, Financial__c>([Select Id, Month__c, Fiscal_Year__c, Fiscal_Quarter__c, RecordTypeId from Financial__c where Account__c IN:acctIds and Fiscal_Year__c!=null]);
        
        for (Financial__c f : newFinancials) {
            if (finIds.contains(f.Id)) {
                for(Financial__c fExist : existing.values()) {
                    if (fExist.RecordTypeId==f.RecordTypeId ) {
                        if (f.RecordTypeId==FinancialCtrl.monthlyRecType()) {
                            //monthly
                            Integer fy = Integer.valueOf(f.Fiscal_Year__c.left(2));
                            Integer fyExist = Integer.valueOf(fExist.Fiscal_Year__c.left(2));
                            Integer month = FinancialCtrl.monthsMap.get(f.month__c);
                            Integer monthExist = FinancialCtrl.monthsMap.get(fExist.month__c);
                            System.debug('fy: ' + fy);
                            System.debug('fyExist: ' + fyExist);
                            System.debug('month: ' + month);
                            System.debug('monthExist: ' + monthExist);
                            if (
                                (fyExist+1==fy && month==7 && monthExist==6)
                                ||
                                (fyExist==fy && month==1 && monthExist==12)
                                || 
                                ((fyExist==fy && month!= 7 && month== monthExist + 1))
                                         
                             )  {
                             
                                    if (f.Id!=fExist.Id) f.Previous_Financial_Record__c = fExist.Id;
                                    break;
                         		}
                        } else {
                            //annual/quarterly
                            Integer fy = Integer.valueOf(f.Fiscal_Year__c.left(2));
                            Integer fq = (f.Fiscal_Quarter__c==null ? 0 : Integer.valueOf(f.Fiscal_Quarter__c.right(1)));
                            Integer fqExist =  (fExist.Fiscal_Quarter__c==null ? 0 : Integer.valueOf(fExist.Fiscal_Quarter__c.right(1)));
                            Integer fyExist = Integer.valueOf(fExist.Fiscal_Year__c.left(2));
                            if (
                                (fyExist+1==fy && fq==0 && fqExist==0) //Annual
                                || 
                                ((fyExist==fy && fq== fqExist + 1)  || (fyExist+1==fy && fq==1 &&  fqExist ==4)) //Quarterly 
                                         
                             )  {
                             
                                    if (f.Id!=fExist.Id) f.Previous_Financial_Record__c = fExist.Id;
                                    break;
                         		}
                        }
                        
                    }
                }	         		       
            }
        }
        
    }
}