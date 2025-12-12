require "test_helper"

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @other_user = create(:user)
    @submission = create(:submission, user: @user, submission_url: "https://example.com/article")
    @tool = create(:tool)
  end

  # Index tests
  test "should get index" do
    get submissions_path
    assert_response :success
  end

  test "should get index with submissions" do
    create(:submission, user: @user)
    get submissions_path
    assert_response :success
    assert_select "h1", text: I18n.t("submissions.index.title")
  end

  test "should filter by submission type" do
    article = create(:submission, user: @user, submission_type: :article)
    guide = create(:submission, user: @user, submission_type: :guide)
    
    get submissions_path, params: { type: "article" }
    assert_response :success
  end

  test "should filter by status" do
    pending_submission = create(:submission, user: @user, status: :pending)
    completed_submission = create(:submission, user: @user, status: :completed)
    
    get submissions_path, params: { status: "pending" }
    assert_response :success
  end

  test "should filter by tool" do
    submission_with_tool = create(:submission, user: @user, tool: @tool)
    submission_without_tool = create(:submission, user: @user)
    
    get submissions_path, params: { tool_id: @tool.id }
    assert_response :success
  end

  # Show tests
  test "should show submission" do
    get submission_path(id: @submission.id)
    assert_response :success
  end

  test "should show submission with comments" do
    comment = create(:comment, commentable: @submission, user: @user)
    get submission_path(id: @submission.id)
    assert_response :success
  end

  # New tests
  test "should get new when signed in" do
    sign_in @user
    get new_submission_path
    assert_response :success
  end

  test "should redirect new when not signed in" do
    get new_submission_path
    assert_redirected_to new_user_session_path
  end

  # Create tests
  test "should create submission when signed in" do
    sign_in @user
    assert_difference "Submission.count", 1 do
      post submissions_path, params: {
        submission: {
          submission_url: "https://example.com/new-article",
          author_note: "Test note"
        }
      }
    end
    assert_redirected_to submission_path(id: Submission.last.id)
  end

  test "should not create submission when not signed in" do
    assert_no_difference "Submission.count" do
      post submissions_path, params: {
        submission: {
          submission_url: "https://example.com/new-article",
          author_note: "Test note"
        }
      }
    end
    assert_redirected_to new_user_session_path
  end

  test "should not create submission with invalid URL" do
    sign_in @user
    assert_no_difference "Submission.count" do
      post submissions_path, params: {
        submission: {
          submission_url: "not-a-valid-url",
          author_note: "Test note"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should create submission with tool association" do
    sign_in @user
    assert_difference "Submission.count", 1 do
      post submissions_path, params: {
        submission: {
          submission_url: "https://example.com/new-article",
          author_note: "Test note",
          tool_id: @tool.id
        }
      }
    end
    submission = Submission.last
    assert_includes submission.tools, @tool
  end

  test "should prevent duplicate submission from same user" do
    sign_in @user
    existing = create(:submission, user: @user, submission_url: "https://example.com/unique-article")
    
    assert_no_difference "Submission.count" do
      post submissions_path, params: {
        submission: {
          submission_url: "https://www.example.com/unique-article",
          author_note: "Test note"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should allow same URL from different users" do
    sign_in @other_user
    # Create submission with URL for first user
    existing = create(:submission, user: @user, submission_url: "https://example.com/shared-article")
    
    # Second user should be able to submit same URL (validation and index are scoped to user_id)
    assert_difference "Submission.count", 1 do
      post submissions_path, params: {
        submission: {
          submission_url: "https://example.com/shared-article",
          author_note: "Test note"
        }
      }
    end
  end

  # Edit tests
  test "should get edit when owner" do
    sign_in @user
    get edit_submission_path(id: @submission.id)
    assert_response :success
  end

  test "should redirect edit when not signed in" do
    get edit_submission_path(id: @submission.id)
    assert_redirected_to new_user_session_path
  end

  test "should redirect edit when not owner" do
    sign_in @other_user
    get edit_submission_path(id: @submission.id)
    assert_redirected_to submissions_path
  end

  # Update tests
  test "should update submission when owner" do
    sign_in @user
    patch submission_path(id: @submission.id), params: {
      submission: {
        author_note: "Updated note"
      }
    }
    assert_redirected_to submission_path(id: @submission.id)
    @submission.reload
    assert_equal "Updated note", @submission.author_note
  end

  test "should not update submission when not signed in" do
    original_note = @submission.author_note
    patch submission_path(id: @submission.id), params: {
      submission: {
        author_note: "Updated note"
      }
    }
    assert_redirected_to new_user_session_path
    @submission.reload
    assert_equal original_note, @submission.author_note
  end

  test "should not update submission when not owner" do
    sign_in @other_user
    original_note = @submission.author_note
    patch submission_path(id: @submission.id), params: {
      submission: {
        author_note: "Updated note"
      }
    }
    # Should redirect to submissions index, not show page
    assert_response :redirect
    @submission.reload
    assert_equal original_note, @submission.author_note
  end

  test "should not update submission with invalid data" do
    sign_in @user
    patch submission_path(id: @submission.id), params: {
      submission: {
        submission_url: "not-a-valid-url"
      }
    }
    assert_response :unprocessable_entity
  end

  # Destroy tests
  test "should destroy submission when owner" do
    sign_in @user
    assert_difference "Submission.count", -1 do
      delete submission_path(id: @submission.id)
    end
    assert_redirected_to submissions_path
  end

  test "should not destroy submission when not signed in" do
    assert_no_difference "Submission.count" do
      delete submission_path(id: @submission.id)
    end
    assert_redirected_to new_user_session_path
  end

  test "should not destroy submission when not owner" do
    sign_in @other_user
    assert_no_difference "Submission.count" do
      delete submission_path(id: @submission.id)
    end
    assert_redirected_to submissions_path
  end

  # Add tag tests
  test "should add tag when owner" do
    sign_in @user
    tag = create(:tag)
    assert_difference "@submission.tags.count", 1 do
      post add_tag_submission_path(id: @submission.id), params: { tag_id: tag.id }
    end
    assert_redirected_to submission_path(id: @submission.id)
  end

  test "should not add tag when not signed in" do
    tag = create(:tag)
    assert_no_difference "@submission.tags.count" do
      post add_tag_submission_path(id: @submission.id), params: { tag_id: tag.id }
    end
    assert_redirected_to new_user_session_path
  end

  test "should not add tag when not owner" do
    sign_in @other_user
    tag = create(:tag)
    assert_no_difference "@submission.tags.count" do
      post add_tag_submission_path(id: @submission.id), params: { tag_id: tag.id }
    end
    # Controller redirects to submissions index when not authorized
    assert_response :redirect
  end

  test "should not add duplicate tag" do
    sign_in @user
    tag = create(:tag)
    @submission.tags << tag
    
    assert_no_difference "@submission.tags.count" do
      post add_tag_submission_path(id: @submission.id), params: { tag_id: tag.id }
    end
    assert_redirected_to submission_path(id: @submission.id)
  end

  # Remove tag tests
  test "should remove tag when owner" do
    sign_in @user
    tag = create(:tag)
    @submission.tags << tag
    
    assert_difference "@submission.tags.count", -1 do
      delete remove_tag_submission_path(id: @submission.id), params: { tag_id: tag.id }
    end
    assert_redirected_to submission_path(id: @submission.id)
  end

  test "should not remove tag when not signed in" do
    tag = create(:tag)
    @submission.tags << tag
    
    assert_no_difference "@submission.tags.count" do
      delete remove_tag_submission_path(id: @submission.id), params: { tag_id: tag.id }
    end
    assert_redirected_to new_user_session_path
  end

  test "should not remove tag when not owner" do
    sign_in @other_user
    tag = create(:tag)
    @submission.tags << tag
    
    assert_no_difference "@submission.tags.count" do
      delete remove_tag_submission_path(id: @submission.id), params: { tag_id: tag.id }
    end
    # Controller redirects to submissions index when not authorized
    assert_response :redirect
  end

  # Follow tests
  test "should follow submission when signed in" do
    sign_in @user
    assert_difference "@submission.follows.count", 1 do
      post follow_submission_path(id: @submission.id)
    end
    assert_redirected_to submission_path(id: @submission.id)
  end

  test "should unfollow submission when already following" do
    sign_in @user
    create(:follow, followable: @submission, user: @user)
    
    assert_difference "@submission.follows.count", -1 do
      post follow_submission_path(id: @submission.id)
    end
    assert_redirected_to submission_path(id: @submission.id)
  end

  test "should not follow submission when not signed in" do
    assert_no_difference "@submission.follows.count" do
      post follow_submission_path(id: @submission.id)
    end
    assert_redirected_to new_user_session_path
  end
end

