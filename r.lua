-- ==========================================
-- Radar HUD V3 - Alarme e Modo Infinito
-- ==========================================

local detector = peripheral.wrap("top")
local monitor = peripheral.wrap("left")
local speaker = peripheral.find("speaker") -- Opcional para som de alarme

if not detector or not monitor then
    print("Erro: Verifique se o detetor esta no topo e o monitor a esquerda!")
    return
end

-- ==========================================
-- CONFIGURAÇÕES
-- ==========================================
local radarX = -8500
local radarZ = -397

-- Lista de pessoas que NAO ativam o alarme (em letras minusculas por seguranca)
local whitelist = {
    ["cadipadi"] = true,
    ["redgames"] = true,
    ["redgames13"] = true,
    ["goonerstickle69"] = true,
    ["goonerstic"] = true
}

local aspect = 0.65
monitor.setTextScale(0.5)

local ranges = {50, 100, 200, 500, 1000, 2000, "Inf"}
local currentRangeIdx = 3

local speeds = {0.5, 1, 2, 5}
local currentSpeedIdx = 2

-- Cores da UI
local colorBg = colors.black
local colorPanelBg = colors.gray
local colorRadar = colors.green
local colorDot = colors.lime
local colorText = colors.white
local colorButton = colors.lightGray
local colorAlert = colors.red

local w, h = monitor.getSize()
local radarSize = math.min(w - 25, h)
local centerX = w - math.floor(radarSize / 2)
local centerY = math.floor(h / 2)
local maxRadiusX = math.floor(radarSize / 2) - 2

local buttons = {}
local isAlarmActive = false

-- Funcoes Basicas
local function clear()
    monitor.setBackgroundColor(colorBg)
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
    monitor.setBackgroundColor(colorBg)
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
    local isInf = (ranges[currentRangeIdx] == "Inf")
    
    local list = {}
    if isInf then
        list = detector.getOnlinePlayers()
    else
        list = detector.getPlayersInRange(ranges[currentRangeIdx])
    end

    for _, name in ipairs(list) do
        local pos = detector.getPlayerPos(name)
        if pos then
            table.insert(players, {
                name = name, 
                x = math.floor(pos.x), 
                y = math.floor(pos.y), 
                z = math.floor(pos.z)
            })
        end
    end
    return players
end

