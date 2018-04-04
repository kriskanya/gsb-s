Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'events#index'
  resources :events, only: [:index]
  post "events/clear_database" => "events#clear_database"
  post "events/scrape" => "events#scrape"
  get "events/export_csv" => "events#export_csv"
  get "events/export_csv2" => "events#export_csv2"
end
