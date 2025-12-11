require "test_helper"

class CommentTest < ActiveSupport::TestCase
  # Validations
  test "should require comment" do
    user = create(:user)
    tool = create(:tool)
    comment = Comment.new(user: user, commentable: tool)
    assert_not comment.valid?
    assert_includes comment.errors[:comment], "can't be blank"
  end

  test "should require user" do
    tool = create(:tool)
    comment = Comment.new(commentable: tool, comment: "Test comment")
    assert_not comment.valid?
    assert_includes comment.errors[:user], "must exist"
  end

  test "should require commentable" do
    user = create(:user)
    comment = Comment.new(user: user, comment: "Test comment")
    assert_not comment.valid?
    assert_includes comment.errors[:commentable], "must exist"
  end

  # Associations
  test "should belong to commentable (tool)" do
    tool = create(:tool)
    comment = create(:comment, commentable: tool)
    assert_equal tool, comment.commentable
    # Test backward compatibility helper
    assert_equal tool, comment.tool
  end

  test "should belong to commentable (submission)" do
    submission = create(:submission)
    comment = create(:comment, :on_submission, commentable: submission)
    assert_equal submission, comment.commentable
  end

  test "should belong to user" do
    user = create(:user)
    tool = create(:tool)
    comment = create(:comment, user: user, commentable: tool)
    assert_equal user, comment.user
  end

  test "should belong to parent comment" do
    tool = create(:tool)
    parent_comment = create(:comment, commentable: tool)
    reply = create(:comment, commentable: tool, parent: parent_comment)

    assert_equal parent_comment, reply.parent
  end

  test "should have many replies" do
    tool = create(:tool)
    parent_comment = create(:comment, commentable: tool)
    reply1 = create(:comment, commentable: tool, parent: parent_comment)
    reply2 = create(:comment, commentable: tool, parent: parent_comment)

    assert_equal 2, parent_comment.replies.count
    assert_includes parent_comment.replies, reply1
    assert_includes parent_comment.replies, reply2
  end

  test "should have many comment_upvotes" do
    tool = create(:tool)
    comment = create(:comment, commentable: tool)
    user = create(:user)
    upvote = create(:comment_upvote, comment: comment, user: user)

    assert_equal 1, comment.comment_upvotes.count
    assert_includes comment.comment_upvotes, upvote
  end

  test "should have many upvoters through comment_upvotes" do
    tool = create(:tool)
    comment = create(:comment, commentable: tool)
    user1 = create(:user)
    user2 = create(:user)
    create(:comment_upvote, comment: comment, user: user1)
    create(:comment_upvote, comment: comment, user: user2)

    # Access the association to ensure it's executed
    upvoters = comment.upvoters.to_a
    assert_equal 2, upvoters.count
    assert_includes upvoters, user1
    assert_includes upvoters, user2
  end

  # Scopes
  test "top_level scope should return only comments without parent" do
    tool = create(:tool)
    top_comment = create(:comment, commentable: tool, parent: nil)
    reply = create(:comment, commentable: tool, parent: top_comment)

    # Actually call the scope and iterate to ensure it's executed
    top_level = Comment.top_level.to_a
    assert_includes top_level, top_comment
    assert_not_includes top_level, reply
  end

  test "replies scope should return only comments with parent" do
    tool = create(:tool)
    top_comment = create(:comment, commentable: tool, parent: nil)
    reply = create(:comment, commentable: tool, parent: top_comment)

    # Actually call the scope and iterate to ensure it's executed
    replies = Comment.replies.to_a
    assert_includes replies, reply
    assert_not_includes replies, top_comment
  end

  test "solved scope should return only solved comments" do
    tool = create(:tool)
    solved_comment = create(:comment, commentable: tool, solved: true)
    unsolved_comment = create(:comment, commentable: tool, solved: false)

    # Actually call the scope and iterate to ensure it's executed
    solved = Comment.solved.to_a
    assert_includes solved, solved_comment
    assert_not_includes solved, unsolved_comment
  end

  test "unsolved scope should return only unsolved comments" do
    tool = create(:tool)
    solved_comment = create(:comment, commentable: tool, solved: true)
    unsolved_comment = create(:comment, commentable: tool, solved: false)

    # Actually call the scope and iterate to ensure it's executed
    unsolved = Comment.unsolved.to_a
    assert_includes unsolved, unsolved_comment
    assert_not_includes unsolved, solved_comment
  end

  test "recent scope should order by created_at desc" do
    tool = create(:tool)
    comment1 = create(:comment, commentable: tool, created_at: 2.days.ago)
    comment2 = create(:comment, commentable: tool, created_at: 1.day.ago)
    comment3 = create(:comment, commentable: tool, created_at: Time.current)

    # Actually call the scope and iterate to ensure it's executed
    recent = Comment.recent.to_a
    assert_equal comment3, recent.first
    assert_equal comment1, recent.last
  end

  test "most_upvoted scope should order by upvote count" do
    tool = create(:tool)
    comment1 = create(:comment, commentable: tool)
    comment2 = create(:comment, commentable: tool)
    comment3 = create(:comment, commentable: tool)

    user1 = create(:user)
    user2 = create(:user)
    user3 = create(:user)

    # comment2 has 3 upvotes
    create(:comment_upvote, comment: comment2, user: user1)
    create(:comment_upvote, comment: comment2, user: user2)
    create(:comment_upvote, comment: comment2, user: user3)

    # comment1 has 1 upvote
    create(:comment_upvote, comment: comment1, user: user1)

    # comment3 has 2 upvotes
    create(:comment_upvote, comment: comment3, user: user1)
    create(:comment_upvote, comment: comment3, user: user2)

    # Actually call the scope and iterate to ensure it's executed
    most_upvoted = Comment.most_upvoted.to_a
    assert_equal comment2, most_upvoted.first
    assert_equal comment3, most_upvoted.second
    assert_equal comment1, most_upvoted.third
  end

  # Dependent destroy
  test "should destroy associated replies when comment is destroyed" do
    tool = create(:tool)
    parent_comment = create(:comment, commentable: tool)
    reply = create(:comment, commentable: tool, parent: parent_comment)

    assert_difference "Comment.count", -2 do
      parent_comment.destroy
    end
  end

  test "should destroy associated comment_upvotes when comment is destroyed" do
    tool = create(:tool)
    comment = create(:comment, commentable: tool)
    user = create(:user)
    upvote = create(:comment_upvote, comment: comment, user: user)

    assert_difference "CommentUpvote.count", -1 do
      comment.destroy
    end
  end

  # Threaded comments
  test "should allow nested comment threads" do
    tool = create(:tool)
    top_comment = create(:comment, commentable: tool)
    reply1 = create(:comment, commentable: tool, parent: top_comment)
    reply2 = create(:comment, commentable: tool, parent: top_comment)
    nested_reply = create(:comment, commentable: tool, parent: reply1)

    assert_equal 2, top_comment.replies.count
    assert_equal 1, reply1.replies.count
    assert_equal nested_reply, reply1.replies.first
  end
end

