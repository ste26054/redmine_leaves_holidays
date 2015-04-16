# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
	#resources :leaves_holidays
	
		# get 'my/leaves', :to => 'leaves_holidays#show', :as => 'leaves_holidays'
		match 'my/leaves', :controller => 'leaves_holidays', :action => 'show', :via => :get, :as => 'leaves_holidays'
end