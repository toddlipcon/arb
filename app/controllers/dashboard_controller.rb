class DashboardController < ApplicationController
  before_filter :authenticate

  def index
    @pending_reviews =
      Review.find(:all,
                  :conditions => [
                    'developer = ? AND ' +
                    'created_on > NOW() - INTERVAL 1 WEEK',
                    session[:username]],
                  :order => 'created_on desc')
  end
end
