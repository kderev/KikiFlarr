import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var notificationService = NotificationService.shared
    @State private var showTMDBSheet = false

    var body: some View {
        NavigationStack {
            List {
                tmdbSection

                notificationsSection

                instancesSection

                aboutSection
            }
            .navigationTitle("Paramètres")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.resetForm()
                            viewModel.isAddingInstance = true
                        } label: {
                            Label("Ajouter une instance", systemImage: "server.rack")
                        }
                        
                        Button {
                            viewModel.resetGroupForm()
                            viewModel.isAddingGroup = true
                        } label: {
                            Label("Nouveau groupe", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isAddingInstance) {
                AddInstanceSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showTMDBSheet) {
                TMDBConfigSheet(instanceManager: instanceManager)
            }
            .sheet(isPresented: $viewModel.isAddingGroup) {
                GroupSheet(viewModel: viewModel, instanceManager: instanceManager)
            }
            .onAppear {
                viewModel.setInstanceManager(instanceManager)
            }
        }
    }
    
    private var tmdbSection: some View {
        Section {
            Button {
                showTMDBSheet = true
            } label: {
                HStack {
                    Image(systemName: "film.stack")
                        .foregroundColor(.blue)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TMDB")
                            .foregroundColor(.primary)
                        Text(instanceManager.hasTMDBConfigured ? "Configuré" : "Non configuré")
                            .font(.caption)
                            .foregroundColor(instanceManager.hasTMDBConfigured ? .green : .secondary)
                    }
                    
                    Spacer()
                    
                    if instanceManager.hasTMDBConfigured {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Films vus (TMDB)")
        } footer: {
            Text("Configurez TMDB pour pouvoir marquer des films comme vus, même s'ils ne sont pas dans votre bibliothèque")
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $notificationService.downloadNotificationsEnabled) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(.orange)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Téléchargements terminés")
                            .foregroundColor(.primary)
                        Text("Recevoir une notification")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(!notificationService.isAuthorized && notificationService.authorizationStatus != .notDetermined)

            if notificationService.authorizationStatus == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                            .frame(width: 28)
                        Text("Activer dans les réglages")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else if notificationService.authorizationStatus == .notDetermined {
                Button {
                    Task {
                        _ = await notificationService.requestAuthorization()
                    }
                } label: {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.blue)
                            .frame(width: 28)
                        Text("Autoriser les notifications")
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            if notificationService.authorizationStatus == .denied {
                Text("Les notifications sont désactivées. Activez-les dans les réglages pour recevoir des alertes.")
            } else if notificationService.authorizationStatus == .notDetermined {
                Text("Autorisez les notifications pour être alerté quand un téléchargement se termine.")
            } else {
                Text("Recevez une notification push quand un téléchargement qBittorrent se termine.")
            }
        }
    }

    private var instancesSection: some View {
        Group {
            if instanceManager.instances.isEmpty && instanceManager.groups.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("Aucune instance", systemImage: "server.rack")
                    } description: {
                        Text("Appuyez sur + pour ajouter une instance")
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Instances configurées")
                }
            } else {
                ForEach(instanceManager.groups) { group in
                    Section {
                        ForEach(instanceManager.instances(in: group)) { instance in
                            InstanceRow(instance: instance, instanceManager: instanceManager)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.prepareForEditing(instance)
                                    viewModel.isAddingInstance = true
                                }
                        }
                        .onDelete { offsets in
                            deleteInstances(in: group, at: offsets)
                        }
                    } header: {
                        HStack {
                            Image(systemName: group.icon)
                                .foregroundColor(group.color)
                            Text(group.name)
                            Spacer()
                            Button {
                                viewModel.prepareForEditingGroup(group)
                                viewModel.isAddingGroup = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                if !instanceManager.ungroupedInstances.isEmpty {
                    Section {
                        ForEach(instanceManager.ungroupedInstances) { instance in
                            InstanceRow(instance: instance, instanceManager: instanceManager)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.prepareForEditing(instance)
                                    viewModel.isAddingInstance = true
                                }
                        }
                        .onDelete { offsets in
                            deleteUngroupedInstances(at: offsets)
                        }
                    } header: {
                        Text("Sans groupe")
                    } footer: {
                        Text("Glissez vers la gauche pour supprimer une instance")
                    }
                }
            }
        }
    }
    
    private func deleteInstances(in group: InstanceGroup, at offsets: IndexSet) {
        let groupInstances = instanceManager.instances(in: group)
        for offset in offsets {
            let instance = groupInstances[offset]
            instanceManager.deleteInstance(instance)
        }
    }
    
    private func deleteUngroupedInstances(at offsets: IndexSet) {
        let ungrouped = instanceManager.ungroupedInstances
        for offset in offsets {
            let instance = ungrouped[offset]
            instanceManager.deleteInstance(instance)
        }
    }
    
    private var aboutSection: some View {
        Section("À propos") {
            HStack {
                Text("Version")
                Spacer()
                Text("2.0.0")
                    .foregroundColor(.secondary)
            }

            Link(destination: URL(string: "https://github.com/kderev/KikiFlarr")!) {
                HStack {
                    Text("Code source")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Optimized Add Instance Sheet

struct AddInstanceSheet: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var instanceManager: InstanceManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, url, username, password, apiKey
    }
    
    var body: some View {
        NavigationStack {
            Form {
                informationsSection
                connectionSection
                testSection
                errorSection
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(viewModel.formTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") {
                        viewModel.saveInstance()
                        dismiss()
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isTesting)
    }
    
    // MARK: - Sections extraites pour optimiser les re-renders
    
    @ViewBuilder
    private var informationsSection: some View {
        Section("Informations") {
            OptimizedTextField(
                placeholder: "Nom de l'instance",
                text: $viewModel.instanceName,
                contentType: .name,
                focusState: $focusedField,
                field: .name,
                onSubmit: { focusedField = .url }
            )
            
            Picker("Type de service", selection: $viewModel.instanceType) {
                ForEach(ServiceType.allCases) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }
            .disabled(viewModel.isEditing)
            
            Picker("Groupe", selection: $viewModel.selectedGroupId) {
                Text("Aucun groupe").tag(nil as UUID?)
                ForEach(instanceManager.groups) { group in
                    Label(group.name, systemImage: group.icon)
                        .tag(group.id as UUID?)
                }
            }
        }
    }
    
    @ViewBuilder
    private var connectionSection: some View {
        Section("Connexion") {
            OptimizedTextField(
                placeholder: "URL de base",
                text: $viewModel.instanceURL,
                contentType: .URL,
                keyboardType: .URL,
                focusState: $focusedField,
                field: .url,
                onSubmit: { focusedField = viewModel.isQBittorrent ? .username : .apiKey }
            )
            
            if viewModel.isLoadingCredentials {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Chargement...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if viewModel.isQBittorrent {
                OptimizedTextField(
                    placeholder: "Nom d'utilisateur",
                    text: $viewModel.username,
                    contentType: .username,
                    focusState: $focusedField,
                    field: .username,
                    onSubmit: { focusedField = .password }
                )
                
                OptimizedSecureField(
                    placeholder: "Mot de passe",
                    text: $viewModel.password,
                    focusState: $focusedField,
                    field: .password,
                    onSubmit: { focusedField = nil }
                )
            } else {
                OptimizedSecureField(
                    placeholder: "Clé API",
                    text: $viewModel.apiKey,
                    focusState: $focusedField,
                    field: .apiKey,
                    onSubmit: { focusedField = nil }
                )
            }
        }
    }
    
    @ViewBuilder
    private var testSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.testConnection()
                }
            } label: {
                HStack {
                    if viewModel.isTesting {
                        ProgressView()
                            .padding(.trailing, 8)
                    }
                    Text("Tester la connexion")
                }
            }
            .disabled(!viewModel.isFormValid || viewModel.isTesting || viewModel.isLoadingCredentials)
            
            if let result = viewModel.testResult {
                TestResultView(result: result)
            }
        }
    }
    
    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.validationError {
            Section {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Optimized TextField Components

struct OptimizedTextField: View {
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType? = nil
    var keyboardType: UIKeyboardType = .default
    @FocusState.Binding var focusState: AddInstanceSheet.Field?
    let field: AddInstanceSheet.Field
    var onSubmit: (() -> Void)? = nil
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textContentType(contentType)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focusState, equals: field)
            .submitLabel(onSubmit != nil ? .next : .done)
            .onSubmit { onSubmit?() }
    }
}

struct OptimizedSecureField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var focusState: AddInstanceSheet.Field?
    let field: AddInstanceSheet.Field
    var onSubmit: (() -> Void)? = nil
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .textContentType(.password)
            .focused($focusState, equals: field)
            .submitLabel(onSubmit != nil ? .next : .done)
            .onSubmit { onSubmit?() }
    }
}

struct TestResultView: View {
    let result: ConnectionTestResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.message)
                        .font(.subheadline)

                    HStack(spacing: 8) {
                        if let time = result.responseTime {
                            Text(String(format: "%.0f ms", time * 1000))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let httpCode = result.httpStatusCode {
                            Text("HTTP \(httpCode)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if !result.success, let suggestion = result.recoverySuggestion {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggestions:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)

                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(InstanceManager())
}

// MARK: - TMDB Configuration Sheet

struct TMDBConfigSheet: View {
    @ObservedObject var instanceManager: InstanceManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isAPIKeyFocused: Bool
    
    @State private var apiKey: String = ""
    @State private var isTesting = false
    @State private var testResult: ConnectionTestResult?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Clé API TMDB", text: $apiKey)
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isAPIKeyFocused)
                        .submitLabel(.done)
                        .onSubmit { isAPIKeyFocused = false }
                } header: {
                    Text("Clé API")
                } footer: {
                    Text("Obtenez votre clé API gratuite sur themoviedb.org")
                }
                
                Section {
                    Link(destination: URL(string: "https://www.themoviedb.org/settings/api")!) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.blue)
                            Text("Obtenir une clé API")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await testConnection()
                        }
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Tester la connexion")
                        }
                    }
                    .disabled(apiKey.isEmpty || isTesting)
                    
                    if let result = testResult {
                        TestResultView(result: result)
                    }
                }
                
                if instanceManager.hasTMDBConfigured {
                    Section {
                        Button(role: .destructive) {
                            instanceManager.saveTMDBApiKey("")
                            apiKey = ""
                            testResult = nil
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Supprimer la configuration")
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Configuration TMDB")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") {
                        instanceManager.saveTMDBApiKey(apiKey)
                        dismiss()
                    }
                    .disabled(apiKey.isEmpty)
                }
            }
            .onAppear {
                apiKey = instanceManager.tmdbApiKey
            }
        }
    }
    
    private func testConnection() async {
        isTesting = true
        testResult = nil
        
        let tempService = TMDBService(apiKey: apiKey)
        do {
            testResult = try await tempService.testConnection()
        } catch {
            testResult = ConnectionTestResult(
                success: false,
                message: error.localizedDescription,
                responseTime: nil
            )
        }
        
        isTesting = false
    }
}

