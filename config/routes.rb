Rails.application.routes.draw do
  root "hello#index"

  namespace :api do
    namespace :v1 do
      # Auth
      post   "auth/register", to: "auth#register"
      post   "auth/login",    to: "auth#login"
      get    "auth/me",       to: "auth#me"

      # Users
      resources :users, only: [:index, :show] do
        collection do
          get  :professionals
          post :assign_manager
          delete :remove_manager
        end
      end

      # Schedule Entries
      resources :schedule_entries do
        member do
          post :cancel
          get  :conflicts
        end
        collection do
          get :check_conflicts
        end
        resources :participations, only: [:index, :create, :update]
      end

      # Tasks
      resources :tasks do
        member do
          post :complete
        end
      end

      # Notifications
      resources :notifications, only: [:index] do
        member do
          post :mark_read
        end
        collection do
          post :mark_all_read
        end
      end

      # Audit Logs
      resources :audit_logs, only: [:index]

      # Projects
      resources :projects do
        resources :assignments, only: [:index, :create, :update]
      end

      # Assignments (standalone)
      resources :assignments, only: [:index, :create, :update]
    end
  end
end
