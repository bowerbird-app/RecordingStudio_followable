module ApplicationHelper
  def dummy_page_nav(title:, back_url: nil, back_label: "Home")
    recording_studio_page_nav(
      title: title,
      page_nav_back_url: back_url,
      page_nav_back_label: back_label
    )

    recording_studio_page_nav_right do
      concat dummy_root_switch_dropdown
      concat render(
        FlatPack::Button::Component.new(
          text: "Sign out",
          style: :ghost,
          size: :md,
          href: main_app.destroy_user_session_path,
          data: { turbo_method: :delete }
        )
      )
    end
  end

  # TODO: temporary shim. Root Switchable v0.10.0's dropdown template calls
  # FlatPack's button_attributes, which was removed in FlatPack v0.1.320.
  # The fix is in Root Switchable v0.11.0+, which needs recording_studio >= 6.1.
  # Remove the shim once a Root Switchable 0.10.x fix ships or the dummy moves to RS 6.x.
  def dummy_root_switch_dropdown
    list = recording_studio_root_switch_list_for
    return if list.blank?

    dropdown = FlatPack::Button::Dropdown::Component.new(
      text: list.menu_rows.current_label,
      disabled: list.menu_rows.switch_rows.empty?,
      style: :ghost,
      size: :md
    )
    dropdown.menu_html(
      render(RecordingStudioRootSwitchable::RootSwitch::RowsComponent.new(menu_rows: list.menu_rows))
    )
    render(dropdown)
  end
end
