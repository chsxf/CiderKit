import AppKit
import SpriteKit
import CiderKit_Engine

class SpriteAssetEditorView: NSView, NSComboBoxDelegate {
    
    private var selectedDatabaseId: String
    private var selectedAssetUUID: String?

    private let comboboxDataSource: NSComboBoxDataSource
    private var databaseView: SpriteAssetDatabaseView!
    
    private var selectedDatabase: SpriteAssetDatabase { Project.current!.spriteAssetDatabase(forId: selectedDatabaseId)! }
    
    override init(frame: NSRect) {
        let defaultDB = Project.current!.defaultSpriteAssetDatabase!
        selectedDatabaseId = defaultDB.id
        
        comboboxDataSource = SpriteAssetDatabaseDataSource()
        
        super.init(frame: frame)
        
        selectedAssetUUID = nil
        
        prepareSubViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    fileprivate func dismiss() {
        if saveDatabases() {
            CiderKitApp.mainWindow.endSheet(self.window!, returnCode: .OK)
        }
    }
    
    private func prepareSubViews() {
        databaseView = SpriteAssetDatabaseView(database: selectedDatabase)

        let mainStack = NSStackView(views: [buildTopStack(), databaseView])
        mainStack.orientation = .vertical
        mainStack.alignment = .left
        addSubview(mainStack)
        
        addConstraints([
            NSLayoutConstraint(item: mainStack, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15),
            NSLayoutConstraint(item: mainStack, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -15),
            NSLayoutConstraint(item: mainStack, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 15),
            NSLayoutConstraint(item: mainStack, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -15),
            
            NSLayoutConstraint(item: databaseView!, attribute: .right, relatedBy: .equal, toItem: mainStack, attribute: .right, multiplier: 1, constant: 0)
        ])
    }
    
    private func buildTopStack() -> NSStackView {
        let label = NSTextField(labelWithString: "Selected Asset Database")
        
        let combobox = NSComboBox()
        combobox.usesDataSource = true
        combobox.dataSource = comboboxDataSource
        combobox.stringValue = selectedDatabaseId
        combobox.delegate = self
        
        let button = NSButton(title: "Close", target: self, action: #selector(SpriteAssetEditorView.dismiss))
        
        let topStack = NSStackView(views: [
            label, combobox, button
        ])
        topStack.orientation = .horizontal
        return topStack
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let combobox = notification.object as! NSComboBox
        selectedDatabaseId = comboboxDataSource.comboBox!(combobox, objectValueForItemAt: combobox.indexOfSelectedItem) as! String
        databaseView.database = selectedDatabase
    }
    
    fileprivate func saveDatabases() -> Bool {
        let databases = Project.current!.spriteAssetDatabases.values
        var currentIndex = databases.startIndex
        while currentIndex != databases.endIndex {
            let database = databases[currentIndex]
            if let sourceURL = database.sourceURL {
                do {
                    try EditorFunctions.save(database, to: sourceURL, prettyPrint: true)
                    currentIndex = databases.index(after: currentIndex)
                }
                catch {
                    let alert = NSAlert()
                    alert.messageText = "An error has occured while saving this sprite asset database:\n\n\(error)"
                    alert.informativeText = "Error"
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "Retry")
                    alert.addButton(withTitle: "Skip")
                    alert.addButton(withTitle: "Cancel")
                    switch alert.runModal() {
                    case.alertFirstButtonReturn:
                        continue
                    case .alertSecondButtonReturn:
                        currentIndex = databases.index(after: currentIndex)
                    default:
                        return false
                    }
                }
            }
        }
        return true
    }
    
}
