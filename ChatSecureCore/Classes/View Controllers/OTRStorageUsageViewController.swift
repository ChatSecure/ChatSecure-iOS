//
// Created by Vyacheslav Karpukhin on 19.02.20.
// Copyright (c) 2020 Chris Ballinger. All rights reserved.
//

import Foundation
import OTRAssets
import MBProgressHUD

class OTRStorageUsageViewController : XLFormViewController {
    private let ROOT_SECTION_TAG = "rootSection"
    private let DELETE_ALL_TAG = "deleteAll"
    private let NO_MEDIA_FOUND_TAG = "noMediaFound"

    private let connections = OTRDatabaseManager.shared.connections

    init() {
        super.init(nibName: nil, bundle: nil)
        self.form = self.formDescriptor()
    }

    required public init!(coder aDecoder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }

    func formDescriptor() -> XLFormDescriptor {
        let form = XLFormDescriptor(title: STORAGE_USAGE_TITLE())

        let firstSection = XLFormSectionDescriptor()
        firstSection.multivaluedTag = ROOT_SECTION_TAG
        form.addFormSection(firstSection)

        let deleteAll = XLFormRowDescriptor(tag: DELETE_ALL_TAG, rowType: XLFormRowDescriptorTypeButton, title: STORAGE_USAGE_DELETE_ALL_BUTTON())
        deleteAll.action.formBlock = { row in
            self.deselectFormRow(row)
            self.deleteMedia()
        }
        firstSection.addFormRow(deleteAll)

        let noMediaFound = XLFormRowDescriptor(tag: NO_MEDIA_FOUND_TAG, rowType: XLFormRowDescriptorTypeText)
        noMediaFound.value = STORAGE_USAGE_NO_MEDIA_FOUND()
        noMediaFound.disabled = true
        firstSection.addFormRow(noMediaFound)

        return form
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.isEditing = false
        DispatchQueue.global().async {
            self.processAllMedia()
        }
    }

    private func processAllMedia() {
        var empty = true
        connections?.read.read { (transaction: YapDatabaseReadTransaction) in
            transaction.iterateKeysAndObjects(inCollection: OTRMediaItem.collection) { (key, mediaItem: OTRMediaItem, stop) in
                let parentMessage = mediaItem.parentMessage(with: transaction) as? OTRBaseMessage
                guard let threadOwner = parentMessage?.threadOwner(with: transaction),
                    let account = threadOwner.account(with: transaction),
                    let length = try? OTRMediaFileManager.shared.dataLength(for: mediaItem, buddyUniqueId: threadOwner.threadIdentifier) else {
                        return
                }
                empty = false

                let section = sectionForAccount(account)
                let row = rowForThreadOwner(threadOwner, section)
                let value = row.value as? Int ?? 0
                row.value = value + length.intValue
                
                DispatchQueue.main.async {
                    self.updateFormRow(row)
                }
            }
        }
        if let deleteAll = self.form.formRow(withTag: DELETE_ALL_TAG),
           let noMediaFound = self.form.formRow(withTag: NO_MEDIA_FOUND_TAG){
            DispatchQueue.main.async {
                deleteAll.hidden = empty
                noMediaFound.hidden = !empty
            }
        }
    }

    private func rowForThreadOwner(_ threadOwner: OTRThreadOwner, _ section: XLFormSectionDescriptor) -> XLFormRowDescriptor {
        var row = self.form.formRow(withTag: threadOwner.threadIdentifier)
        if row == nil {
            row = XLFormRowDescriptor(tag: threadOwner.threadIdentifier, rowType: XLFormRowDescriptorTypeInfo, title: threadOwner.threadName)
            row?.valueFormatter = ByteCountFormatter()
            DispatchQueue.main.sync {
                section.addFormRow(row!)
            }
        }
        return row!
    }

