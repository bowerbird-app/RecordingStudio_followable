# frozen_string_literal: true

RecordingStudioFollowable::Engine.routes.draw do
  get "follows", to: "follows#index", as: :follows
  post "follows", to: "follows#create"
  delete "follows", to: "follows#destroy"
end
