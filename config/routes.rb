# frozen_string_literal: true

RecordingStudioFollowable::Engine.routes.draw do
  post "follows", to: "follows#create", as: :follows
  delete "follows", to: "follows#destroy"
end
