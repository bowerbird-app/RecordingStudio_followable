# frozen_string_literal: true

class CreateRecordingStudioFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_follows, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :target_recording_id, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :recording_studio_follows, :target_recording_id
  end
end
