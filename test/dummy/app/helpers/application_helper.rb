module ApplicationHelper
  include RecordingStudio::LayoutHelper
  include RecordingStudioNotifications::MenuHelper if defined?(RecordingStudioNotifications::MenuHelper)

  def dummy_page_nav(title: nil, back_url: nil, back_label: "Home")
    content_for(:title, title) if title.present?
    if back_url.present?
      flat_pack_page_nav(round: true, style: :default, anchor_href: back_url, anchor_tooltip: back_label)
    else
      flat_pack_page_nav(round: true, style: :default)
    end
    register_page_nav "Pages", main_app.pages_path, role: :secondary
    register_page_nav "Following", recording_studio_followable.follows_path, role: :secondary
    register_page_nav "Inbox", recording_studio_notifications.notifications_path, role: :secondary

    recording_studio_page_nav_right do
      concat dummy_root_switch_dropdown
      concat recording_studio_notifications_menu if respond_to?(:recording_studio_notifications_menu)
      concat dummy_nav_button("Sign out", main_app.destroy_user_session_path, turbo_method: :delete)
    end
  end

  def dummy_root_switch_dropdown
    return unless respond_to?(:recording_studio_root_switch_dropdown)

    recording_studio_root_switch_dropdown(style: :ghost, size: :md)
  rescue StandardError
    nil
  end

  def recording_studio_notifications_menu(limit: 5)
    return unless user_signed_in?
    return unless respond_to?(:recording_studio_notifications_async_menu)

    recording_studio_notifications_async_menu(recipient: current_user, limit: limit)
  rescue StandardError
    nil
  end

  private

  def dummy_nav_button(text, href, turbo_method: nil)
    render FlatPack::Button::Component.new(
      text: text,
      style: :ghost,
      size: :md,
      href: href,
      data: turbo_method ? { turbo_method: turbo_method } : {}
    )
  end
end
