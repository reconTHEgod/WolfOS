-- WolfOS User Server Module

WDM = os.getApiSided "WDM"
WNC = os.getApiSided "WNC"
WAU = os.getApiSided "WAU"

pcall ->
    modemPort = WDM.readServerData "modem_port"
    channel = WDM.readTempData("server_modules").user.channel
    if not channel
        error!
    
    relay = WDM.readTempData "parent_address"
    thisAddress = os.getComputerID!..":"..channel
    
    while true
        data = WNC.listen(modemPort, channel) or {}
        
        switch data[1]
            when "login_attempt"
                ok, user = WAU.checkLogin data[2], data[3]
                if ok
                    WNC.send modemPort, relay, thisAddress, data.sourceAddress, {"login_success", user}
                else
                    WNC.send modemPort, relay, thisAddress, data.sourceAddress, {"login_failure", "invalid_user"}
            when "data_request"
                switch data[2]
                    when "user_list"
                        WNC.send modemPort, relay, thisAddress, data.sourceAddress, {"request_success", WDM.readData os.getSystemDir("data").."users.dat"}
                    when "user_data"
                        user, n = WAU.exists data[3]
                        if user
                            WNC.send modemPort, relay, thisAddress, data.sourceAddress, {"request_success", user, n}
                        else
                            WNC.send modemPort, relay, thisAddress, data.sourceAddress, {"request_failure", "invalid_user"}
            when "data_update"
                switch data[2]
                    when "new_user"
                        WAU.createUser data[3], data[4], data[5]
                    when "remove_user"
                        WAU.removeUser data[3]
                    when "update_user"
                        WAU.changeUserData data[3], data[4], data[5]
