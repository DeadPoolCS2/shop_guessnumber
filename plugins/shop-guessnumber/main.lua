function GetPluginAuthor()
    return "Karp & rocobalt"
end

function GetPluginVersion()
    return "v1.1.0"
end

function GetPluginName()
    return "Guess the Number"
end

function GetPluginWebsite()
    return ""
end

local targetNumber = 0
local creditReward = 0
local playerTries = {}
local gameEnded = true
local messageSent = {}

-- Preluăm șansa de start a jocului din config sau folosim 25% ca valoare implicită
local chanceToStartGame = config:Fetch("guessnumber.chance_to_start", 25)

local function generateRandomNumber()
    -- Obținem valorile min/max din config, dacă nu există, folosim valori implicite
    local minNumber = config:Fetch("guessnumber.min_number", 1)
    local maxNumber = config:Fetch("guessnumber.max_number", 15)
    local minCredits = config:Fetch("guessnumber.min_credits", 100)
    local maxCredits = config:Fetch("guessnumber.max_credits", 300)

    -- Generăm numerele aleatorii pe baza acestor valori
    targetNumber = math.random(minNumber, maxNumber)
    creditReward = math.random(minCredits, maxCredits)
end

local function handleGuess(playerid, message)
    local guessedNumber = tonumber(message)
    if guessedNumber then
        if guessedNumber == targetNumber then
            local playerName = GetPlayer(playerid)
            playermanager:SendMsg(MessageType.Chat, config:Fetch("prefix"), FetchTranslation("win")
                :gsub("{player}", playerName:CBasePlayerController().PlayerName)
                :gsub("{number}", targetNumber)
                :gsub("{credits}", creditReward))
            
            exports["shop-core"]:GiveCredits(playerid, creditReward)
            gameEnded = true
            playerTries[playerid] = nil
        else
            if playerTries[playerid] and playerTries[playerid] < 3 then
                playerTries[playerid] = playerTries[playerid] + 1
                local remainingTries = 3 - playerTries[playerid]
                if remainingTries > 0 then
                    ReplyToCommand(playerid, config:Fetch("prefix"), FetchTranslation("wrong_guess")
                        :gsub("{tries}", remainingTries))
                else
                    ReplyToCommand(playerid, config:Fetch("prefix"), FetchTranslation("lose"))
                end
            end
        end
    end
end

AddEventHandler("OnRoundStart", function()
    local randomChance = math.random(0, 100)
    if randomChance <= chanceToStartGame then
        if gameEnded then
            generateRandomNumber()
            playermanager:SendMsg(MessageType.Chat, config:Fetch("prefix"), FetchTranslation("start")
                :gsub("{min}", config:Fetch("guessnumber.min_number", 1))
                :gsub("{max}", config:Fetch("guessnumber.max_number", 15))
                :gsub("{credits}", creditReward))
            
            for playerid, _ in pairs(playerTries) do
                playerTries[playerid] = 0
            end
            for playerid, _ in pairs(messageSent) do
                messageSent[playerid] = nil
            end
            gameEnded = false
        end
    end
end)

AddEventHandler("OnRoundEnd", function()
    if not gameEnded then
        gameEnded = true
        playermanager:SendMsg(MessageType.Chat, config:Fetch("prefix"), FetchTranslation("round_end")
            :gsub("{number}", targetNumber))
    end
end)

AddEventHandler("OnClientChat", function(event, playerid, text)
    local guessedNumber = tonumber(text)
    if guessedNumber and guessedNumber >= config:Fetch("guessnumber.min_number", 1) and guessedNumber <= config:Fetch("guessnumber.max_number", 15) then
        if not playerTries[playerid] then
            playerTries[playerid] = 0
        end
        if gameEnded then
            return ""
        end
        if playerTries[playerid] < 3 then
            handleGuess(playerid, text)
        end
        return ""
    end
end)
