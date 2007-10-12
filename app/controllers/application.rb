# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  def render(args)
    if args[:json]
      @headers['Content-Type'] = 'text/javascript'
      
      obj = args.delete(:json)
      args[:text] = obj.to_json
      super(args)
    else
      super(*args)
    end
  end

end
