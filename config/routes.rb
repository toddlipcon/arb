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

  map.show 'project/:project/commit/sha1/:sha1/:action',
    :controller => 'commit',
    :action => 'show',
    :project => /\w+/

  map.new 'review/new/:json',
    :controller => 'review',
    :action => 'new',
    :json => /(?:json)?/,
    :defaults => { :json => 0 }

  map.add_commit 'review/:review_id/add/commit/sha1/:sha1/:json',
    :controller => 'review',
    :action => 'add_commit',
    :json => /(?:json)?/,
    :defaults => { :json => 0 }

  map.connect 'commit/sha1/:sha1/:action',
    :controller => 'commit',
    :action     => 'show'

  map.connect 'commit/id/:id/:action',
    :controller => 'commit'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end
