Rails.application.routes.draw do
  devise_for :users

  get "/recording_studio", to: redirect("/"), as: nil
  mount RecordingStudio::Engine, at: "/recording_studio"
  mount RecordingStudioRootSwitchable::Engine, at: "/recording_studio_root_switchable"
  mount RecordingStudioNotifications::Engine, at: "/notifications"
  mount RecordingStudioFollowable::Engine, at: "/recording_studio_followable"

  get "up" => "rails/health#show", as: :rails_health_check

  get "sample/embed", to: "public_samples#embed", as: :public_sample_embed
  get "sample", to: "public_samples#show", as: :public_sample

  resources :pages, only: %i[index show] do
    member do
      post :notify_followers
    end
  end

  root "home#index"
end
