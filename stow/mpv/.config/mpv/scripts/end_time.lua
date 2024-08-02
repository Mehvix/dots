mp.register_script_message('end-time', function()
    when = os.date('%I:%M:%S', os.time() + mp.get_property("time-remaining"))
    mp.osd_message(string.format("Movie ends at: %s", when), 3)
end)

