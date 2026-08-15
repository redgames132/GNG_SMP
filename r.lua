-- ==========================================
-- Radar HUD V3 - Com Alarme e Modo Tabela
-- ==========================================

local detector = peripheral.wrap("top")
local monitor = peripheral.wrap("left")

if not detector or not monitor then
    print("Erro: Verifique se o detetor esta no topo e o monitor a esquerda!")
    return
end

-- ==========================================
-- CONFIGURACOES
-- ==========================================
local radarX = -8500
local radarZ = -397

-- Lista de amigos (Nao ativam o alarme)
local whitelist = {
    ["cadipadi"] = true,
    ["redgames132"] = true,
    ["goonerstickle69"] = true
}

local aspect = 0.65
monitor.setTextScale(0.5)

local ranges = {50, 100, 200, 500, 1000, 2000, "Inf"}
local currentRangeIdx = 3 

local speeds = {0.5, 1, 2, 5, 10}
local currentSpeedIdx = 2 

-- Paleta de Cores UI
local cBg = colors.black
local cPanel = colors.gray
local cRadar = colors.green
local cDot = colors.lime
local cText = colors.white
local cBtnBg = colors.cyan
local cBtnFg = colors.black
local cAlarmBg = colors.red
local cAlarmFg = colors.white

local w, h = monitor.getSize()
local panelWidth = 25
local radarSize = math.min(w - panelWidth, h) 
local centerX = w - math.floor(radarSize / 2)
local centerY = math.floor(h / 2)
local maxRadiusX = math.floor(radarSize / 2) - 2

local buttons = {}
local alarmBlink = false

local function clear()
    monitor.setBackgroundColor(cBg)
    monitor.clear()
    buttons = {}
end

local function drawButton(id, x, y, text, bg, fg)
    monitor.setCursorPos(x, y)
    monitor.setBackgroundColor(bg)
    monitor.setTextColor(fg)
    monitor.write(text)
    table.insert(buttons, {id=id, x=x, y=y, len=string.len(text)})
end

local function drawCircle(cx, cy, radiusX, color)
    monitor.setTextColor(color)
    monitor.setBackgroundColor(cBg)
    for angle = 0, 360, 2 do
        local rad = math.rad(angle)
        local x = math.floor(math.cos(rad) * radiusX + 0.5)
        local y = math.floor(math.sin(rad) * radiusX * aspect + 0.5)
        monitor.setCursorPos(cx + x, cy + y)
        monitor.write(".")
    end
end

local function getTargetPlayers()
    local players = {}
    local maxDist = ranges[currentRangeIdx]
    local list = (maxDist == "Inf") and detector.getOnlinePlayers() or detector.getPlayersInRange(maxDist)

    for _, name in ipairs(list) do
        local pos = detector.getPlayerPos(name)
        if pos then
            table.insert(players, {name = name, x = math.floor(pos.x), y = math.floor(pos.y), z = math.floor(pos.z)})
        end
    end
    return players
end