// MARK: - Group Sheet

struct GroupSheet: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var instanceManager: InstanceManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations") {
                    TextField("Nom du groupe", text: $viewModel.groupName)
                        .textContentType(.name)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit { isNameFocused = false }
                }
                
                Section("Apparence") {
                    Picker("Icône", selection: $viewModel.groupIcon) {
                        ForEach(InstanceGroup.availableIcons, id: \.self) { icon in
                            Label(iconLabel(for: icon), systemImage: icon)
                                .tag(icon)
                        }
                    }
                    
                    Picker("Couleur", selection: $viewModel.groupColor) {
                        ForEach(InstanceGroup.availableColors, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(colorFor(color))
                                    .frame(width: 20, height: 20)
                                Text(colorLabel(for: color))
                            }
                            .tag(color)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: viewModel.groupIcon)
                                .font(.largeTitle)
                                .foregroundColor(colorFor(viewModel.groupColor))
                            Text(viewModel.groupName.isEmpty ? "Nom du groupe" : viewModel.groupName)
                                .font(.headline)
                                .foregroundColor(viewModel.groupName.isEmpty ? .secondary : .primary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Aperçu")
                }
                
                if viewModel.isEditingGroup, let group = viewModel.editingGroup {
                    Section {
                        Button(role: .destructive) {
                            instanceManager.deleteGroup(group)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Supprimer le groupe")
                            }
                        }
                    } footer: {
                        Text("Les instances du groupe ne seront pas supprimées, elles seront déplacées dans \"Sans groupe\"")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(viewModel.groupFormTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enregistrer") {
                        viewModel.saveGroup()
                        dismiss()
                    }
                    .disabled(!viewModel.isGroupFormValid)
                }
            }
        }
    }
    
    private func iconLabel(for icon: String) -> String {
        switch icon {
        case "server.rack": return "Serveur"
        case "externaldrive.connected.to.line.below": return "Stockage externe"
        case "cloud": return "Cloud"
        case "house": return "Maison"
        case "building.2": return "Bureau"
        case "network": return "Réseau"
        case "desktopcomputer": return "Ordinateur"
        case "laptopcomputer": return "Portable"
        case "internaldrive": return "Disque interne"
        case "opticaldiscdrive": return "Lecteur optique"
        default: return icon
        }
    }
    
    private func colorLabel(for color: String) -> String {
        switch color {
        case "red": return "Rouge"
        case "orange": return "Orange"
        case "yellow": return "Jaune"
        case "green": return "Vert"
        case "blue": return "Bleu"
        case "purple": return "Violet"
        case "pink": return "Rose"
        case "gray": return "Gris"
        default: return color
        }
    }
    
    private func colorFor(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "gray": return .gray
        default: return .blue
        }
    }
}
