# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
	# match 'leaves_holidays', :to => 'leaves_holidays#leaves', :via => :get
	#  match 'leaves_holidays', :to => 'leaves_holidays#create_leave', :via => :post
	# get 'leaves', :to => 'leave_request#index'
	resources :leave_requests
end