local function drawUI()
    clear()
    local isInf = (ranges[currentRangeIdx] == "Inf")
    local players = getTargetPlayers()
    
    -- Verifica Alarme (Qualquer pessoa a < 1000 blocos que nao esteja na whitelist)
    local alarmActive = false
    for _, p in ipairs(players) do
        if not whitelist[p.name] then
            local dist = math.sqrt((p.x - radarX)^2 + (p.z - radarZ)^2)
            if dist <= 1000 then
                alarmActive = true
                break
            end
        end
    end

    -- Desenha a divisao do painel (se nao for infinito)
    if not isInf then
        monitor.setBackgroundColor(cPanel)
        for y = 1, h do
            monitor.setCursorPos(panelWidth, y)
            monitor.write(" ")
        end
        monitor.setBackgroundColor(cBg)
    end

    -- Controlos: Raio
    monitor.setTextColor(cText)
    monitor.setCursorPos(2, 2) monitor.write("ALCANCE:")
    drawButton("range_down", 2, 3, " - ", cBtnBg, cBtnFg)
    
    local rangeText = tostring(ranges[currentRangeIdx])
    monitor.setCursorPos(6, 3)
    monitor.setBackgroundColor(cBg)
    monitor.setTextColor(cText)
    monitor.write(" " .. rangeText .. string.rep(" ", 5 - string.len(rangeText)))
    
    drawButton("range_up", 12, 3, " + ", cBtnBg, cBtnFg)

    -- Controlos: Velocidade
    monitor.setTextColor(cText)
    monitor.setCursorPos(2, 5) monitor.write("ATUALIZA (s):")
    drawButton("speed_down", 2, 6, " - ", cBtnBg, cBtnFg)
    
    local speedText = tostring(speeds[currentSpeedIdx])
    monitor.setCursorPos(6, 6)
    monitor.setBackgroundColor(cBg)
    monitor.setTextColor(cText)
    monitor.write(" " .. speedText .. string.rep(" ", 5 - string.len(speedText)))
    
    drawButton("speed_up", 12, 6, " + ", cBtnBg, cBtnFg)

    -- Alarme Banner
    if alarmActive then
        alarmBlink = not alarmBlink
        if alarmBlink then
            monitor.setBackgroundColor(cAlarmBg)
            monitor.setTextColor(cAlarmFg)
            monitor.setCursorPos(isInf and 20 or (panelWidth + 2), 1)
            monitor.write(" [ ! ] ALERTA DE INTRUSO (<1000m) [ ! ] ")
            monitor.setBackgroundColor(cBg)
        end
    end

    if isInf then
        -- MODO INFINITO (Tabela em Tela Cheia)
        monitor.setCursorPos(2, 9)
        monitor.setTextColor(colors.yellow)
        monitor.write("--- TODOS OS JOGADORES ONLINE ---")
        
        local row = 11
        local col = 2
        for _, p in ipairs(players) do
            monitor.setCursorPos(col, row)
            monitor.setTextColor(whitelist[p.name] and colors.lightBlue or cText)
            monitor.write(p.name .. ": ")
            monitor.setTextColor(colors.gray)
            monitor.write("X:" .. p.x .. " Y:" .. p.y .. " Z:" .. p.z)
            
            row = row + 2
            if row > h - 1 then
                row = 11
                col = col + 35 -- Vai para a proxima coluna se faltar espaco
            end
        end
    else
        -- MODO RADAR NORMAL
        drawCircle(centerX, centerY, maxRadiusX, cRadar)
        drawCircle(centerX, centerY, math.floor(maxRadiusX / 2), cRadar)
        
        monitor.setTextColor(colors.gray)
        monitor.setCursorPos(centerX, centerY) monitor.write("+")

        local tableRow = 9
        monitor.setCursorPos(2, tableRow)
        monitor.setTextColor(colors.yellow)
        monitor.write("SINAIS:")
        tableRow = tableRow + 2

        local maxMapDist = ranges[currentRangeIdx]

        for _, p in ipairs(players) do
            local relX = p.x - radarX
            local relZ = p.z - radarZ
            
            local screenRelX = (relX / maxMapDist) * maxRadiusX
            local screenRelZ = (relZ / maxMapDist) * maxRadiusX * aspect
            
            local screenX = math.floor(centerX + screenRelX)
            local screenY = math.floor(centerY + screenRelZ)
            
            -- Desenhar Ponto no Radar
            if screenX > panelWidth and screenX <= w and screenY > 0 and screenY <= h then
                -- Pisca vermelho se for intruso perto
                local isIntruder = (not whitelist[p.name]) and (math.sqrt(relX^2 + relZ^2) <= 1000)
                
                monitor.setCursorPos(screenX, screenY)
                monitor.setTextColor(isIntruder and (alarmBlink and colors.red or colors.orange) or cDot)
                monitor.write("o")
                
                monitor.setCursorPos(screenX - math.floor(string.len(p.name)/2), screenY - 1)
                monitor.setTextColor(colors.white)
                monitor.write(string.sub(p.name, 1, 5))
            end
            
            -- Tabela Lateral
            if tableRow <= h then
                monitor.setCursorPos(2, tableRow)
                monitor.setTextColor(whitelist[p.name] and colors.lightBlue or cText)
                monitor.write(string.sub(p.name, 1, 10))
                monitor.setCursorPos(2, tableRow + 1)
                monitor.setTextColor(colors.gray)
                monitor.write(p.x .. ", " .. p.z)
                tableRow = tableRow + 3
            end
        end
    end
end

local function handleClick(x, y)
    for _, btn in ipairs(buttons) do
        if y == btn.y and x >= btn.x and x < (btn.x + btn.len) then
            if btn.id == "range_down" and currentRangeIdx > 1 then currentRangeIdx = currentRangeIdx - 1
            elseif btn.id == "range_up" and currentRangeIdx < #ranges then currentRangeIdx = currentRangeIdx + 1
            elseif btn.id == "speed_down" and currentSpeedIdx > 1 then currentSpeedIdx = currentSpeedIdx - 1
            elseif btn.id == "speed_up" and currentSpeedIdx < #speeds then currentSpeedIdx = currentSpeedIdx + 1
            end
            return true 
        end
    end
    return false
end

local function main()
    while true do
        drawUI()
        
        local timer = os.startTimer(speeds[currentSpeedIdx])
        
        while true do
            local event, side, x, y = os.pullEvent()
            
            if event == "timer" and side == timer then
                break 
            elseif event == "monitor_touch" then
                if handleClick(x, y) then
                    os.cancelTimer(timer)
                    break 
                end
            end
        end
    end
end

local ok, err = pcall(main)
if not ok then
    print("Erro detetado: ", err)
    monitor.clear()
end
