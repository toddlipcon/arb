require 'pam'

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
    return false if username.nil?

    conv_data = username

    pam_conv = proc do |msgs, data|
      ret = []

      msgs.each do |msg|
        case msg.msg_style
        when PAM::PAM_PROMPT_ECHO_ON
          ret.push(PAM::Response.new(username, 0))
        when PAM::PAM_PROMPT_ECHO_OFF
          ret.push(PAM::Response.new(password, 0))
        else
          ret.push(PAM::Response.new(nil, 0))
        end
      end

      ret

    end

    PAM.start('arb', username, pam_conv, conv_data) do |pam|
      begin
        pam.authenticate(0)
      rescue
        return false
      end
      
      begin
        pam.acct_mgmt(0)
        pam.open_session {}
      rescue PAM::PAMError
        return false
      end
    end

    return true
  end
end
