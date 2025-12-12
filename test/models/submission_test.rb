require "test_helper"

class SubmissionTest < ActiveSupport::TestCase
  # Validations
  test "should require user" do
    submission = Submission.new(submission_url: "https://example.com")
    assert_not submission.valid?
    assert_includes submission.errors[:user], "must exist"
  end

  test "should require submission_type" do
    user = create(:user)
    submission = Submission.new(user: user, submission_url: "https://example.com")
    # submission_type defaults to 0 (article) via enum, but let's test explicit requirement
    submission.submission_type = nil
    assert_not submission.valid?
  end

  test "should default status to pending on create" do
    user = create(:user)
    submission = Submission.new(user: user, submission_url: "https://example.com", submission_type: :article)
    # status defaults to 0 (pending) via enum and callback
    submission.valid?
    assert_equal "pending", submission.status
  end

  test "should validate URL format" do
    user = create(:user)
    submission = Submission.new(
      user: user,
      submission_url: "not-a-valid-url",
      submission_type: :article
    )
    assert_not submission.valid?
    assert_includes submission.errors[:submission_url], "must be a valid URL (e.g., https://example.com)"
  end

  test "should normalize URL on validation" do
    user = create(:user)
    submission = Submission.new(
      user: user,
      submission_url: "https://www.EXAMPLE.com/path/?query=test#fragment",
      submission_type: :article
    )
    submission.valid?
    assert_equal "https://example.com/path", submission.normalized_url
  end

  test "should enforce unique normalized_url" do
    user = create(:user)
    submission1 = create(:submission, user: user, submission_url: "https://example.com/article")
    submission2 = Submission.new(
      user: user,
      submission_url: "https://www.example.com/article/",
      submission_type: :article
    )
    assert_not submission2.valid?
    assert_includes submission2.errors[:normalized_url], "has already been taken"
  end

  # Associations
  test "should belong to user" do
    user = create(:user)
    submission = create(:submission, user: user)
    assert_equal user, submission.user
  end

  test "should belong to multiple tools" do
    tool1 = create(:tool)
    tool2 = create(:tool)
    submission = create(:submission)
    submission.tools << [tool1, tool2]
    
    assert_includes submission.tools, tool1
    assert_includes submission.tools, tool2
    assert_equal 2, submission.tools.count
  end

  test "should have many submission_tags" do
    submission = create(:submission)
    tag = create(:tag)
    submission_tag = create(:submission_tag, submission: submission, tag: tag)

    assert_equal 1, submission.submission_tags.count
    assert_includes submission.submission_tags, submission_tag
  end

  test "should have many tags through submission_tags" do
    submission = create(:submission)
    tag1 = create(:tag)
    tag2 = create(:tag)
    create(:submission_tag, submission: submission, tag: tag1)
    create(:submission_tag, submission: submission, tag: tag2)

    tags = submission.tags.to_a
    assert_equal 2, tags.count
    assert_includes tags, tag1
    assert_includes tags, tag2
  end

  test "should have many list_submissions" do
    submission = create(:submission)
    list = create(:list)
    list_submission = create(:list_submission, submission: submission, list: list)

    assert_equal 1, submission.list_submissions.count
    assert_includes submission.list_submissions, list_submission
  end

  test "should have many lists through list_submissions" do
    submission = create(:submission)
    list1 = create(:list)
    list2 = create(:list)
    create(:list_submission, submission: submission, list: list1)
    create(:list_submission, submission: submission, list: list2)

    lists = submission.lists.to_a
    assert_equal 2, lists.count
    assert_includes lists, list1
    assert_includes lists, list2
  end

  test "should have many comments as commentable" do
    submission = create(:submission)
    user = create(:user)
    comment1 = create(:comment, commentable: submission, user: user)
    comment2 = create(:comment, commentable: submission, user: user)

    assert_equal 2, submission.comments.count
    assert_includes submission.comments, comment1
    assert_includes submission.comments, comment2
  end

  test "should have many follows" do
    submission = create(:submission)
    user = create(:user)
    follow = create(:follow, followable: submission, user: user)

    assert_equal 1, submission.follows.count
    assert_includes submission.follows, follow
  end

  test "should have many followers through follows" do
    submission = create(:submission)
    user1 = create(:user)
    user2 = create(:user)
    create(:follow, followable: submission, user: user1)

    followers = submission.followers.to_a
    assert_equal 1, followers.count
    assert_includes followers, user1
    assert_not_includes followers, user2
  end

  # Enums
  test "should have correct submission_type enum values" do
    submission = create(:submission)
    assert submission.article?
    assert_not submission.guide?
    
    submission.github_repo!
    assert submission.github_repo?
    assert_not submission.article?
  end

  test "should have correct status enum values" do
    submission = create(:submission)
    assert submission.pending?
    assert_not submission.completed?
    
    submission.completed!
    assert submission.completed?
    assert_not submission.pending?
  end

  # Scopes
  test "pending scope should return only pending submissions" do
    user = create(:user)
    pending_submission = create(:submission, user: user, status: :pending)
    completed_submission = create(:submission, user: user, status: :completed)

    pending = Submission.pending.to_a
    assert_includes pending, pending_submission
    assert_not_includes pending, completed_submission
  end

  test "completed scope should return only completed submissions" do
    user = create(:user)
    pending_submission = create(:submission, user: user, status: :pending)
    completed_submission = create(:submission, user: user, status: :completed)

    completed = Submission.completed.to_a
    assert_includes completed, completed_submission
    assert_not_includes completed, pending_submission
  end

  test "recent scope should order by created_at desc" do
    user = create(:user)
    submission1 = create(:submission, user: user, created_at: 2.days.ago)
    submission2 = create(:submission, user: user, created_at: 1.day.ago)
    submission3 = create(:submission, user: user, created_at: Time.current)

    recent = Submission.recent.to_a
    assert_equal submission3, recent.first
    assert_equal submission1, recent.last
  end

  test "by_type scope should filter by submission_type" do
    user = create(:user)
    article = create(:submission, user: user, submission_type: :article)
    guide = create(:submission, user: user, submission_type: :guide)

    articles = Submission.by_type(:article).to_a
    assert_includes articles, article
    assert_not_includes articles, guide
  end

  test "for_tool scope should filter by tool" do
    tool = create(:tool)
    user = create(:user)
    submission1 = create(:submission, user: user, tool: tool)
    submission2 = create(:submission, user: user)

    tool_submissions = Submission.for_tool(tool).to_a
    assert_includes tool_submissions, submission1
    assert_not_includes tool_submissions, submission2
  end

  # Helper methods
  test "processing? should return true for processing status" do
    submission = create(:submission, status: :processing)
    assert submission.processing?
  end

  test "completed? should return true for completed status" do
    submission = create(:submission, status: :completed)
    assert submission.completed?
  end

  test "failed? should return true for failed status" do
    submission = create(:submission, status: :failed)
    assert submission.failed?
  end

  test "rejected? should return true for rejected status" do
    submission = create(:submission, status: :rejected)
    assert submission.rejected?
  end

  test "pending? should return true for pending status" do
    submission = create(:submission, status: :pending)
    assert submission.pending?
  end

  test "duplicate? should return true when duplicate_of_id is present" do
    user = create(:user)
    original = create(:submission, user: user)
    duplicate = create(:submission, user: user, duplicate_of: original)
    
    assert duplicate.duplicate?
    assert_not original.duplicate?
  end

  test "metadata_value should retrieve metadata value" do
    submission = create(:submission, metadata: { "key1" => "value1", "key2" => "value2" })
    assert_equal "value1", submission.metadata_value(:key1)
    assert_equal "value2", submission.metadata_value("key2")
  end

  test "set_metadata_value should set metadata value" do
    submission = create(:submission)
    submission.set_metadata_value(:new_key, "new_value")
    assert_equal "new_value", submission.metadata["new_key"]
  end

  # Callbacks
  test "should set default status to pending on create" do
    user = create(:user)
    submission = Submission.new(user: user, submission_url: "https://example.com", submission_type: :article)
    submission.save
    assert submission.pending?
  end

  # Dependent destroy
  test "should destroy associated submission_tags when submission is destroyed" do
    submission = create(:submission)
    tag = create(:tag)
    submission_tag = create(:submission_tag, submission: submission, tag: tag)

    assert_difference "SubmissionTag.count", -1 do
      submission.destroy
    end
  end

  test "should destroy associated list_submissions when submission is destroyed" do
    submission = create(:submission)
    list = create(:list)
    list_submission = create(:list_submission, submission: submission, list: list)

    assert_difference "ListSubmission.count", -1 do
      submission.destroy
    end
  end

  test "should destroy associated comments when submission is destroyed" do
    submission = create(:submission)
    user = create(:user)
    comment = create(:comment, commentable: submission, user: user)

    assert_difference "Comment.count", -1 do
      submission.destroy
    end
  end

  test "should destroy associated follows when submission is destroyed" do
    submission = create(:submission)
    user = create(:user)
    follow = create(:follow, followable: submission, user: user)

    assert_difference "Follow.count", -1 do
      submission.destroy
    end
  end
end

