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

  def show
    @review = Review.find(params[:id])

    raise "no such review" if @review.nil?
  end

  def minimal_owners_to_approve
    @review = Review.find(params[:id])
    raise "no review" if @review.nil?

    render :json => @review.minimal_owners_to_approve
  end
end
