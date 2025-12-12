require "application_system_test_case"

class SubmissionsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, email: "submission_test@example.com", password: "password123")
    @submission = create(:submission, user: @user, submission_url: "https://example.com/article")
  end

  test "visiting the index" do
    visit submissions_url
    assert_selector "h1", text: I18n.t("submissions.index.title")
  end

  test "should create a submission" do
    sign_in @user
    visit new_submission_url
    
    fill_in I18n.t("submissions.form.submission_url"), with: "https://example.com/new-article"
    fill_in I18n.t("submissions.form.author_note"), with: "This is a test article"
    
    click_on I18n.t("actions.submit")
    
    assert_text I18n.t("submissions.create.success")
    assert_current_path submission_path(id: Submission.last.id)
  end

  test "should show submission" do
    visit submission_url(id: @submission.id)
    assert_text @submission.submission_url
  end

  test "should update submission when owner" do
    sign_in @user
    visit edit_submission_url(id: @submission.id)
    
    fill_in I18n.t("submissions.form.author_note"), with: "Updated note"
    click_on I18n.t("actions.submit")
    
    assert_text I18n.t("submissions.update.success")
    @submission.reload
    assert_equal "Updated note", @submission.author_note
  end

  test "should not allow edit when not owner" do
    other_user = create(:user)
    sign_in other_user
    
    visit edit_submission_url(id: @submission.id)
    assert_current_path submissions_path
    assert_text I18n.t("submissions.flash.unauthorized")
  end

  test "should destroy submission when owner" do
    sign_in @user
    visit submission_url(id: @submission.id)
    
    # Find and click delete button
    accept_confirm do
      click_button I18n.t("actions.delete")
    end
    
    assert_text I18n.t("submissions.destroy.success")
    assert_current_path submissions_path
  end

  test "should add tag to submission" do
    sign_in @user
    tag = create(:tag, tag_name: "Test Tag")
    
    visit submission_url(id: @submission.id)
    click_button I18n.t("submissions.actions.add_tag")
    
    click_button tag.display_name
    
    assert_text tag.display_name
    assert_text I18n.t("submissions.add_tag.success", tag: tag.tag_name)
  end

  test "should follow submission" do
    sign_in @user
    visit submission_url(id: @submission.id)
    
    # Find and click follow button
    within "#submission-#{@submission.id}-interactions" do
      click_button I18n.t("submissions.actions.follow")
    end
    
    assert_text I18n.t("submissions.follow.success")
  end
end

