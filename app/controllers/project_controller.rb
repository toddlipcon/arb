class ProjectController < ApplicationController

  def check_update
    @project = Project.by_name(params[:id]) or raise "No project"

    old_rev = params[:old_rev] or raise "No old rev"
    new_rev = params[:new_rev] or raise "No new rev"
    ref     = params[:ref] or raise "No ref"

    raise "Bad old rev" unless old_rev =~ /^\w{40}$/;
    raise "New old rev" unless new_rev =~ /^\w{40}$/;

    check_revs = @project.main_repository.git_rev_list(old_rev, new_rev)

    unapproved_revs = check_revs.select do |rev|
      commit = Commit.by_sha1(:project => @project,
                              :sha1 => rev)
      commit.nil? || ! commit.approved?
    end

    output = ""
    if !unapproved_revs.empty?
      render :json => {
        :output => "The following revisions have not been approved:\n" +
          unapproved_revs.map { |r| "\t#{r}" }.join("\n"),
        :allowed => false
      }
    else
      render :json => {
        :output => "ARB checks passed",
        :allowed => true
      }
    end
  end


end
