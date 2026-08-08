-- ==========================================
-- RADAR RED_INDUSTRIES (V6 - ANTI-LAG)
-- Coordenadas da Base: -573, 57, -1446
-- ==========================================

local function findPeripheral(typeKeyword)
    local found = peripheral.find(typeKeyword)
    if found then return found end
    for _, side in ipairs(peripheral.getNames()) do
        if peripheral.getType(side) and string.find(peripheral.getType(side), typeKeyword) then
            return peripheral.wrap(side)
        end
    end
    return nil
end

local detector = findPeripheral("player_detector")
local monitor = findPeripheral("monitor")

if not monitor or not detector then
    print("ERRO CRITICO: Perifericos nao encontrados!")
    return
end

-- ==========================================
-- COORDENADAS FIXAS
-- ==========================================
local meuX = -573
local meuY = 57
local meuZ = -1446

-- Configurações
local ranges = {200, 1000, 999999}
local rangeNomes = {"200m", "1000m", "Infin"}
local rIndex = 1

local speeds = {5, 10, 20} -- Ajustado para ser fluido com o novo timer
local speedNomes = {"Lenta", "Normal", "Rapida"}
local sIndex = 2

-- Configuração Visual
monitor.setTextScale(0.5)
local w, h = monitor.getSize()
local buffer = window.create(monitor, 1, 1, w, h, false)

local cx = math.floor(w / 2)
local cy = math.floor(h / 2) + 2
local radius = math.floor(math.min(cx / 1.5, cy)) - 4
local angle = 0

-- ==========================================
-- SISTEMA DE CACHE (O SEGREDO CONTRA O LAG)
-- ==========================================
local cachedPlayers = {}
local framesSinceLastScan = 10 -- Começa em 10 para escanear no primeiro frame

local function scanPlayers()
    local success, players = pcall(detector.getOnlinePlayers)
    local newCache = {}
    
    if success and type(players) == "table" then
        for _, nome in ipairs(players) do
            local successPos, pos = pcall(detector.getPlayerPos, nome)
            if successPos and pos and pos.x and pos.y and pos.z then
                -- Salva os dados na memória temporária
                table.insert(newCache, {nome = nome, x = pos.x, y = pos.y, z = pos.z})
            end
        end
    end
    cachedPlayers = newCache
end

