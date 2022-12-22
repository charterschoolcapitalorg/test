public with sharing class ChatterGroupPicklist extends VisualEditor.DynamicPickList{
   
    public override VisualEditor.DataRow getDefaultValue(){
    	CollaborationGroup collabGroup = getDefaultGroup();
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow(collabGroup.Name, (String)collabGroup.Id);
        return defaultValue;
    }
    public override VisualEditor.DynamicPickListRows getValues() {
        List<CollaborationGroup> collabGroups = getCollabGroups();
        VisualEditor.DynamicPickListRows  groups = new VisualEditor.DynamicPickListRows();
        for(CollaborationGroup cg : collabGroups){
        	VisualEditor.DataRow entry = new VisualEditor.DataRow(cg.Name, (String)cg.Id);
        	groups.addRow(entry);
        }
        return groups;
    }

    private List<CollaborationGroup> getCollabGroups(){
    	List<CollaborationGroup> collabGroups = [SELECT Id, Name FROM CollaborationGroup];
    	return collabGroups;
    }

    private CollaborationGroup getDefaultGroup(){
    	CollaborationGroup collabGroup = [SELECT Id, Name FROM CollaborationGroup WHERE Name like'SFDC%'];
    	return collabGroup;
    }

}