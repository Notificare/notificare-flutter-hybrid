//
//  NotificationService.swift
//  notification
//
//  Created by Helder Pinhal on 28/04/2020.
//  Copyright © 2020 Notificare. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent
        
        NotificarePushLib.shared().fetchAttachment(request.content.userInfo, completionHandler: {(_ response: Any?, _ error: Error?) -> Void in
            if let bestAttemptContent = self.bestAttemptContent,
                let contentHandler = self.contentHandler {
                
                if (error == nil) {
                    if let attachments = response as? [UNNotificationAttachment] {
                        bestAttemptContent.attachments = attachments
                    }
                }
                
                contentHandler(bestAttemptContent)
            }
        })
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
