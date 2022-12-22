public class BoxFieldStructures {

    public class FolderFile {
        public String type {get;set;}
        public String id {get;set;}
        public String sequence_id {get;set;}
        public String etag {get;set;}
        public String sha1 {get;set;}
        public String name {get;set;}
        public String description {get;set;}
        public Long size {get;set;}
        public PathCollection path_collection {get;set;}
        public DateTime created_at {get;set;}
        public DateTime modified_at {get;set;}
        public DateTime trashed_at {get;set;}
        public DateTime purged_at {get;set;}
        public DateTime content_created_at {get;set;}
        public DateTime content_modified_at {get;set;}
        public MiniUser created_by {get;set;}
        public MiniUser modified_by {get;set;}
        public MiniUser owned_by {get;set;}
        public SharedLink shared_link {get;set;}
        public FolderUploadEmail folder_upload_email {get;set;}
        public MiniFolderFile parent {get;set;}
        public String item_status {get;set;}
        public MiniFolderFileCollection item_collection {get;set;}     
    }
	
	public class MiniUser {
        public String type {get;set;}
        public String id {get;set;}
        public String name {get;set;}
        public String login {get;set;}
    }
    
    public class SharedLink {
        public String url {get;set;}
        public String download_url {get;set;}
        public String vanity_url {get;set;}
        public Boolean is_password_enabled {get;set;}
        public DateTime unshared_at {get;set;}
        public Integer download_count {get;set;}
        public Integer preview_count {get;set;}
        public String access {get;set;}
        public Permissions permissions {get;set;}
    }
    
    public class FolderFiles {
        public Integer total_count { get; set; }
        public List<FolderFile> entries { get; set; }
        public Integer offset { get; set; }
        public Integer limit_x {get; set;}
        public Integer status {get; set;}
        public String code{get; set;}
        
    }
    
        
    public class BoxGroup {
        public String type {get; set;}
        public String id {get; set;}
        public String name {get; set;}
    }  

    public class BoxGroups{
        public Integer total_count {get; set;}
        public BoxGroup [] entries {get; set;}
        public Integer limit_x {get; set;}
        public Integer offset {get; set;}
    }
    public class PathCollection {
        public Integer total_count {get;set;}
        public MiniFolderFile[] entries {get;set;}
    }
    
    public class MiniFolderFile  {
        public String type {get;set;}
        public String id {get;set;}
        public String sequence_id {get;set;}
        public String etag {get;set;}
        public String sha1 {get;set;}
        public String name {get;set;}
        public MiniFolderFile parent {get;set;}
    }
    
   public class MiniFolderFileCollection {
        public Integer total_count {get;set;}
        public MiniFolderFile[] entries {get;set;}
        public Integer offset {get;set;}
        public Integer limit_x {get;set;}
    }
    
    /*
    
    public class BoxUsers {
        public Integer total_count {get; set;}
        public User[] entries {get; set;}
        public Integer limit_x {get; set;}
        public Integer offset {get; set;}
    }
    
    
    
   public class User {
        public String type {get;set;}
        public String id {get;set;}
        public String name {get;set;}
        public String login {get;set;}
        public DateTime created_at {get;set;}
        public DateTime modified_at {get;set;}
        public String role {get;set;}
        public String language {get;set;}
        public Long space_amount {get;set;}
        public Long space_used {get;set;}
        public Long max_upload_size {get;set;}
        public String status {get;set;}
        public String job_title {get;set;}
        public String phone {get;set;}
        public String address {get;set;}
        public String avatar_url {get;set;}
    }
    

    public class Collaboration {
        public String type {get;set;}
        public String id {get;set;}
        public MiniUser created_by {get;set;}
        public DateTime created_at {get;set;}
        public DateTime modified_at {get;set;}
        public DateTime expires_at {get;set;}
        public String status {get;set;}
        public MiniUser accessible_by {get;set;}
        public String role {get;set;}
        public DateTime acknowledged_at {get;set;}
        public MiniFolderFile item {get;set;}
    }

    public class Collaborations {
        public Integer total_count {get;set;}
        public List<Collaboration> entries {get;set;}
    }
    
    public class BoxGroupMembership {
        public String type {get; set;}
        public String id {get; set;}
        public MiniUser user {get; set;}
        public BoxGroup group_x {get; set;}
     }
    
    public class BoxGroupMemberships {
        public Integer total_count {get; set;}
        public BoxGroupMembership [] entries {get; set;}
        public Integer limit_x {get; set;}
        public Integer offset {get; set;}
    }  
    
     public class ExpiringEmbedLink
    {
        public string url { get; set; }
    }
    
    public class ExpiringEmbed
    {
        public string type { get; set; }
        public string id { get; set; }
        public string etag { get; set; }
        public ExpiringEmbedLink expiring_embed_link { get; set; }
    }   
    */
    public class Permissions {
        public Boolean can_download {get;set;}
        public Boolean can_preview {get;set;}
    }
    
    public class FolderUploadEmail{
        public String access {get;set;}
        public String email {get;set;}
    }  
    
    public class ErrorConflicts {
		public String type {get;set;}
        public String id {get;set;}
	}
	
	
    public class BoxException extends Exception {}
    
	public class ErrorInfo {
		public ErrorConflicts[] conflicts {get;set;}
	}
	
    public class Error {
        public String type {get;set;}
        public Integer status {get;set;}
        public String code {get;set;}
        public String help_url {get;set;}
        public String message {get;set;}
        public String request_id {get;set;}
        public ErrorInfo context_info {get;set;}
    }
    
}