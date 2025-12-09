require "test_helper"

class CommentUpvoteTest < ActiveSupport::TestCase
  # Validations
  test "should require comment" do
    user = create(:user)
    comment_upvote = CommentUpvote.new(user: user)
    assert_not comment_upvote.valid?
    assert_includes comment_upvote.errors[:comment], "must exist"
  end

  test "should require user" do
    tool = create(:tool)
    comment = create(:comment, tool: tool)
    comment_upvote = CommentUpvote.new(comment: comment)
    assert_not comment_upvote.valid?
    assert_includes comment_upvote.errors[:user], "must exist"
  end

  test "should enforce uniqueness of comment_id and user_id combination" do
    tool = create(:tool)
    comment = create(:comment, tool: tool)
    user = create(:user)
    create(:comment_upvote, comment: comment, user: user)

    duplicate = build(:comment_upvote, comment: comment, user: user)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:comment_id], "has already been taken"
  end

  # Associations
  test "should belong to comment" do
    tool = create(:tool)
    comment = create(:comment, tool: tool)
    user = create(:user)
    comment_upvote = create(:comment_upvote, comment: comment, user: user)
    assert_equal comment, comment_upvote.comment
  end

  test "should belong to user" do
    tool = create(:tool)
    comment = create(:comment, tool: tool)
    user = create(:user)
    comment_upvote = create(:comment_upvote, comment: comment, user: user)
    assert_equal user, comment_upvote.user
  end
end