    private func sectionForAccount(_ account: OTRAccount) -> XLFormSectionDescriptor {
        var section = (self.form.formSections as! [XLFormSectionDescriptor]).first { $0.title == account.displayName }
        if section == nil {
            section = XLFormSectionDescriptor.formSection(withTitle: account.displayName, sectionOptions: .canDelete)
            DispatchQueue.main.sync {
                self.form.addFormSection(section!)
            }
        }
        return section!
    }

    override func formRowHasBeenRemoved(_ formRow: XLFormRowDescriptor!, at indexPath: IndexPath!) {
        super.formRowHasBeenRemoved(formRow, at: indexPath)
        deleteMedia(formRow.tag)
    }

    private func deleteMedia(_ threadIdentifier: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            MBProgressHUD.showAdded(to: strongSelf.view, animated: true)
        }
        connections?.write.asyncReadWrite { [weak self] (transaction: YapDatabaseReadWriteTransaction) in
            guard let strongSelf = self else { return }
            let mediaItemsToDelete = strongSelf.findItemsToDelete(transaction, threadIdentifier)
            strongSelf.doDelete(transaction, mediaItemsToDelete)
            DispatchQueue.global().async {
                strongSelf.vacuumAndUpdateUI(deleteAll: threadIdentifier == nil)
            }
        }
    }

    private func findItemsToDelete(_ transaction: YapDatabaseReadWriteTransaction, _ threadIdentifier: String?) -> [OTRMediaItem] {
        var mediaItemsToDelete: [OTRMediaItem] = []
        transaction.iterateKeysAndObjects(inCollection: OTRMediaItem.collection) { (key, mediaItem: OTRMediaItem, stop) in
            let parentMessage = mediaItem.parentMessage(with: transaction) as? OTRBaseMessage
            if threadIdentifier != nil,
                let threadOwner = parentMessage?.threadOwner(with: transaction),
                threadOwner.threadIdentifier != threadIdentifier {
                return
            }
            if (parentMessage?.mediaItemUniqueId != nil) {
                mediaItemsToDelete.append(mediaItem)
            }
        }
        return mediaItemsToDelete
    }

    private func doDelete(_ transaction: YapDatabaseReadWriteTransaction, _ mediaItemsToDelete: [OTRMediaItem]) {
        mediaItemsToDelete.forEach { mediaItem in
            if let parentMessage = mediaItem.parentMessage(with: transaction) as? OTRBaseMessage,
               let threadOwner = parentMessage.threadOwner(with: transaction) {

                mediaItem.remove(with: transaction)

                let media = OTRMediaItem.incomingItem(withFilename: mediaItem.filename, mimeType: nil)
                media.parentObjectKey = parentMessage.uniqueId
                media.parentObjectCollection = parentMessage.messageCollection
                media.save(with: transaction)

                parentMessage.mediaItemUniqueId = media.uniqueId
                parentMessage.messageError = FileTransferError.automaticDownloadsDisabled
                parentMessage.save(with: transaction)

                OTRMediaFileManager.shared.deleteData(for: mediaItem,
                        buddyUniqueId: threadOwner.threadIdentifier, completion: nil, completionQueue: nil)
            }
        }
    }

    private func vacuumAndUpdateUI(deleteAll: Bool) {
        OTRMediaFileManager.shared.vacuum { [weak self] in
            guard let strongSelf = self else { return }
            if deleteAll {
                strongSelf.form.formSections.forEach {
                    let element = $0 as! XLFormSectionDescriptor
                    if element.multivaluedTag != strongSelf.ROOT_SECTION_TAG {
                        strongSelf.form.removeFormSection(element)
                    }
                }
                if let deleteAll = strongSelf.form.formRow(withTag: strongSelf.DELETE_ALL_TAG),
                   let noMediaFound = strongSelf.form.formRow(withTag: strongSelf.NO_MEDIA_FOUND_TAG){
                    deleteAll.hidden = true
                    noMediaFound.hidden = false
                }
            }
            MBProgressHUD.hide(for: strongSelf.view, animated: true)
        }
    }
}
