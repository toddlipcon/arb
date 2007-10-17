# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  before_filter :authenticate

  def render(args = {})
    if ! args[:json].nil?
      @headers['Content-Type'] = 'text/javascript'
      
      obj = args.delete(:json)
      args[:text] = obj.to_json
      super(args)
    else
      super(args)
    end
  end


##
# Taken from http://wiki.rubyonrails.org/rails/pages/HowtoAuthenticateWithHTTP
##
  def get_auth_data
    auth_data = nil
    [
      'REDIRECT_REDIRECT_X_HTTP_AUTHORIZATION',
      'REDIRECT_X_HTTP_AUTHORIZATION',
      'X-HTTP_AUTHORIZATION', 
      'HTTP_AUTHORIZATION'
    ].each do |key|
      if request.env.has_key?(key)
        auth_data = request.env[key].to_s.split
        break
      end
    end

    if auth_data && auth_data[0] == 'Basic' 
      return Base64.decode64(auth_data[1]).split(':')[0..1] 
    end 
  end


##
# Authenticate user using HTTP Basic Auth
##
  def authenticate
    login, password = get_auth_data
    if authorize(login, password)
      session[:username] = login
      return true
    end

    response.headers["Status"] = 'Unauthorized'
    response.headers['WWW-Authenticate'] = 'Basic realm="ARB"'
    render :text => "Authentication required", :status => 401
  end


  def authorize(username, password)
    return username == 'todd'
  end
end
