import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var viewModel = SettingsViewModel()
    @State private var currentStep = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $currentStep) {
                    welcomeStep
                        .tag(0)
                    
                    overseerrStep
                        .tag(1)
                    
                    arrStep
                        .tag(2)
                    
                    qbittorrentStep
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                stepIndicator
                    .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.setInstanceManager(instanceManager)
            }
        }
    }
    
    // MARK: - Welcome Step
    
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "play.tv.fill")
                .font(.system(size: 80))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(spacing: 12) {
                Text("Bienvenue dans KikiFlarr")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Gérez vos médias depuis une seule application")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "magnifyingglass", title: "Recherche", description: "Trouvez films et séries via Overseerr")
                featureRow(icon: "arrow.down.circle", title: "Téléchargement", description: "Envoyez vers Radarr ou Sonarr")
                featureRow(icon: "chart.line.uptrend.xyaxis", title: "Suivi", description: "Suivez vos torrents via qBittorrent")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button {
                withAnimation {
                    currentStep = 1
                }
            } label: {
                Text("Commencer")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Overseerr Step
    
    private var overseerrStep: some View {
        instanceSetupStep(
            icon: "magnifyingglass",
            iconColor: .purple,
            title: "Configurer Overseerr",
            description: "Overseerr permet de rechercher des films et séries",
            serviceType: .overseerr,
            nextStep: 2,
            canSkip: true
        )
    }
    
    // MARK: - Arr Step
    
    private var arrStep: some View {
        VStack(spacing: 20) {
            Spacer()
            
            HStack(spacing: 20) {
                Image(systemName: "film")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                Image(systemName: "tv")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("Configurer Radarr / Sonarr")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Ajoutez au moins une instance pour envoyer vos demandes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button {
                    viewModel.resetForm()
                    viewModel.instanceType = .radarr
                    viewModel.isAddingInstance = true
                } label: {
                    HStack {
                        Image(systemName: "film")
                        Text("Ajouter Radarr")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button {
                    viewModel.resetForm()
                    viewModel.instanceType = .sonarr
                    viewModel.isAddingInstance = true
                } label: {
                    HStack {
                        Image(systemName: "tv")
                        Text("Ajouter Sonarr")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 40)
            
            if !instanceManager.radarrInstances.isEmpty || !instanceManager.sonarrInstances.isEmpty {
                VStack(spacing: 8) {
                    Text("Instances configurées:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(instanceManager.radarrInstances + instanceManager.sonarrInstances) { instance in
                        HStack {
                            Image(systemName: instance.serviceType.icon)
                            Text(instance.name)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button("Passer") {
                    withAnimation {
                        currentStep = 3
                    }
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Suivant") {
                    withAnimation {
                        currentStep = 3
                    }
                }
                .disabled(instanceManager.radarrInstances.isEmpty && instanceManager.sonarrInstances.isEmpty)
            }
            .padding(.horizontal, 40)
        }
        .padding()
        .sheet(isPresented: $viewModel.isAddingInstance) {
            AddInstanceSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - qBittorrent Step
    
    private var qbittorrentStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            VStack(spacing: 8) {
                Text("Configurer qBittorrent")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Optionnel - pour suivre vos téléchargements")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.resetForm()
                viewModel.instanceType = .qbittorrent
                viewModel.isAddingInstance = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Ajouter qBittorrent")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 40)

            if !instanceManager.qbittorrentInstances.isEmpty {
                ForEach(instanceManager.qbittorrentInstances) { instance in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(instance.name)
                    }
                    .font(.subheadline)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    // Onboarding terminé
                } label: {
                    Text("Terminer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasMinimumConfig ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!hasMinimumConfig)
                .padding(.horizontal, 40)

                if !hasMinimumConfig {
                    VStack(spacing: 8) {
                        Text("Configuration minimale requise:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Label("Au moins une instance Overseerr", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundColor(instanceManager.overseerrInstances.isEmpty ? .red : .green)

                            Label("Au moins une instance Radarr ou Sonarr", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundColor((instanceManager.radarrInstances.isEmpty && instanceManager.sonarrInstances.isEmpty) ? .red : .green)
                        }
                    }
                    .padding(.horizontal, 40)
                } else {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Conseil important")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        Text("Testez vos connexions depuis les paramètres pour vous assurer que tout fonctionne correctement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
        .padding()
        .sheet(isPresented: $viewModel.isAddingInstance) {
            AddInstanceSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Helper Views
    
    private func instanceSetupStep(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        serviceType: ServiceType,
        nextStep: Int,
        canSkip: Bool
    ) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(iconColor)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel.resetForm()
                viewModel.instanceType = serviceType
                viewModel.isAddingInstance = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Ajouter \(serviceType.rawValue)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(iconColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 40)
            
            if let instance = instanceManager.instances(of: serviceType).first {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(instance.name)
                }
                .font(.subheadline)
            }
            
            Spacer()
            
            HStack {
                if canSkip {
                    Button("Passer") {
                        withAnimation {
                            currentStep = nextStep
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Suivant") {
                    withAnimation {
                        currentStep = nextStep
                    }
                }
            }
            .padding(.horizontal, 40)
        }
        .padding()
        .sheet(isPresented: $viewModel.isAddingInstance) {
            AddInstanceSheet(viewModel: viewModel)
        }
    }
    
    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index == currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var hasMinimumConfig: Bool {
        !instanceManager.overseerrInstances.isEmpty &&
        (!instanceManager.radarrInstances.isEmpty || !instanceManager.sonarrInstances.isEmpty)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(InstanceManager())
}
