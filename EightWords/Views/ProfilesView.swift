import SwiftUI

struct ProfilesView: View {
    @EnvironmentObject private var learningStore: LearningProfileStore
    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""
    @State private var showingNewProfile = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(learningStore.profiles) { profile in
                        Button {
                            learningStore.activate(profile.id)
                        } label: {
                            HStack(spacing: 13) {
                                Text(String(profile.name.prefix(1)).uppercased())
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 42, height: 42)
                                    .background(AppColors.ink, in: Circle())
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(profile.name)
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppColors.ink)
                                    Text("\(profile.points) points · \(profile.streak)-day streak")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppColors.muted)
                                }
                                Spacer()
                                if profile.id == learningStore.activeProfileID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 21, weight: .bold))
                                        .foregroundStyle(AppColors.ink)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            if learningStore.profiles.count > 1 {
                                Button(role: .destructive) {
                                    learningStore.delete(profile.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text("Profiles on this device")
                } footer: {
                    Text("Each profile keeps separate daily progress, saved words, points, streaks, and rewards. No email or password is required.")
                }

                Section {
                    Button {
                        showingNewProfile = true
                    } label: {
                        Label("Add learner profile", systemImage: "person.badge.plus")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .disabled(learningStore.profiles.count >= 6)
                } footer: {
                    Text("Up to six profiles can be stored locally.")
                }
            }
            .navigationTitle("Learner Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .alert("New learner", isPresented: $showingNewProfile) {
                TextField("Name", text: $newName)
                Button("Cancel", role: .cancel) { newName = "" }
                Button("Create") {
                    _ = learningStore.createProfile(name: newName)
                    newName = ""
                }
            } message: {
                Text("Progress stays privately on this device.")
            }
        }
        .tint(AppColors.ink)
    }
}

#Preview {
    ProfilesView()
        .environmentObject(LearningProfileStore())
}

