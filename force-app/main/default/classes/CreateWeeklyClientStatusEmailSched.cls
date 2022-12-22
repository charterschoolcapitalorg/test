public class CreateWeeklyClientStatusEmailSched implements Schedulable {
 	
 	public void execute(SchedulableContext sc) 
    {  
        CreateWeeklyClientStatusEmail batch = new CreateWeeklyClientStatusEmail(); 
        Database.executeBatch(batch, 1);
    }   
    
    
}