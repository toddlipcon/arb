class CommitController < ApplicationController
  def diff
    @commit = Commit.new(:sha1 => params[:sha1])

    @headers["Content-Type"] = 'text/plain'
    render :text => @commit.diff_tree
  end
end
