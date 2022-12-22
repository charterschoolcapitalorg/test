public class SelectAll{
    
    public string allfields;
    public string SOQL;
    
    public selectall(){
    }
    
    public SelectAll(string sfo){
        map<string, schema.sobjecttype> allSObjects = schema.getglobaldescribe();
        schema.sobjecttype q = allsobjects.get(sfo);
        schema.describesobjectresult d = q.getdescribe();
        map<string, schema.sobjectfield> m = d.fields.getmap();
        set<string> s = m.keyset();
        string query = '';
        for(string f : s){
            query = query+f+', ';
        }
        query = query.substring(0,query.length()-2);
        this.allfields = query;
        this.SOQL = 'SELECT ' + query + ' FROM ' + sfo;
    }
}