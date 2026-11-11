# frozen_string_literal: true

module RecordingStudioFollowable
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioFollowable

    class << self
      def apply_model_extensions(target)
        apply_extensions(target, extensions_for(:model, extension_keys_for(target)))
      end

      def apply_controller_extensions(target)
        apply_extensions(target, extensions_for(:controller, extension_keys_for(target)))
      end

      def load_host_config(app)
        merge_yaml_config(app)
        merge_x_config(app)
        RecordingStudioFollowable.configuration.hooks.run(
          :on_configuration,
          RecordingStudioFollowable.configuration
        )
      end

      private

      def extensions_for(kind, names)
        hooks = RecordingStudioFollowable.configuration.hooks
        Array(names).flat_map do |name|
          if kind == :model
            hooks.model_extensions_for(name)
          else
            hooks.controller_extensions_for(name)
          end
        end
      end

      def apply_extensions(target, extensions)
        return unless target

        applied = target.instance_variable_get(:@recording_studio_followable_applied_extensions) || identity_hash

        extensions.flatten.compact.each do |extension|
          next if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end

        target.instance_variable_set(:@recording_studio_followable_applied_extensions, applied)
      end

      def extension_keys_for(target)
        names = [target.name, target.name&.demodulize].compact.uniq
        names.map(&:to_sym)
      end

      def identity_hash
        {}.compare_by_identity
      end

      def merge_yaml_config(app)
        return unless app.respond_to?(:config_for)

        yaml = ignore_standard_error { app.config_for(:recording_studio_followable) }
        ignore_standard_error { RecordingStudioFollowable.configuration.merge!(yaml) if yaml.respond_to?(:each) }
      end

      def merge_x_config(app)
        return unless app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_followable)

        xcfg = app.config.x.recording_studio_followable
        hash = xcfg.respond_to?(:to_h) ? xcfg.to_h : ignore_standard_error { each_pair_hash(xcfg) }
        RecordingStudioFollowable.configuration.merge!(hash) if hash&.any?
      end

      def each_pair_hash(xcfg)
        hash = {}
        xcfg.each_pair { |k, v| hash[k] = v } if xcfg.respond_to?(:each_pair)
        hash
      end

      def ignore_standard_error
        yield
      rescue StandardError
        nil
      end
    end

    initializer "recording_studio_followable.before_initialize",
                before: "recording_studio_followable.load_config" do |_app|
      RecordingStudioFollowable.configuration.hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_followable.load_config" do |app|
      RecordingStudioFollowable::Engine.load_host_config(app)
    end

    initializer "recording_studio_followable.after_initialize",
                after: "recording_studio_followable.load_config" do |_app|
      RecordingStudioFollowable.configuration.hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_followable.apply_model_extensions" do
      config.to_prepare do
        next unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?

          RecordingStudioFollowable::Engine.apply_model_extensions(model)
        end
      end
    end

    initializer "recording_studio_followable.apply_controller_extensions" do
      config.to_prepare do
        next unless defined?(ActionController::Base)

        ActionController::Base.descendants.each do |controller|
          RecordingStudioFollowable::Engine.apply_controller_extensions(controller)
        end
      end
    end
  end
end
