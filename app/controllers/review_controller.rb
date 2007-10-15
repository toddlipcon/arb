class ReviewController < ApplicationController
  helper :diff

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

  def add_commit
    @review = Review.find(params[:review_id])
    raise "no such review" if @review.nil?

    @commit = Commit.by_sha1(
                             :sha1 => params[:sha1],
                             :project => @review.project
                             )
    puts "commit: #{@commit.inspect}"
    raise "no such commit" if @commit.nil? || ! @commit.valid?

    @review.commits << @commit

    if params[:json]
      render :json => { :success => true }
    else
      render :text => 'successful';
    end
  end


  def show
    @review = Review.find(params[:id])
    raise "no such review" if @review.nil?
  end
end
