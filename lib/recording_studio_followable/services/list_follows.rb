# frozen_string_literal: true

module RecordingStudioFollowable
  FollowsPage = Struct.new(:records, :next_cursor, keyword_init: true)

  module Services
    class ListFollows
      def self.call(...)
        new(...).call
      end

      def initialize(root:, actor:, limit: nil, cursor: nil)
        @root = RecordingIdentity.follow_root_for(root)
        @actor = actor
        @limit = limit
        @cursor = cursor
      end

      def call
        Authorization.assert_view!(actor: @actor, recording: @root)
        return FollowQuery.for_root(@root) if @limit.blank?

        records, next_cursor = FollowQuery.page_for_root(@root, limit: @limit, cursor: @cursor)
        FollowsPage.new(records: records, next_cursor: next_cursor)
      end
    end
  end
end
