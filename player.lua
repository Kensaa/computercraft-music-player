local server = "http://kensa.fr:9515/"

local dfpwm = require "cc.audio.dfpwm"
local speaker = peripheral.find("speaker")

function downloadFile(url,path)
    local ok, err = http.checkURL(url)
    if not ok then
        return
    end

    local response = http.get(url , nil , true)
    if not response then
        print("an error occured")
        return
    end
    
    local res = response.readAll()
    response.close()
    local file, err = fs.open(path, "wb")
    if not file then
        print("an error occured")
        return
    end

    file.write(res)
    file.close()
end

function play(src)
    local decoder = dfpwm.make_decoder()
    for input in io.lines(src, 1024) do
        local decoded = decoder(input)
        while not speaker.playAudio(decoded,10000) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

function timeConvert(input)
    local seconds = input % 60
    local minutes = (input - seconds) / 60
    if seconds < 10 then
        seconds = "0" .. seconds
    end
    if minutes < 10 then
        minutes = "0" .. minutes
    end
    return minutes..":"..seconds
end

while true do
    term.clear()
    term.setCursorPos(1,1)
    print("Kensa's Music Player")
    print(" 1. Play Song")
    print(" 2. Convert new song")
    print(" 3. Exit")
    local choise = read()
    if choise == "1" then
        local songs = textutils.unserialiseJSON(http.get(server.."tracks/").readAll())
        print("List of songs: ")
        if #songs == 0 then
            print("No songs available.")
        else
            for i,song in ipairs(songs) do
                if fs.exists("sounds/"..song..".dfpwm") then
                    print(i..". "..song.." (local)")
                else
                    print(i..". "..song)
                end
                if i % 10 == 0 then 
                    print("Press ENTER to continue...")
                    read()
                    term.clear()
                    term.setCursorPos(1,1)
                end
            end
        
            print("Select the song: ")
            local songIndex = read()
            if tonumber(songIndex) > #songs or songIndex == "" then
                print("Invalid song index")
            else
                local song = songs[tonumber(songIndex)]
                
                --check if song is not downloaded
                if not fs.exists("sounds/"..song..".dfpwm") then
                    print("Song not found, downloading...")
                    --shell.run("wget",server.."tracks/"..song..".dfpwm","sounds/"..song..".dfpwm")
                    downloadFile(server.."tracks/"..song..".dfpwm","sounds/"..song..".dfpwm")
                    print("Song downloaded !")
                end
                print("Starting playing song...")
                parallel.waitForAny(
                    function()
                        play("sounds/"..song..".dfpwm")
                    end,
                    function()
                        duration = 0
                        local songDuration = tonumber(http.get(server.."duration/"..song).readAll())
                        x,y = term.getSize()
                        term.setCursorPos(1,y)
                        while true do
                            duration = duration + 1
                            sleep(1)
                            term.clearLine()
                            term.setCursorPos(1,y)
                            term.write(timeConvert(duration).." - "..timeConvert(songDuration))
                        end
                        
                    end
                )
               
                print("Song finished !")
                print("Press ENTER to continue...")
                read()
            end
        end
    elseif choise == "2" then
        print("Convert new song: ")
        print("Enter the name of the song: ")
        local name = read()
        print("Enter the youtube url of the song: ")
        local url = read()
        print("Converting song...")
        local postData = {}
        postData["url"] = url
        postData["name"] = name
        http.post(server.."download", textutils.serialiseJSON(postData), {["Content-Type"] = "application/json"})
        print("Song converted !")

        print("Press ENTER to continue...")
        read()
    elseif choise == "3" then
        print("Exiting...")
        break
    else
        print("Invalid choise")
    end
end