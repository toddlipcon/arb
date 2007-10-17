class CommitController < ApplicationController
  helper :diff
  helper :file_change_set

  before_filter :get_commit

  def get_commit
    @project = Project.find(:first, :conditions => [ 'name = ?', params[:project] ])
    puts "Project is #{@project.inspect}"
    @commit = Commit.by_sha1(:sha1 => params[:sha1],
                             :project => @project)
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
