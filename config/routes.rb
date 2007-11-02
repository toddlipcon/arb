ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl',
    :action => 'wsdl'

  map.show 'project/:project/commit/sha1/:sha1/:action/:json',
    :controller => 'commit',
    :action => 'show',
    :project => /\w+/,
    :json => /(?:json)?/,
    :defaults => { :json => 0 }

  map.new 'comment/new',
    :controller => 'comment',
    :action => 'new'

  map.create 'comment/create',
    :controller => 'comment',
    :action => 'create'

  map.new 'review/new/:json',
    :controller => 'review',
    :action => 'new',
    :json => /(?:json)?/,
    :defaults => { :json => 0 }

  map.new 'review/:id/show/json',
    :controller => 'review',
    :action => 'show',
    :json => 1

  map.notify 'review/:id/notify/:reviewer',
    :controller => 'review',
    :action => 'notify',
    :reviewer => /\w+/

  # Install the default route as the lowest priority.
  map.connect ':controller/:id/:action'
end
