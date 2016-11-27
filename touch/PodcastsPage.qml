
/**
 *
 * gPodder QML UI Reference Implementation
 * Copyright (c) 2013, Thomas Perl <m@thp.io>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 *
 */

import QtQuick 2.0

import 'common'
import 'common/util.js' as Util
import 'icons/icons.js' as Icons
import 'common/constants.js' as Constants

SlidePage {
    id: page

    canClose: false

    hasMenuButton: true
    menuButtonLabel: 'Settings'
    onMenuButtonClicked: {
        pgst.showSelection([
            {
                label: 'Check for new episodes',
                callback: function () {
                    py.call('main.check_for_episodes');
                }
            },
            {
                label: 'Filter episodes',
                callback: function () {
                    pgst.loadPage('EpisodeQueryPage.qml');
                }
            },
            {
                label: 'Settings',
                callback: function () {
                    pgst.loadPage('SettingsPage.qml');
                },
            },
            {
                label: 'Add new podcast',
                callback: function () {
                    var ctx = { py: py };
                    pgst.loadPage('TextInputDialog.qml', {
                        buttonText: 'Subscribe',
                        placeholderText: 'Feed URL',
                        pasteOnLoad: true,
                        callback: function (url) {
                            ctx.py.call('main.subscribe', [url]);
                        }
                    });
                },
            },
            {
                label: 'Discover new podcasts',
                callback: function () {
                    py.call('main.get_directory_providers', [], function (result) {
                        var items = [];
                        for (var i=0; i<result.length; i++) {
                            (function (provider) {
                                items.push({
                                    label: provider.label,
                                    callback: function () {
                                        pgst.loadPage('Directory.qml', {
                                            provider: provider.label,
                                            can_search: provider.can_search,
                                        });
                                    },
                                });
                            })(result[i]);
                        }
                        pgst.showSelection(items, 'Select provider');
                    });
                },
            },
            {
                label: 'Import OPML File',
                callback: function () {
                    var devel = false
                    if(devel) {
                        openFileNameReady("/mnt/sdcard/all-subscriptions.opml");
                    } else if (platform.android) {

                        var afd = Qt.createQmlObject('import org.thp.gpodder.android 1.0; AndroidFileDialog { }',
                                      pgst,
                                      "afd");
                        if(afd == null){
                            console.log("ERROR CREATING AFD");
                            return;
                        }
                        afd.existingFileNameReady.connect(openFileNameReady);
                        var success = afd.provideExistingFileName();
                        if (!success) {
                            console.log("Problem with JNI or sth like that...");
                        }

                    } else {
                        pgst.loadPage('FileDialog.qml', { caller: page });
                    }
                },
            },
        ], undefined, undefined, true);
    }

    PListView {
        id: podcastList
        title: 'Subscriptions'

        section.property: 'section'
        section.delegate: SectionHeader { text: section }

        PPlaceholder {
            text: 'No podcasts'
            visible: podcastList.count === 0
        }

        model: podcastListModel

        delegate: PodcastItem {
            onClicked: pgst.loadPage('EpisodesPage.qml', {'podcast_id': id, 'title': title});
            onPressAndHold: {
                pgst.showSelection([
                    {
                        label: 'Refresh',
                        callback: function () {
                            py.call('main.check_for_episodes', [url]);
                        },
                    },
                    {
                        label: 'Unsubscribe',
                        callback: function () {
                            var ctx = { py: py, id: id };
                            pgst.showConfirmation(title, 'Unsubscribe', 'Cancel', 'Remove this podcast and all downloaded episodes?', Icons.trash, function () {
                                ctx.py.call('main.unsubscribe', [ctx.id]);
                            });
                        },
                    },
                    {
                        label: 'Rename',
                        callback: function () {
                            var ctx = { py: py, id: id };
                            pgst.loadPage('TextInputDialog.qml', {
                                buttonText: 'Rename',
                                placeholderText: 'New name',
                                text: title,
                                callback: function (new_title) {
                                    ctx.py.call('main.rename_podcast', [ctx.id, new_title]);
                                }
                            });
                        }
                    },
                    {
                        label: 'Mark episodes as old',
                        callback: function () {
                            py.call('main.mark_episodes_as_old', [id]);
                        },
                    },
                    {
                        label: 'Podcast details',
                        callback: function () {
                            pgst.loadPage('PodcastDetail.qml', {podcast_id: id, title: title});
                        }
                    },
                ], title);
            }
        }
    }

    function openFileNameReady(path) {
        console.log("openFileNameReady(", path, ")")
        if(path) {
            py.call('main.load_opml_file', [path], function (result) {
                var items = [];
                for (var i=0; i<result.length; i++) {
                    (function (podcast) {
                        items.push({
                            title: podcast.title,
                            url: podcast.url,
                            section: podcast.section,
                            selected: true,
                            enabled: podcast.section == 'new'
                        });
                    })(result[i]);
                }
                pgst.loadPage("PodcastsImportPage.qml", {podcasts: items})
            });
        }
    }

}
