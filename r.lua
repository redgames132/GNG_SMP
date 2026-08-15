-- ==========================================
-- Radar HUD V4 - APEX EDITION
-- ==========================================

local detector = peripheral.wrap("top")
local monitor = peripheral.wrap("left")

if not detector or not monitor then
    print("Erro: Detetor no 'top' ou monitor na 'left' nao encontrados!")
    return
end

-- ==========================================
-- CONFIGURACOES DE BASE
-- ==========================================
local radarX = -8500
local radarZ = -397

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

-- ==========================================
-- PALETA DE CORES (UI)
-- ==========================================
local cMenuBg   = colors.gray
local cRadarBg  = colors.black
local cTitle    = colors.yellow
local cText     = colors.white
local cTextDark = colors.lightGray
local cBtnBg    = colors.cyan
local cBtnFg    = colors.black
local cRadar    = colors.green
local cDot      = colors.lime
local cFriend   = colors.lightBlue
local cAlarmBg  = colors.red
local cAlarmFg  = colors.white

local w, h = monitor.getSize()
local panelWidth = 26 -- Largura do menu esquerdo
local radarSize = math.min(w - panelWidth, h) 
local centerX = panelWidth + math.floor((w - panelWidth) / 2)
local centerY = math.floor(h / 2)
local maxRadiusX = math.floor(radarSize / 2) - 3

local buttons = {}
local alarmBlink = false

-- Funcoes de Desenho Basicas
local function drawText(x, y, text, fg, bg)
    monitor.setCursorPos(x, y)
    if fg then monitor.setTextColor(fg) end
    if bg then monitor.setBackgroundColor(bg) end
    monitor.write(text)
end

local function drawButton(id, x, y, text)
    drawText(x, y, text, cBtnFg, cBtnBg)
    table.insert(buttons, {id=id, x=x, y=y, len=string.len(text)})
end

local function fillRect(x, y, width, height, color)
    monitor.setBackgroundColor(color)
    for iy = 0, height - 1 do
        monitor.setCursorPos(x, y + iy)
        monitor.write(string.rep(" ", width))
    end
end

