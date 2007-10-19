class ProjectController < ApplicationController

  def check_update
    render :json => {
      :output => 'hello world',
      :allowed => false
    }
  end


end
