Rails.application.routes.draw do
  devise_for :users

  scope module: "recording_studio_user/auth", path: "users" do
    post "otp/start", to: "otp_challenges#create", as: :recording_studio_user_otp_start
    get "otp/challenge", to: "otp_challenges#show", as: :recording_studio_user_otp_challenge
    post "otp/challenge", to: "otp_challenges#submit"
    post "otp/resend", to: "otp_challenges#resend", as: :recording_studio_user_otp_resend
  end

  scope module: "recording_studio_user/auth", path: "auth" do
    post "otp/challenge", to: "otp_challenges#submit"
    post "otp/resend", to: "otp_challenges#resend"
  end

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
