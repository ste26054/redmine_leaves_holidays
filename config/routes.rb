# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
	match 'my/leaves', :to => 'my#leaves', :via => :get
end