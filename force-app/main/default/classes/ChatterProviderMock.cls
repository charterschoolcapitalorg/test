@isTest
public class ChatterProviderMock implements ConnectAPIHelper.ChatterProvider {
    public List<ConnectApi.FeedElementInput> feedElementInputs = new List<ConnectApi.FeedElementInput>();
    public List<ConnectApi.CommentInput> commentInputs = new List<ConnectApi.CommentInput>();

    public ConnectApi.FeedElement postFeedElement(Id communityId, ConnectApi.FeedElementInput input) {
        feedElementInputs.add(input);
        return null;
    }

    public ConnectApi.Comment postCommentToFeedElement(Id communityId, Id feedItemId, ConnectApi.CommentInput input, ConnectApi.BinaryInput upload) {
        commentInputs.add(input);
        return null;
    }
}