
Credentials = readCredentials()

local function getTime(timeCategory)
    local currTime = os.date("*t")


end

local function login()
    for attempt = 1, 6 do
        term.clear()
        term.setCursorPos(1,1)

        print("Login to continue")
        print("Enter username:")
        local username = read()

        print("Enter password")
        local password = read("*")

        if Credentials[username].password == password then
            if Credentials[username].isAdmin == 1 then
                return username, 1
            else
                return username, Credentials[username].isAdmin
            end
        else
            print("Invalid username or password. Please try again.")
            os.sleep(3)
        end

    end

    print("Too many failed attempts. Enacting punishment.")
    local command = string.format("damage @p magic 10")
end

local function main()
    while true do
        
        
    end
end

main()