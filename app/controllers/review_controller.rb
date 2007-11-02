class ReviewController < ApplicationController
  helper :diff
  helper :chunk
  helper :commit

  def new
    puts params.to_yaml

    @project = Project.by_name(params[:project])
    raise "bad project" if @project.nil?

    @review = Review.new
    puts Review.column_names.inspect

    Review.column_names.each do |c|
      @review[c.to_sym] = params[c] if params.include?(c)
    end

    @review.project = @project
    
    puts "review is: #{@review.inspect}"

    @review.save!

    puts "id is: #{@review.id}"

    if params[:json]
      render :json => @review
    else
      render :text => 'text rendering not impl'
    end
  end

  def get_review
    @review = Review.find(params[:id])
    raise "no review" if @review.nil?
  end

  def show
    get_review

    if params[:json]
      render :json => @review
    end
  end

  def minimal_owners_to_approve
    get_review
    render :json => @review.minimal_owners_to_approve
  end

  def notify
    get_review
    @reviewer = params[:reviewer]

    Notifier.deliver_new_review(@review, @reviewer)
    render :json =>
      {:success => true }
  end

  def approved
    get_review
    render :json => @review.approved?
  end
end
