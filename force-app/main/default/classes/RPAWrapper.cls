/**=====================================================================
 * Appirio, Inc
 * Name: RPAWrapper
 * Description: T-280412 : Custom Wrapper class to store list of information about RPAs
 * Created Date: [05/22/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [08/29/2016]                [John Caughie]              [Added Decimal RPAFeeBalance to store balance of fees]

 =====================================================================*/
global class RPAWrapper implements Comparable{
        public ID RPAID {get;set;}
        public String RPAName {get;set;}
        public String RPAAccount {get;set;}
        public String RPAStatus {get;set;}
        public Decimal RPAProgramFee {get;set;}
        public Date RPAEndDate {get;set;}
        public Date RPADate {get;set;}
        public String newFees {get;set;}
        public Decimal RPAFeeBalance {get;set;}                                                             //2016.08.29 J Caughie - Added for balance of fees
        public Integer RowID {get;set;}
        public enum SORT_BY {
            //ByAccountName,ByBillingCountry,ByBillingStreet
            ByRPAName,ByRPAAccount,ByRPAStatus,ByRPAProgramFee,ByRPAEndDate,ByRPADate,RPAFeeBalance
        }
        public enum SORT_ORDER {
            ByAsc,ByDesc
        }

    //Variable to decide the member on which sorting should be performed
        public static SORT_BY sortBy = SORT_BY.ByRPAName;
    //Variable to decide the type of sorting (asc/desc)
        public static SORT_ORDER  sortOrder = SORT_ORDER.ByAsc;

        public RPAWrapper(ID RPAID, String RPAName, String RPAAccount, String RPAStatus,Date RPAEndDate, Date RPADate, 
                          Decimal RPAProgramFee, String newFees, Decimal RPAFeeBalance, Integer RowID){
            
            this.RPAID = RPAID;
            this.RPAName = RPAName;
            this.RPAAccount = RPAAccount;
            this.RPAStatus = RPAStatus;
            this.RPAEndDate = RPAEndDate;
            this.RPADate = RPADate;
            this.RPAProgramFee = RPAProgramFee;
            this.newFees = newFees;
            this.RPAFeeBalance = RPAFeeBalance;                                                             //2016.08.29 J Caughie - Added for balance of fees
            this.RowID = RowID;

        }
//opp_school__r.school__r.Charter_Holder__c,Id,name,Purchase_Date__c,School__c,Expected_Pay_Date__c, Distribution_Date__c, FV_Amount__c, Description__c
        global Integer compareTo(Object objToCompare) {
        //Sort by BookName Alphabetically
        //if(sortBy == SORT_BY.ByAccountName)
        if(sortBy == SORT_BY.ByRPAAccount)
        {   if(sortOrder == SORT_ORDER.ByAsc){
                return RPAAccount.compareTo(((RPAWrapper)objToCompare).RPAAccount);
            }
            else{
                return ((RPAWrapper)objToCompare).RPAAccount.compareTo(RPAAccount);
            }
        }
        else if(sortBy == SORT_BY.ByRPAStatus)
        {   if(sortOrder == SORT_ORDER.ByAsc){
                return RPAStatus.compareTo(((RPAWrapper)objToCompare).RPAStatus);
            }
            else{
                return ((RPAWrapper)objToCompare).RPAStatus.compareTo(RPAStatus);
            }
        }
        else if(sortBy == SORT_BY.ByRPAName)
        {
            if(sortOrder == SORT_ORDER.ByAsc){
                return RPAName.compareTo(((RPAWrapper)objToCompare).RPAName);
            }
            else{
                return ((RPAWrapper)objToCompare).RPAName.compareTo(RPAName);
            }
        }
        else if(sortBy == SORT_BY.ByRPAEndDate){   
        	Date otherPurDate = objToCompare != null ? ((RPAWrapper)objToCompare).RPAEndDate : System.today();
        	if(sortOrder == SORT_ORDER.ByAsc){
                //Date otherExpPDate = objToCompare != null ? ((ReceivableWrapper)objToCompare).ExpPayDate : System.today();
                return otherPurDate.daysBetween(this.RPAEndDate);
            }
            else{
                return this.RPAEndDate.daysBetween(otherPurDate);
            }
        }
        else if(sortBy == SORT_BY.ByRPADate){   
        	Date otherExpPDate = objToCompare != null ? ((RPAWrapper)objToCompare).RPADate : System.today();
        	if(sortOrder == SORT_ORDER.ByAsc){
                //Date otherExpPDate = objToCompare != null ? ((ReceivableWrapper)objToCompare).ExpPayDate : System.today();
                return otherExpPDate.daysBetween(this.RPADate);
            }
            else{
                return this.RPADate.daysBetween(otherExpPDate);
            }
        }
              
        else if(sortBy == SORT_BY.ByRPAProgramFee){
			Decimal otherFVAmount = objToCompare != null ? ((RPAWrapper)objToCompare).RPAProgramFee : 0.00;          
			if(sortOrder == SORT_ORDER.ByAsc){
            	return (this.RPAProgramFee - otherFVAmount).intvalue();
            }
            else{
                return (otherFVAmount - this.RPAProgramFee).intValue();
            }
        }

        else if(sortBy == SORT_BY.RPAFeeBalance){                                                                       //2016.08.29 J Caughie - Added for balance of fees
            Decimal otherFVAmount = objToCompare != null ? ((RPAWrapper)objToCompare).RPAFeeBalance : 0.00;          
            if(sortOrder == SORT_ORDER.ByAsc){
                return (this.RPAFeeBalance - otherFVAmount).intvalue();
            }
            else{
                return (otherFVAmount - this.RPAFeeBalance).intValue();
            }
        }
		
        return null;
    }
	
}