local function showChapterTitle()
    local chapterTitle = mp.get_property_osd("chapter-metadata/by-key/title")
    mp.osd_message(chapterTitle, 5)
end

local function startObserving()
    mp.observe_property("chapter", nil, showChapterTitle)
end

mp.observe_property("chapter", nil, showChapterTitle)
--mp.add_key_binding("Ctrl+p", "showChapter", startObserving)