local function drawCircle(cx, cy, radiusX, color)
    monitor.setTextColor(color)
    monitor.setBackgroundColor(cRadarBg)
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
    monitor.setBackgroundColor(cRadarBg)
    monitor.clear()
    buttons = {}
    
    local isInf = (ranges[currentRangeIdx] == "Inf")
    local players = getTargetPlayers()
    
    -- Verifica Alarme
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

    if isInf then
        -- ==========================================
        -- TELA: MODO INFINITO (DATABASE GLOBAL)
        -- ==========================================
        fillRect(1, 1, w, 3, cMenuBg)
        drawText(math.floor(w/2) - 15, 2, "=== SISTEMA DE RASTREIO GLOBAL ===", cTitle, cMenuBg)
        
        -- Controlos minimizados no topo
        drawText(2, 2, "ALCANCE:", cText, cMenuBg)
        drawButton("range_down", 11, 2, "<")
        drawText(13, 2, "Inf", cText, cMenuBg)
        drawButton("range_up", 17, 2, ">")
        
        -- Cabecalhos da tabela
        drawText(2, 5, "NOME DO JOGADOR", cTextDark, cRadarBg)
        drawText(25, 5, "COORDENADAS (X, Y, Z)", cTextDark, cRadarBg)
        drawText(1, 6, string.rep("-", w), cMenuBg, cRadarBg)
        
        local row = 7
        local col1 = 2
        local col2 = 25
        for _, p in ipairs(players) do
            local color = whitelist[p.name] and cFriend or cText
            drawText(col1, row, p.name, color, cRadarBg)
            drawText(col2, row, string.format("X: %-6d Y: %-3d Z: %-6d", p.x, p.y, p.z), cTextDark, cRadarBg)
            
            row = row + 2
            if row > h - 1 then
                row = 7
                col1 = col1 + 45
                col2 = col2 + 45
            end
        end

    else
        -- ==========================================
        -- TELA: MODO RADAR NORMAL
        -- ==========================================
        -- Fundo do Menu Esquerdo
        fillRect(1, 1, panelWidth, h, cMenuBg)
        
        -- Cabecalho Menu
        drawText(2, 2, "-= PAINEL DE CONTROLE =-", cTitle, cMenuBg)
        
        -- Controles: Raio
        drawText(2, 4, "ALCANCE (Blocos):", cText, cMenuBg)
        drawButton("range_down", 2, 6, " [ < ] ")
        
        local rangeText = tostring(ranges[currentRangeIdx])
        local pad = string.rep(" ", math.floor((6 - string.len(rangeText))/2))
        drawText(10, 6, pad .. rangeText .. pad, cText, cRadarBg)
        
        drawButton("range_up", 18, 6, " [ > ] ")

        -- Controles: Velocidade
        drawText(2, 9, "ATUALIZACAO (Seg):", cText, cMenuBg)
        drawButton("speed_down", 2, 11, " [ < ] ")
        
        local speedText = tostring(speeds[currentSpeedIdx])
        pad = string.rep(" ", math.floor((6 - string.len(speedText))/2))
        drawText(10, 11, pad .. speedText .. pad, cText, cRadarBg)
        
        drawButton("speed_up", 18, 11, " [ > ] ")

        -- Linha separadora
        drawText(2, 14, string.rep("-", panelWidth-2), cTextDark, cMenuBg)
        drawText(2, 15, "SINAIS DETECTADOS:", cTitle, cMenuBg)
        
        -- Desenhar Anéis do Radar
        drawCircle(centerX, centerY, maxRadiusX, cRadar)
        drawCircle(centerX, centerY, math.floor(maxRadiusX * 0.66), cRadar)
        drawCircle(centerX, centerY, math.floor(maxRadiusX * 0.33), cRadar)
        drawText(centerX, centerY, "+", cTextDark, cRadarBg)

        -- Barra de Alarme
        if alarmActive then
            alarmBlink = not alarmBlink
            if alarmBlink then
                local alertMsg = " [!] INTRUSO DETECTADO (<1000m) [!] "
                local alertPad = math.floor(((w - panelWidth) - string.len(alertMsg)) / 2)
                drawText(panelWidth + 1, 2, string.rep(" ", alertPad) .. alertMsg .. string.rep(" ", alertPad), cAlarmFg, cAlarmBg)
            end
        end

        local tableRow = 17
        local maxMapDist = ranges[currentRangeIdx]

        -- Processar Pontos no Radar e Lista
        for _, p in ipairs(players) do
            local relX = p.x - radarX
            local relZ = p.z - radarZ
            
            local screenRelX = (relX / maxMapDist) * maxRadiusX
            local screenRelZ = (relZ / maxMapDist) * maxRadiusX * aspect
            
            local screenX = math.floor(centerX + screenRelX)
            local screenY = math.floor(centerY + screenRelZ)
            
            local isFriend = whitelist[p.name]
            local isIntruder = (not isFriend) and (math.sqrt(relX^2 + relZ^2) <= 1000)
            
            -- Desenhar no Mapa
            if screenX > panelWidth and screenX <= w and screenY > 0 and screenY <= h then
                local dotColor = cDot
                if isIntruder then dotColor = (alarmBlink and colors.red or colors.orange) end
                if isFriend then dotColor = cFriend end
                
                drawText(screenX, screenY, "o", dotColor, cRadarBg)
                drawText(screenX - math.floor(string.len(p.name)/2), screenY + 1, string.sub(p.name, 1, 5), cText, cRadarBg)
            end
            
            -- Tabela Menu Esquerdo
            if tableRow <= h - 2 then
                drawText(2, tableRow, string.sub(p.name, 1, 12), isFriend and cFriend or cText, cMenuBg)
                drawText(15, tableRow, string.format("[%d, %d]", p.x, p.z), cTextDark, cMenuBg)
                tableRow = tableRow + 2
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
    print("Erro critico:", err)
    monitor.clear()
end
