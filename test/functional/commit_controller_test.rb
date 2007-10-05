require File.dirname(__FILE__) + '/../test_helper'
require 'commit_controller'

# Re-raise errors caught by the controller.
class CommitController; def rescue_action(e) raise e end; end

class CommitControllerTest < Test::Unit::TestCase
  def setup
    @controller = CommitController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
