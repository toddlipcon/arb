class CommitController < ApplicationController
  helper :diff
  helper :chunk

  before_filter :authenticate, :only => [:approve]

  before_filter :get_commit

  def get_commit
    @project = Project.find(:first, :conditions => [ 'name = ?', params[:project] ])
    @commit = ArbCommit.new(@project, params[:sha1])
    
    raise "Commit not in review repository" unless @commit.exists_in_review_repository?
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

  def applicable_owners_file_hash
    render :json => @commit.applicable_owners_files_hash
  end

  def approve
    begin
      raise "no commit" if @commit.nil?
      raise "not in review repository" unless @commit.exists_in_review_repository?
      raise "not allowed" unless @commit.allowed_approvers.include?(session[:username])
    rescue Exception => e
      if params[:json]
        render :json => {
          :success => '0',
          :reason => e
        }
      else
        render :text => 'Error: ' + e
      end
      return
    end

    @approval = Approval.new(
                            :commit_sha1 => @commit.review_commit.full_revision,
                            :approved_by => session[:username],
                            :approved_on => Time.new()
                               )

    begin
      @approval.save
    rescue ActiveRecord::StatementInvalid
      # Probably trying to approve something already approved

      if params[:json]
        render :json => {
          :success => '0',
          :reason => 'Cannot approve same commit twice'
        }
        return
      else
        render :text => 'Cannot approve same commit twice'
        return
      end
    end

    if params[:json]
      render :json => {
        :success => 1
      }
    else
      render :text => 'Commit approved'
    end
  end

end