-- ==========================================
-- MOTOR GRÁFICO (DESENHO)
-- ==========================================
local function drawRadar()
    buffer.setVisible(false)
    buffer.setBackgroundColor(colors.black)
    buffer.clear()

    local meio = math.floor(w / 2)

    -- UI Superior
    for y = 1, 2 do
        buffer.setCursorPos(1, y)
        buffer.setBackgroundColor(colors.gray)
        buffer.write(string.rep(" ", meio))
    end
    buffer.setCursorPos(2, 1)
    buffer.setTextColor(colors.white)
    buffer.write("ALCANCE:")
    buffer.setCursorPos(2, 2)
    buffer.setTextColor(colors.yellow)
    buffer.write("> " .. rangeNomes[rIndex] .. " <")

    local startX = meio + 1
    local widthRight = w - meio
    for y = 1, 2 do
        buffer.setCursorPos(startX, y)
        buffer.setBackgroundColor(colors.lightGray)
        buffer.write(string.rep(" ", widthRight))
    end
    buffer.setCursorPos(startX + 1, 1)
    buffer.setTextColor(colors.black)
    buffer.write("VELOCIDADE:")
    buffer.setCursorPos(startX + 1, 2)
    buffer.setTextColor(colors.cyan)
    buffer.write("> " .. speedNomes[sIndex] .. " <")

    buffer.setBackgroundColor(colors.black)

    -- Pontos Cardeais
    buffer.setTextColor(colors.gray)
    buffer.setCursorPos(cx, math.max(4, cy - radius - 1))
    buffer.write("N")
    buffer.setCursorPos(cx, math.min(h, cy + radius + 1))
    buffer.write("S")
    buffer.setCursorPos(math.min(w, cx + math.floor(radius * 1.5) + 1), cy)
    buffer.write("L")
    buffer.setCursorPos(math.max(1, cx - math.floor(radius * 1.5) - 1), cy)
    buffer.write("O")

    -- Círculo
    buffer.setTextColor(colors.green)
    for i = 0, 359, 10 do
        local rad = math.rad(i)
        local x = cx + math.floor(math.cos(rad) * radius * 1.5) 
        local y = cy + math.floor(math.sin(rad) * radius)
        if x >= 1 and x <= w and y >= 4 and y <= h then
            buffer.setCursorPos(x, y)
            buffer.write(".")
        end
    end

    buffer.setCursorPos(cx, cy)
    buffer.setTextColor(colors.white)
    buffer.write("X")

    -- Varredura Animada
    for offset = 0, 2 do
        local sweepRad = math.rad(angle - (offset * 2))
        local col = (offset == 0) and colors.lime or colors.green
        buffer.setTextColor(col)
        
        for r = 1, radius do
            local x = cx + math.floor(math.cos(sweepRad) * r * 1.5)
            local y = cy + math.floor(math.sin(sweepRad) * r)
            if x >= 1 and x <= w and y >= 4 and y <= h and not (x == cx and y == cy) then
                buffer.setCursorPos(x, y)
                buffer.write(offset == 0 and "+" or ".")
            end
        end
    end

    -- Desenha os Jogadores lendo do CACHE (Zero lag de servidor)
    local currentRange = ranges[rIndex]
    
    for _, player in ipairs(cachedPlayers) do
        local dx = player.x - meuX
        local dy = player.y - meuY
        local dz = player.z - meuZ
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

        if dist <= currentRange then
            local visualRange = currentRange
            if currentRange == 999999 then 
                visualRange = math.max(dist, 3000) 
            end
            
            local scale = radius / visualRange
            local px = cx + math.floor(dx * scale * 1.5)
            local pz = cy + math.floor(dz * scale)

            if px >= 1 and px <= w and pz >= 4 and pz <= h then
                buffer.setCursorPos(px, pz)
                buffer.setTextColor(colors.red)
                buffer.write("O")
                
                buffer.setCursorPos(math.max(1, px - math.floor(#player.nome / 2)), pz + 1)
                buffer.setTextColor(colors.white)
                buffer.write(player.nome)
                
                local distText = math.floor(dist) .. "m"
                buffer.setCursorPos(math.max(1, px - math.floor(#distText / 2)), pz + 2)
                buffer.setTextColor(colors.lightGray)
                buffer.write(distText)
            end
        end
    end

    buffer.setVisible(true)
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================

term.clear()
term.setCursorPos(1, 1)
print("======================================")
print(" RADAR OTIMIZADO (ANTI-LAG) ATIVO")
print("======================================")
print(" > Sistema de cache online.")

local running = true
local updateTimer = os.startTimer(0.08) -- Tempo ideal para evitar crash no CC

while running do
    local event, p1, p2, p3 = os.pullEvent()

    if event == "timer" and p1 == updateTimer then
        -- 1. Controle de Scan de Jogadores (Só escaneia a cada 10 frames = ~0.8s)
        framesSinceLastScan = framesSinceLastScan + 1
        if framesSinceLastScan >= 10 then
            scanPlayers()
            framesSinceLastScan = 0
        end

        -- 2. Atualiza a animação
        angle = (angle + speeds[sIndex]) % 360
        drawRadar()
        
        -- 3. Reinicia o timer de forma saudável
        updateTimer = os.startTimer(0.08)

    elseif event == "monitor_touch" then
        local clickX, clickY = p2, p3
        
        if clickY <= 3 then
            local meio = math.floor(w / 2)
            if clickX <= meio then
                rIndex = rIndex + 1
                if rIndex > #ranges then rIndex = 1 end
            else
                sIndex = sIndex + 1
                if sIndex > #speeds then sIndex = 1 end
            end
            drawRadar()
        end

    elseif event == "key" then
        if p1 == keys.f then
            running = false
        end
    end
end

-- Desliga
monitor.setBackgroundColor(colors.black)
monitor.clear()
monitor.setCursorPos(1, 1)
monitor.setTextColor(colors.red)
monitor.write("SISTEMA DESLIGADO")
term.clear()
term.setCursorPos(1, 1)
print("Radar encerrado com segurança.")
