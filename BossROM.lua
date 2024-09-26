-- Mowzies Mobs Boss Summoner Script with User Authentication and Admin Mode

local bosses = {
    ["Frostmaw"] = "mowziesmobs:frostmaw",
    ["Barako, the Sun Chief"] = "mowziesmobs:barako",
    ["Ferrous Wroughtnaut"] = "mowziesmobs:ferrous_wroughtnaut",
    ["Naga"] = "mowziesmobs:naga"
}

local baseCost = 5 -- Initial cost in cogs
local cooldownTime = 3600 -- Cooldown time in seconds (1 hour)
local lockoutTime = 600 -- Lockout time in seconds (10 minutes)
local sessionTime = 300 -- Session time in seconds (5 minutes)

local chestLeft = peripheral.wrap("left") -- Wrap the chest peripheral on the left
local chestBack = peripheral.wrap("back") -- Wrap the chest peripheral behind
local cogsItem = "numismatics:cog" -- Item ID for the cogs
local lastSummonTime = {}
local summonCount = {}

local credentialsFile = "credentials.txt"

local function readCredentials()
    local file = fs.open(credentialsFile, "r")
    if not file then
        return { ["admin"] = {password = "adminpassword", isAdmin = true} }
    end
    local data = file.readAll()
    file.close()
    if data and data ~= "" then
        return textutils.unserialize(data) or { ["admin"] = {password = "adminpassword", isAdmin = true} }
    else
        return { ["admin"] = {password = "adminpassword", isAdmin = true} }
    end
end

local function writeCredentials(credentials)
    local file = fs.open(credentialsFile, "w")
    file.write(textutils.serialize(credentials))
    file.close()
end

local credentials = readCredentials()

local lockoutStartTime = nil
local failedAttempts = 0

local function checkCogs(cost, isAdmin)
    if isAdmin then
        return true
    end
    
    local items = chestLeft.list()
    local count = 0
    for slot, item in pairs(items) do
        if item.name == cogsItem then
            count = count + item.count
        end
    end

    if count >= cost then
        return true
    else
        print("You do not have enough funds.")
        local diff = cost - count
        print("You require " .. diff .. " more cogs.")
        os.sleep(2)
        return false
    end
end

local function removeCogs(cost, isAdmin)
    if isAdmin then
        return
    end
    
    local items = chestLeft.list()
    local remaining = cost
    for slot, item in pairs(items) do
        if item.name == cogsItem then
            local toRemove = math.min(item.count, remaining)
            chestLeft.pushItems(peripheral.getName(chestBack), slot, toRemove)
            remaining = remaining - toRemove
            if remaining <= 0 then break end
        end
    end
end

local function summonBoss(bossID, x, y, z)
    local command = string.format("summon %s %d %d %d", bossID, x, y, z)
    commands.exec(command)
end

local function summon(player, bossName, x, y, z, isAdmin)
    local bossID = bosses[bossName]
    local currentTime = os.time()
    local cost = baseCost

    if lastSummonTime[player] then
        local timeElapsed = currentTime - lastSummonTime[player]
        if timeElapsed < cooldownTime then
            cost = baseCost * (2 ^ summonCount[player]) -- Exponentially increasing cost
        else
            summonCount[player] = 0
        end
    else
        summonCount[player] = 0
    end

    if checkCogs(cost, isAdmin) then
        removeCogs(cost, isAdmin)
        summonBoss(bossID, x, y, z)
        lastSummonTime[player] = currentTime
        summonCount[player] = summonCount[player] + 1
        print("Summoned " .. bossName .. " at (169, -60, 60)")
        os.sleep(2)
    end
end

local function displayMenu()
    term.clear()
    term.setCursorPos(1, 1)
    print("Select a boss to summon:")
    local bossNames = {}
    for bossName in pairs(bosses) do
        table.insert(bossNames, bossName)
    end
    for i, bossName in ipairs(bossNames) do
        print(i .. ". " .. bossName)
    end
    print("\nEnter the number of the boss you want to summon:")
    local choice = tonumber(read())
    if choice and choice >= 1 and choice <= #bossNames then
        return bossNames[choice]
    else
        print("Invalid choice. Please try again.")
        os.sleep(2)
        return displayMenu()
    end
end

local function createAccount()
    term.clear()
    term.setCursorPos(1, 1)
    print("Create a new user account")
    print("Enter username:")
    local username = read()
    if credentials[username] then
        print("Username already exists. Please choose a different username.")
        os.sleep(2)
        return
    end
    print("Enter password:")
    local password = read("*")
    print("Confirm password:")
    local passwordConfirm = read("*")
    if password == passwordConfirm then
        credentials[username] = {password = password, isAdmin = false}
        writeCredentials(credentials)
        print("Account created successfully.")
        os.sleep(2)
    else
        print("Passwords do not match. Account creation failed.")
        os.sleep(2)
    end
end

local function login()
    for attempt = 1, 6 do
        term.clear()
        term.setCursorPos(1, 1)
        print("Login to continue")
        print("Enter username:")
        local username = read()
        print("Enter password:")
        local password = read("*")
        
        if credentials[username] and credentials[username].password == password then
            return username, credentials[username].isAdmin
        else
            print("Invalid username or password. Please try again.")
            os.sleep(2)
        end
    end

    lockoutStartTime = os.time()
    print("Too many failed attempts. Terminal locked for 10 minutes.")
    os.sleep(2)
    return nil, nil
end

local function terminateProgram()
    print("Enter admin password to terminate the program:")
    local password = read("*")
    if credentials["admin"].password == password then
        error("Program terminated by admin.")
    else
        print("Invalid password loser. Returning to main menu.")
        os.sleep(2)
    end
end

local function main()
    -- Coordinates where the bosses will be summoned
    local x, y, z = 169, -60, 60

    while true do
        if lockoutStartTime then
            if os.time() - lockoutStartTime < lockoutTime then
                print("Terminal is locked. Please wait.")
                os.sleep(10)
                -- Continue waiting until the lockout time has passed
            else
                lockoutStartTime = nil
            end
        else
            local username, isAdmin = login()
            if username then
                print("Welcome, " .. username .. "!")
                local sessionStartTime = os.time()
                while os.time() - sessionStartTime < sessionTime do
                    if isAdmin then
                        print("Admin mode enabled.")
                        print("Type 'account' to create a new user account, 'logout' to log out, or Enter to continue.")
                        local response = read()
                        if response == "account" then
                            createAccount()
                        elseif response == "logout" then
                            break
                        end
                    end
                    local bossName = displayMenu()
                    if bossName then
                        summon(username, bossName, x, y, z, isAdmin)
                    end
                    print("Type 'logout' to log out or press Enter to continue.")
                    local input = read()
                    if input == "logout" then
                        break
                    elseif input == "terminate" and isAdmin then
                        terminateProgram()
                    end
                end
            end
        end
        os.sleep(2) -- Wait before allowing another summon attempt
    end
end

main()
