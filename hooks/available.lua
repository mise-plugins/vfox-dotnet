--- Returns all available .NET SDK versions from Microsoft's official API
--- @param ctx table Context provided by vfox
--- @return table Available versions
function PLUGIN:Available(ctx)
    local http = require("http")
    local json = require("json")

    local result = {}
    local seen = {}

    -- Fetch the releases index to get all channels
    local indexResp, indexErr = http.get({
        url = "https://builds.dotnet.microsoft.com/dotnet/release-metadata/releases-index.json",
    })

    if indexErr ~= nil then
        error("Failed to fetch releases index: " .. indexErr)
    end

    if indexResp.status_code ~= 200 then
        error("Failed to fetch releases index, status: " .. indexResp.status_code)
    end

    local indexData = json.decode(indexResp.body)
    if indexData == nil or indexData["releases-index"] == nil then
        error("Invalid releases index format")
    end

    -- Process each channel
    for _, channel in ipairs(indexData["releases-index"]) do
        local channelVersion = channel["channel-version"]
        local releaseType = channel["release-type"] or ""
        local supportPhase = channel["support-phase"] or ""
        local releasesUrl = channel["releases.json"]

        -- Determine the note for this channel
        local channelNote = ""
        if supportPhase == "eol" then
            channelNote = "EOL"
        elseif releaseType == "lts" then
            channelNote = "LTS"
        elseif releaseType == "sts" then
            channelNote = "STS"
        end

        -- Fetch releases for this channel
        if releasesUrl ~= nil and releasesUrl ~= "" then
            local relResp, relErr = http.get({
                url = releasesUrl,
            })

            if relErr == nil and relResp.status_code == 200 then
                local relData = json.decode(relResp.body)
                if relData ~= nil and relData["releases"] ~= nil and type(relData["releases"]) == "table" then
                    for _, release in ipairs(relData["releases"]) do
                        -- Get SDK version from the release
                        if release["sdk"] ~= nil and release["sdk"]["version"] ~= nil then
                            local version = release["sdk"]["version"]
                            if not seen[version] then
                                seen[version] = true
                                local note = channelNote
                                -- Mark previews and RCs
                                if string.match(version, "preview") or string.match(version, "rc") or string.match(version, "alpha") or string.match(version, "beta") then
                                    note = "Preview"
                                end
                                table.insert(result, {
                                    version = version,
                                    note = note,
                                })
                            end
                        end

                        -- Also check for additional SDKs array
                        if release["sdks"] ~= nil and type(release["sdks"]) == "table" then
                            for _, sdk in ipairs(release["sdks"]) do
                                if sdk["version"] ~= nil then
                                    local version = sdk["version"]
                                    if not seen[version] then
                                        seen[version] = true
                                        local note = channelNote
                                        if string.match(version, "preview") or string.match(version, "rc") or string.match(version, "alpha") or string.match(version, "beta") then
                                            note = "Preview"
                                        end
                                        table.insert(result, {
                                            version = version,
                                            note = note,
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Sort versions (oldest first) using semver comparison
    -- Versions are like "10.0.102", "9.0.309-preview.1", etc.
    table.sort(result, function(a, b)
        -- Split version into parts
        local function parseVersion(v)
            local parts = {}
            -- Split on dots and dashes
            for part in string.gmatch(v, "[^%.%-]+") do
                local num = tonumber(part)
                if num then
                    table.insert(parts, {type = "num", val = num})
                else
                    table.insert(parts, {type = "str", val = part})
                end
            end
            return parts
        end

        local partsA = parseVersion(a.version)
        local partsB = parseVersion(b.version)

        -- Compare part by part
        local maxLen = math.max(#partsA, #partsB)
        for i = 1, maxLen do
            local pa = partsA[i]
            local pb = partsB[i]

            if pa == nil then return true end  -- a is shorter, comes first
            if pb == nil then return false end -- b is shorter, comes first

            if pa.type == "num" and pb.type == "num" then
                if pa.val ~= pb.val then
                    return pa.val < pb.val
                end
            elseif pa.type == "str" and pb.type == "str" then
                if pa.val ~= pb.val then
                    return pa.val < pb.val
                end
            else
                -- Number comes before string (so "9.0.100" < "9.0.100-preview")
                return pa.type == "num"
            end
        end
        return false -- equal
    end)

    return result
end
