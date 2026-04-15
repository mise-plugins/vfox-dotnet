--- Installs .NET SDK using Microsoft's official installer script
--- @param ctx table Context provided by vfox
function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo["dotnet"]
    local path = sdkInfo.path
    local version = sdkInfo.version
    local sep = RUNTIME.osType == "windows" and "\\" or "/"

    if RUNTIME.osType == "windows" then
        local function quote_for_windows_shell(value)
            return '"' .. value:gsub('"', '""') .. '"'
        end

        local scriptPath = path .. sep .. "dotnet-install.ps1"
        local command = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "
            .. quote_for_windows_shell(scriptPath)
            .. " -InstallDir "
            .. quote_for_windows_shell(path)
            .. " -Version "
            .. quote_for_windows_shell(version)
            .. " -NoPath"

        local executeResult = os.execute(command)
        if executeResult == nil or executeResult == false then
            error("Failed to execute dotnet-install.ps1 on Windows")
        end

        os.remove(scriptPath)
    else
        local cmd = require("cmd")
        local scriptPath = path .. sep .. "dotnet-install.sh"
        cmd.exec("chmod +x '" .. scriptPath .. "'")
        cmd.exec("'" .. scriptPath .. "' --install-dir '" .. path .. "' --version '" .. version .. "' --no-path")
        os.remove(scriptPath)
    end

    local dotnetBin
    if RUNTIME.osType == "windows" then
        dotnetBin = path .. sep .. "dotnet.exe"
    else
        dotnetBin = path .. sep .. "dotnet"
    end

    local f = io.open(dotnetBin, "r")
    if f == nil then
        error("Installation failed: dotnet binary not found at " .. dotnetBin)
    end
    f:close()
end
