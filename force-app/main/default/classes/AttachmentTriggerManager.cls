/**=====================================================================
 * Manager Class Name: AttachmentTriggerManager
 * Description: T-279945 : Manager Class for Trigger AttachmentTriggerAfterInsert
 * Created Date: [08/29/2018]
 * Created By: [John Caughie]
 * Date Modified                Modified By                  Description of the update

 =====================================================================*/
public class AttachmentTriggerManager {
	
	/* CSC isons removal logic
		//static method to parse new attachments and delete those named csc_icons.png
		public static void DeleteIconsCSC(List<Attachment> attachments) {
			List<Id> deleteAttachmentIds = new List<Id>();
			for(Attachment a : attachments){
				if(a.Name.toLowerCase() == 'csc_icons.png'){
					deleteAttachmentIds.add(a.Id);
				}
			}

			System.debug(deleteAttachmentIds);
			Database.delete(deleteAttachmentIds, false);
		}
	*/



	
}