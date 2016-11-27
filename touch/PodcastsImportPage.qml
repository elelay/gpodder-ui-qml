import QtQuick 2.0
import QtQuick.Controls 1.2

import 'common'
import 'common/util.js' as Util
import 'icons/icons.js' as Icons
import 'common/constants.js' as Constants


SlidePage {

   id: page

   canClose: true

   hasMenuButton: true
   menuButtonLabel: 'Actions'

   property var podcasts: [{}]

    onMenuButtonClicked: {
        pgst.showSelection([
            {
                label: 'Select All',
                callback: function () {
                    for (var i=0; i < importModel.count; i++) {
                        var podcast = importModel.get(i)
                        if(podcast.enabled) {
                            importModel.setProperty(i, "selected", true);
                        }
                    }
                }
            },
            {
                label: 'Select None',
                callback: function () {
                    for (var i=0; i < importModel.count; i++) {
                        var podcast = importModel.get(i)
                        if(podcast.enabled) {
                            importModel.setProperty(i, "selected", false);
                        }
                    }
                }
            },
            {
                label: 'Import Selected',
                callback: function () {
                    var urls = [];
                    for (var i=0; i < importModel.count; i++) {
                        var podcast = importModel.get(i)
                        if(podcast.enabled && podcast.selected) {
                            urls.push(podcast.url)
                        }
                    }
                    console.log("subscribing to", urls);
                    py.call('main.subscribe_all', [urls], function () {
                            page.closePage();
                    });
                }
            },
        ], undefined, undefined, true);
    }


   PListView {
       id: podcastsImportList
       title: 'OPML Import'

       section.property: 'section'
       section.delegate: SectionHeader { text: section }

       PPlaceholder {
           text: 'No podcast found'
           visible: podcastsImportList.count === 0
       }

       model: ListModel {
               id: importModel
            Component.onCompleted: {
                page.podcasts.forEach(function(p){
                        append(p);
                });
            }
        }

       delegate: Item {

              height: 2 * Constants.layout.item.height * pgst.scalef

              anchors {
                     left: parent.left
                     right: parent.right
              }

              Row {
                     id: tt

               anchors {
                   left: parent.left
                   right: parent.right
                   leftMargin: Constants.layout.padding * pgst.scalef
                   rightMargin: Constants.layout.padding * pgst.scalef
               }

               // CheckBox doesn't preserve bidirectional bindings (in 5.3 anyway)
               // I gave up after many variations and use IconMenuItem,
               // which works fine
               IconMenuItem {
                id: check

                height: 50 * pgst.scalef
                icon: selected ? Icons.check : Icons.cross
                color: Constants.colors.secondaryHighlight

                enabled: model.enabled
                onClicked: {
                    importModel.setProperty(index, "selected", !selected)
                }
               }

               PLabel {
                   id: titleLabel
                   elide: Text.ElideRight
                   text: title
                   font.bold:true
                   width: parent.width - check.width
                   color: section == 'new' ? Constants.colors.text : Constants.colors.toolbarDisabled
               }

               width: parent.width
           }

              PLabel {
                     id: urlLabel
                     anchors {
                            top: tt.bottom
                            left: parent.left
                            leftMargin: Constants.layout.padding * pgst.scalef
                            rightMargin: Constants.layout.padding * pgst.scalef
                            right: parent.right
                     }
                     width:parent.width
               wrapMode: Text.WrapAnywhere
                     text: url
              }
       }
   }
}