-- Processa UI e Logica Principal
local function drawUI()
    clear()
    isAlarmActive = false
    
    -- Painel Lateral (Fundo)
    monitor.setBackgroundColor(colorPanelBg)
    for y = 1, h do
        monitor.setCursorPos(25, y)
        monitor.write(" ")
    end
    monitor.setBackgroundColor(colorBg)

    -- Controlos
    monitor.setTextColor(colorText)
    monitor.setCursorPos(2, 2) monitor.write("Alcance:")
    drawButton("range_down", 2, 4, "[ - ]", colorButton, colors.black)
    
    local rangeText = tostring(ranges[currentRangeIdx])
    monitor.setCursorPos(9, 4)
    monitor.setBackgroundColor(colorBg)
    monitor.setTextColor(colorText)
    monitor.write(string.rep(" ", 6 - string.len(rangeText)) .. rangeText)
    
    drawButton("range_up", 17, 4, "[ + ]", colorButton, colors.black)

    monitor.setTextColor(colorText)
    monitor.setCursorPos(2, 7) monitor.write("Atualizacao(s):")
    drawButton("speed_down", 2, 9, "[ - ]", colorButton, colors.black)
    
    local speedText = tostring(speeds[currentSpeedIdx])
    monitor.setCursorPos(9, 9)
    monitor.setBackgroundColor(colorBg)
    monitor.setTextColor(colorText)
    monitor.write(string.rep(" ", 6 - string.len(speedText)) .. speedText)
    
    drawButton("speed_up", 17, 9, "[ + ]", colorButton, colors.black)

    -- Obter jogadores e verificar alarme
    local players = getTargetPlayers()
    local isInf = (ranges[currentRangeIdx] == "Inf")

    for _, p in ipairs(players) do
        local dist = math.sqrt((p.x - radarX)^2 + (p.z - radarZ)^2)
        -- Checar Alarme (Menos de 1000 blocos e nao esta na whitelist)
        if dist < 1000 and not whitelist[string.lower(p.name)] then
            isAlarmActive = true
        end
    end

    -- Desenhar Area Direita (Radar ou Tabela Infinita)
    if isInf then
        -- MODO INFINITO: Apenas Tabela
        monitor.setCursorPos(28, 2)
        monitor.setTextColor(colors.yellow)
        monitor.write("=== REGISTO GLOBAL DE JOGADORES ===")
        
        local row = 4
        local col = 28
        for _, p in ipairs(players) do
            monitor.setCursorPos(col, row)
            monitor.setTextColor(colorText)
            monitor.write(string.sub(p.name, 1, 14))
            
            monitor.setCursorPos(col, row + 1)
            monitor.setTextColor(colors.gray)
            monitor.write("X:" .. p.x .. " Y:" .. p.y .. " Z:" .. p.z)
            
            row = row + 3
            if row > h - 2 then
                row = 4
                col = col + 25 -- Muda para a proxima coluna se encher a tela
            end
        end
    else
        -- MODO RADAR NORMAL
        drawCircle(centerX, centerY, maxRadiusX, colorRadar)
        drawCircle(centerX, centerY, math.floor(maxRadiusX / 2), colorRadar)
        monitor.setTextColor(colors.gray)
        monitor.setCursorPos(centerX, centerY) monitor.write("+")

        local tableRow = 12
        monitor.setCursorPos(2, tableRow)
        monitor.setTextColor(colors.yellow)
        monitor.write("SINAIS LOCAIS:")
        tableRow = tableRow + 2

        for _, p in ipairs(players) do
            local maxMapDist = ranges[currentRangeIdx]
            local relX = p.x - radarX
            local relZ = p.z - radarZ
            
            local screenRelX = (relX / maxMapDist) * maxRadiusX
            local screenRelZ = (relZ / maxMapDist) * maxRadiusX * aspect
            local screenX = math.floor(centerX + screenRelX)
            local screenY = math.floor(centerY + screenRelZ)
            
            -- Desenhar ponto no radar
            if screenX > 25 and screenX <= w and screenY > 0 and screenY <= h then
                -- Pisca vermelho se for intruso
                if not whitelist[string.lower(p.name)] then
                    monitor.setTextColor(colorAlert)
                else
                    monitor.setTextColor(colorDot)
                end
                monitor.setCursorPos(screenX, screenY)
                monitor.write("o")
                
                monitor.setCursorPos(screenX - math.floor(string.len(p.name)/2), screenY - 1)
                monitor.setTextColor(colors.white)
                monitor.write(string.sub(p.name, 1, 5))
            end
            
            -- Tabela esquerda
            if tableRow <= h - 1 then
                monitor.setCursorPos(2, tableRow)
                if not whitelist[string.lower(p.name)] then
                    monitor.setTextColor(colorAlert)
                else
                    monitor.setTextColor(colorText)
                end
                monitor.write(string.sub(p.name, 1, 10))
                monitor.setCursorPos(2, tableRow + 1)
                monitor.setTextColor(colors.gray)
                monitor.write("X:" .. p.x .. " Z:" .. p.z)
                tableRow = tableRow + 3
            end
        end
    end

    -- ALARME VISUAL E SONORO
    if isAlarmActive then
        monitor.setCursorPos(2, h)
        monitor.setBackgroundColor(colorAlert)
        monitor.setTextColor(colors.white)
        monitor.write(" !! INVASOR !! ")
        monitor.setBackgroundColor(colorBg)
        
        if speaker then
            -- Toca um som de sino/alerta
            speaker.playSound("block.note_block.bell", 3, 1)
        end
    end
end

-- Interacao com Cliques
local function handleClick(x, y)
    for _, btn in ipairs(buttons) do
        if y == btn.y and x >= btn.x and x < (btn.x + btn.len) then
            if btn.id == "range_down" and currentRangeIdx > 1 then
                currentRangeIdx = currentRangeIdx - 1
            elseif btn.id == "range_up" and currentRangeIdx < #ranges then
                currentRangeIdx = currentRangeIdx + 1
            elseif btn.id == "speed_down" and currentSpeedIdx > 1 then
                currentSpeedIdx = currentSpeedIdx - 1
            elseif btn.id == "speed_up" and currentSpeedIdx < #speeds then
                currentSpeedIdx = currentSpeedIdx + 1
            end
            return true
        end
    end
    return false
end

-- Loop Principal
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
    print("Erro: ", err)
    monitor.clear()
end
