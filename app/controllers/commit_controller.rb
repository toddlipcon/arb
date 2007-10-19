class CommitController < ApplicationController
  helper :diff
  helper :chunk

  before_filter :authenticate, :only => [:approve]

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

  def changed
    render :json => @commit.changed_files
  end

  def owners
    render :json => @commit.minimal_owners_to_approve
  end

  def approve
    raise "no commit" if @commit.nil?
    @approval = Approval.new(
                            :commit => @commit,
                            :approved_by => session[:username],
                            :approved_on => Time.new()
                               )

    begin
      @approval.save
    rescue ActiveRecord::StatementInvalid
      # Probably trying to approve something already approved
      render :text => 'Cannot approve same commit twice' and return
    end
    render :text => 'Commit approved'
  end

end
