# frozen_string_literal: true

RecordingStudioFollowable::Engine.routes.draw do
  get "follows", to: "follows#index", as: :follows
  post "follows", to: "follows#create"
  delete "follows", to: "follows#destroy"
  get "follow_sign_in/setup", to: "follow_sign_ins#setup", as: :follow_sign_in_setup
  get "follow_sign_in", to: "follow_sign_ins#new", as: :follow_sign_in
  post "follow_sign_in", to: "follow_sign_ins#create"
end
