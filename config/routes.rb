# frozen_string_literal: true

RecordingStudioFollowable::Engine.routes.draw do
  get "follows", to: "follows#index", as: :follows
  post "follows", to: "follows#create"
  delete "follows", to: "follows#destroy"
  get "follow_sign_in", to: "follow_sign_ins#new", as: :follow_sign_in
  post "follow_sign_in", to: "follow_sign_ins#create"
  get "follow_sign_in/verify", to: "follow_sign_ins#verify", as: :follow_sign_in_verify
  post "follow_sign_in/verify", to: "follow_sign_ins#submit"
end
