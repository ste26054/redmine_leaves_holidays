
RedmineApp::Application.routes.draw do

	resources :leave_requests do
		member do
			get 'submit'
			get 'unsubmit'
		end
		resource :leave_status
		resources :leave_votes
	end

	resources :users do
		resource :leave_preference do
			get 'notification'
			get 'manage_pending_days'
		end
	end

	resources :leave_preferences, :only => [:index] do
		collection do
			match '/bulk_edit', :to => 'leave_preferences#bulk_edit', :via => [:get, :post]
			put '/bulk_update', :to => 'leave_preferences#bulk_update'
			get '/clear_filters', :to => 'leave_preferences#clear_filters'
		end
	end

	resources :projects do
		match '/projects/:project_id/leave_management_rules/edit', :to => 'leave_management_rules#edit', :via => [:get, :post], as: :leave_management_rules_edit
		match '/projects/:project_id/leave_management_rules/update', :to => 'leave_management_rules#update', :via => [:get, :post], as: :leave_management_rules_update
	end

	get '/leave_approvals', :to => 'leave_approvals#index'
	get '/leave_calendars', :to => 'leave_calendars#show'
	get '/leave_timeline', :to => 'leave_timelines#show'
	get '/projects/:project_id/leave_timeline', :to => 'leave_timelines#show_project'
	
end