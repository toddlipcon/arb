class CommitController < ApplicationController
  helper :diff

  before_filter :get_commit

  def get_commit
    @commit = Commit.by_sha1(params[:sha1])
  end

  def diff
    @diff = @commit.diff
  end

  def show
  end

  def json
    render :json => @commit
  end

  def approved
    render :json => @commit.approved?
  end
end
