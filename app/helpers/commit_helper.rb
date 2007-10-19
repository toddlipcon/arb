module CommitHelper

  def review_status(commit)
    owners_hash = commit.applicable_owners_files_hash

    approvals = commit.approvals.map { |a| a.approved_by }

    render_partial 'commit/review_status', nil,
        :approvals => approvals,
        :owners_hash      => owners_hash


  end
end
