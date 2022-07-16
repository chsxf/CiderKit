import SwiftUI
import CiderKit_Engine

fileprivate struct ProjectDetails {
    let url: URL
    let error: String
}

fileprivate struct ProjectOperationModifier: ViewModifier {
    var isPresented: Binding<Bool>
    var projectDetails: ProjectDetails?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: isPresented, presenting: projectDetails) { details in
                Button("OK", role: .cancel) { }
            } message: { details in
                Text(details.error)
            }
    }
}

struct ProjectManagerView: View {
    @EnvironmentObject var projectManager: ProjectManager
    
    var hostingWindow: NSWindow
    
    @State private var newProjectAlertShown = false
    @State private var openProjectAlertShown = false
    @State private var projectDetails: ProjectDetails?
    
    fileprivate func selectFolderPanel(canCreateDirectories: Bool) -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = canCreateDirectories
        let response = panel.runModal()
        return response == .OK ? panel.url : nil
    }
    
    fileprivate static func getProjectDetailsFromError(url: URL, error: Error) -> ProjectDetails {
        switch error {
        case let projectError as ProjectErrors:
            return ProjectDetails(url: url, error: projectError.rawValue)
        case let projectManagerError as ProjectManagerErrors:
            return ProjectDetails(url: url, error: projectManagerError.rawValue)
        default:
            return ProjectDetails(url: url, error: error.localizedDescription)
        }
    }
    
    fileprivate func dismiss(response: NSApplication.ModalResponse) {
        CiderKitApp.mainWindow.endSheet(hostingWindow, returnCode: response)
    }
    
    fileprivate func openProject(at url: URL) {
        do {
            try ProjectManager.openProject(at: url)
            projectDetails = nil
            dismiss(response: .OK)
        }
        catch {
            projectDetails = Self.getProjectDetailsFromError(url: url, error: error)
            newProjectAlertShown = true
       }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("CiderKit Editor")
            
            Spacer()
            
            if projectManager.recentProjects.count > 0 {
                List {
                    ForEach(projectManager.recentProjects) { project in
                        Button(action: { openProject(at: project.url) }) {
                            VStack(alignment: .leading) {
                                Text(project.url.lastPathComponent)
                                    .bold()
                                Text(project.url.deletingLastPathComponent().path)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            else {
                Text("No recent project")
                    .italic()
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Button("New Project...") {
                    if let url = selectFolderPanel(canCreateDirectories: true) {
                        do {
                            try ProjectManager.createNewProject(at: url)
                            projectDetails = nil
                            dismiss(response: .OK)
                        }
                        catch {
                            projectDetails = Self.getProjectDetailsFromError(url: url, error: error)
                            newProjectAlertShown = true
                       }
                    }
                }
                .modifier(ProjectOperationModifier(isPresented: $newProjectAlertShown, projectDetails: projectDetails))
                
                Button("Open Other Project...") {
                    if let url = selectFolderPanel(canCreateDirectories: false) {
                        openProject(at: url)
                    }
                }
                .modifier(ProjectOperationModifier(isPresented: $openProjectAlertShown, projectDetails: projectDetails))
                
                Spacer()
                
                Button("Quit \(CiderKitApp.appName)") {
                    dismiss(response: .abort)
                }
            }
        }
        .padding()
    }
}
