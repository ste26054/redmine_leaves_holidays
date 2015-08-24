# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
	# match 'leaves_holidays', :to => 'leaves_holidays#leaves', :via => :get
	#  match 'leaves_holidays', :to => 'leaves_holidays#create_leave', :via => :post
	# get 'leaves', :to => 'leave_request#index'
	resources :leave_requests do
		member do
			get 'submit'
			get 'unsubmit'
		end
		resource :leave_statuses
		resources :leave_votes
	end

	resources :users do
		resource :leave_preferences do
			get 'notification'
		end
	end

	get '/leave_preferences', :to => 'leave_preferences#index'
	get '/leave_approvals', :to => 'leave_approvals#index'
	get '/leave_calendars', :to => 'leave_calendars#show'

end