
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
		match 'leave_management_rules/edit', :to => 'leave_management_rules#edit', :via => [:get, :post], as: :leave_management_rules_edit
		match 'leave_management_rules/update', :to => 'leave_management_rules#update', :via => [:get, :post], as: :leave_management_rules_update
		
		match 'leave_administrators/edit', :to => 'leave_administrators#edit', :via => [:get, :post], as: :leave_administrators_edit
		match 'leave_administrators/update', :to => 'leave_administrators#update', :via => [:get, :post], as: :leave_administrators_update
		match 'leave_administrators/clear', :to => 'leave_administrators#clear', :via => [:get], as: :leave_administrators_clear
	end

	get '/leave_approvals', :to => 'leave_approvals#index'
	get '/leave_calendars', :to => 'leave_calendars#show'
	get '/leave_timeline', :to => 'leave_timelines#show'
	get '/projects/:project_id/leave_timeline', :to => 'leave_timelines#show_project'
	get '/leave_management_rules/:project_id/show_metrics', :to => 'leave_management_rules#show_metrics', as: :leave_rules_show_metrics
	
end