
RedmineApp::Application.routes.draw do

	resources :leave_requests do
		member do
			get 'submit'
			get 'unsubmit'
		end
		collection do
			get 'leave_length'
			get 'leave_issue_description'
		end
		resource :leave_status, :except => [:show]
		resources :leave_votes, :except => [:show]
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

	resources :leave_rules

	resources :projects do
		match 'leave_management_rules/edit', :to => 'leave_management_rules#edit', :via => [:get, :post], as: :leave_management_rules_edit
		match 'leave_management_rules/update', :to => 'leave_management_rules#update', :via => [:get, :post], as: :leave_management_rules_update
		match 'leave_management_rules/enable', :to => 'leave_management_rules#enable', :via => [:get], as: :leave_management_rules_enable
		match 'leave_management_rules/disable', :to => 'leave_management_rules#disable', :via => [:get], as: :leave_management_rules_disable
		
		match 'leave_administrators/edit', :to => 'leave_administrators#edit', :via => [:get, :post], as: :leave_administrators_edit
		match 'leave_administrators/update', :to => 'leave_administrators#update', :via => [:get, :post], as: :leave_administrators_update
		match 'leave_administrators/clear', :to => 'leave_administrators#clear', :via => [:get], as: :leave_administrators_clear
	end

	get '/leave_approvals', :to => 'leave_approvals#index'
	get '/leave_timeline', :to => 'leave_timelines#show'
	get '/projects/:project_id/leave_timeline', :to => 'leave_timelines#show_project'
	get '/leave_management_rules/:project_id/show_metrics', :to => 'leave_management_rules#show_metrics', as: :leave_rules_show_metrics

	get '/leave_feedbacks/new', :to => 'leave_requests#feedback_new', as: :leave_feedbacks_new
	post '/leave_feedbacks/send', :to => 'leave_requests#feedback_send', as: :leave_feedbacks_send

	
end