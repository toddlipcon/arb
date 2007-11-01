class Notifier < ActionMailer::Base

  def new_review(review, reviewer_username)
    recipients "#{reviewer_username}@amiestreet.com"
    from "#{review.developer}@amiestreet.com"
    subject "New review ##{review.id} for #{review.project.name}"

    body :review => review,
      :reviewer_username => reviewer_username
  end
end
