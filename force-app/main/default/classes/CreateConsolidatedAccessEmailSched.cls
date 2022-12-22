public  class CreateConsolidatedAccessEmailSched implements Schedulable{
   
   
    public void execute(SchedulableContext sc) 
    {  
        CreateConsolidatedAccessEmail batch = new CreateConsolidatedAccessEmail(); 
        Database.executeBatch(batch, 500);
    }

}