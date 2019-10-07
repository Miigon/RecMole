local dataprovider

local data = {


}

function dataprovider.getData(userid,key)
    return data[userid][key]
end


return dataprovider