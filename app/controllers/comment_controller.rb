class CommentController < ApplicationController
  before_filter :authenticate, :only => [:create]

  def create
    @comment = Comment.new(params[:comment])

    @line_id = @comment.index_hash + '_line_' + @comment.line_number.to_s
    @inserted_id = @line_id + '_inserted';

    @comment.commenter = session[:username]
    @comment.written_on = Time.new

    if @comment.nil?
      raise "no comment"
    end

    if ! @comment.save 
      puts "not saved!"
      render :update do |page|
        page.replace_html @inserted_id, :partial => 'review/new_comment_ajax_row'
      end
      return
    end

    puts "saved"

    if request.xhr?
      puts "rendering rjs"
      render :action => 'create_xhr' and return
    end

    puts "rendering rhtml"

  end

end
 
