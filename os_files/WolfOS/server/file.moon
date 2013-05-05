-- WolfOS User Server Module

WDM = os.getApiSided "WDM"
WNC = os.getApiSided "WNC"
WFH = os.getApiSided "WFH"

pcall ->
    modemPort = WDM.readServerData "modem_port"
    channel = WDM.readTempData("server_modules").file.channel
    if not channel
        error!
    
    relay = WDM.readTempData "parent_address"
    thisAddress = os.getComputerID!..":"..channel
    
    while true
        data = WNC.listen(modemPort, channel) or {}
        
        switch data[1]
            when "is_dir"
                WNC.send modemPort, relay, thisAddress, data.sourceAddress, {"is_dir_response", WFH.isDir data[2]}
            when "list_contents"
                WNC.send modemPort, relay, thisAddress, data.sourceAddress, {"list_contents_response", WFH.list data[2], data[3]}
            when "move_item"
                WFH.move data[2], data[3]
            when "copy_item"
                WFH.copy data[2], data[3]
            when "delete_item"
                WFH.delete data[2]
