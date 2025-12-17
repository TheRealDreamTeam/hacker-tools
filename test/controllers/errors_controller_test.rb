require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "renders not found page with navbar" do
    get "/404"

    assert_response :not_found
    assert_select "nav#navbar"
    assert_select "p", text: I18n.t("errors.pages.message")
  end

  test "renders internal server error page with navbar" do
    get "/500"

    assert_response :internal_server_error
    assert_select "nav#navbar"
    assert_select "p", text: I18n.t("errors.pages.message")
  end
end

