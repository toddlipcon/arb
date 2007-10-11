class CommitController < ApplicationController
  helper :diff

  def diff
    @commit = Commit.new(:sha1 => params[:sha1])

    @diff = @commit.diff
  end

  def show
    @commit = Commit.new(:sha1 => params[:sha1])
  end
end
