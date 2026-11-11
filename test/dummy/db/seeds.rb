PASSWORD = "Password"

find_or_record_child = lambda do |recordable, root_recording, parent_recording|
  RecordingStudio::Recording.where(RecordingStudio::Recording.recording_studio_trashable_kept_sql).find_by(
    root_recording: root_recording,
    parent_recording: parent_recording,
    recordable: recordable
  ) || RecordingStudio.record!(
    action: "created",
    recordable: recordable,
    root_recording: root_recording,
    parent_recording: parent_recording
  ).recording
end

ensure_user = lambda do |email|
  User.find_or_create_by!(email: email) do |user|
    user.password = PASSWORD
    user.password_confirmation = PASSWORD
  end
end

admin = ensure_user.call("admin@admin.com")
alice = ensure_user.call("alice@example.com")
bob = ensure_user.call("bob@example.com")
charlie = ensure_user.call("charlie@example.com")

workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
accessible_workspace = Workspace.find_or_create_by!(name: "Client Workspace")
private_workspace = Workspace.find_or_create_by!(name: "Private Workspace")
folder = Folder.find_or_create_by!(name: "Product Docs")
page = Page.find_or_create_by!(title: "Getting Started")

previous_actor = Current.actor
Current.actor = admin

begin
  root_recording = RecordingStudio.root_recording_for(workspace)
  accessible_root_recording = RecordingStudio.root_recording_for(accessible_workspace)
  private_root_recording = RecordingStudio.root_recording_for(private_workspace)

  [root_recording, accessible_root_recording, private_root_recording].each do |recording|
    next if RecordingStudioAccessible::AccessGrantList.rows_for(recording).any?

    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: admin)
    raise result.error if result.failure?
  end

  folder_recording = find_or_record_child.call(folder, root_recording, root_recording)
  find_or_record_child.call(page, root_recording, folder_recording)

  {
    alice => :admin,
    bob => :edit,
    charlie => :view
  }.each do |actor, role|
    result = RecordingStudioAccessible.grant_access(
      recording: accessible_root_recording,
      actor: actor,
      role: role,
      manager_actor: admin
    )
    raise result.error if result.failure?
  end

  studio_view = RecordingStudioAccessible.grant_access(
    recording: root_recording,
    actor: alice,
    role: :view,
    manager_actor: admin
  )
  raise studio_view.error if studio_view.failure?
ensure
  Current.actor = previous_actor
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: alice@example.com, bob@example.com, charlie@example.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: Workspace '#{accessible_workspace.name}' with root recording ##{accessible_root_recording.id}"
puts "Seeded: Workspace '#{private_workspace.name}' with root recording ##{private_root_recording.id}"
puts "Seeded: Folder '#{folder.name}' and page '#{page.title}'"
