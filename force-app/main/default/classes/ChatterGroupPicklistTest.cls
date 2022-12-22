@isTest
public class ChatterGroupPicklistTest {
	@testSetup static void groupSetup() {
		List<CollaborationGroup> groups = new List<CollaborationGroup>();
        CollaborationGroup grp = new CollaborationGroup();
		grp.Name = 'SFDC Team 1';
        grp.CollaborationType = 'Public';
		groups.add(grp);
        for(Integer i = 0; i < 10; i++){
            grp = new CollaborationGroup();
            grp.Name = 'Group ' + i;
            grp.CollaborationType = 'Public';
			groups.add(grp);
        }
        insert groups;
    }
    
    @isTest static void testGroupCount(){
        ChatterGroupPicklist cpg = new ChatterGroupPicklist();
        VisualEditor.DynamicPickListRows rows = cpg.getValues();
        System.debug(rows);
    }

    @isTest static void testDefaultValue(){
        ChatterGroupPicklist cpg = new ChatterGroupPicklist();
        VisualEditor.DataRow row = cpg.getDefaultValue();
        String label = row.getLabel();
        System.assertEquals(label.left(9), 'SFDC Team', 'incorrect group type returned');
    }    
    
}