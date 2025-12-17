require "test_helper"

class ApplicationNotifierTest < ActiveSupport::TestCase
  test "should prevent self-notifications" do
    user = users(:one)
    
    # This should not deliver if recipient == actor
    assert_nothing_raised do
      ApplicationNotifier.deliver_if_not_self(user, user) do
        # This block should not execute
        flunk "Should not execute block for self-notification"
      end
    end
  end
  
  test "should allow notifications for different users" do
    user1 = users(:one)
    user2 = users(:two)
    executed = false
    
    ApplicationNotifier.deliver_if_not_self(user1, user2) do
      executed = true
    end
    
    assert executed, "Block should execute for different users"
  end
end

