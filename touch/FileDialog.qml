import QtQuick 2.0
import QtQuick.Dialogs 1.0

FileDialog {
   id: fileDialog
   title: "Please choose a file"
   folder: "file:///"
   nameFilters: [ "OPML Subscriptions (*.opml)" ]
   property var caller: null
   onAccepted: {
       console.log("You chose: " + fileDialog.fileUrls)
       caller.openFileNameReady(""+fileDialog.fileUrls)
   }
   onRejected: {
       console.log("Canceled")
   }
   Component.onCompleted: {
      pgst.loadPageInProgress = false;
      visible = true;
   }
}
