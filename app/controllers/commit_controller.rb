class CommitController < ApplicationController
  def diff
    @commit = Commit.new(:sha1 => params[:sha1])

    @diff = @commit.diff
  end
end
