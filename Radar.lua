-- ==========================================
-- RADAR DE JOGADORES 3D - VERSAO PRO
-- ==========================================

local detector = peripheral.find("player_detector")
local monitor = peripheral.find("monitor")

if not detector then detector = peripheral.wrap("left") end
if not monitor then monitor = peripheral.wrap("front") end

if not monitor or not detector then
    print("ERRO: Perifericos nao encontrados!")
    return
end

-- ==========================================
-- CONFIGURAÇÕES DA SUA BASE
-- ==========================================
local meuX = -573
local meuY = 57
local meuZ = -1446

-- Configurações de Controle
local ranges = {200, 1000, 999999}
local rangeNomes = {"200", "1000", "Inf"}
local rIndex = 1

local speeds = {2, 5, 12} -- Diminuí os pulos pois a tela atualiza mais rápido agora
local speedNomes = {"Lenta", "Normal", "Rapida"}
local sIndex = 2

-- Configuração da Tela e Sistema Anti-Piscar (Buffer)
monitor.setTextScale(0.5)
local w, h = monitor.getSize()
local buffer = window.create(monitor, 1, 1, w, h, false) -- Tela invisível

local cx = math.floor(w / 2)
local cy = math.floor(h / 2) + 1 -- Desce o centro um pouco para compensar a barra superior
local radius = math.floor(math.min(cx / 1.5, cy)) - 3
local angle = 0

local function drawRadar()
    -- Começa a desenhar na tela invisível
    buffer.setVisible(false)
    buffer.setBackgroundColor(colors.black)
    buffer.clear()

    -- 1. Barra de Status Superior (UI)
    buffer.setCursorPos(1, 1)
    buffer.setBackgroundColor(colors.gray)
    buffer.setTextColor(colors.white)
    -- Preenche a linha inteira de cinza
    buffer.write(string.rep(" ", w)) 
    
    -- Botões na barra
    buffer.setCursorPos(2, 1)
    buffer.setTextColor(colors.lightGray)
    buffer.write("ALCANCE: ")
    buffer.setTextColor(colors.white)
    buffer.write(rangeNomes[rIndex])
    
    buffer.setCursorPos(18, 1)
    buffer.setTextColor(colors.lightGray)
    buffer.write("VEL: ")
    buffer.setTextColor(colors.white)
    buffer.write(speedNomes[sIndex])
    
    buffer.setBackgroundColor(colors.black)

    -- 2. Rosa dos Ventos (Pontos Cardeais)
    buffer.setTextColor(colors.gray)
    buffer.setCursorPos(cx, cy - radius - 1)
    buffer.write("N")
    buffer.setCursorPos(cx, cy + radius + 1)
    buffer.write("S")
    buffer.setCursorPos(cx + math.floor(radius * 1.5) + 1, cy)
    buffer.write("L")
    buffer.setCursorPos(cx - math.floor(radius * 1.5) - 1, cy)
    buffer.write("O")

    -- 3. Círculo do Radar
    buffer.setTextColor(colors.green)
    for i = 0, 359, 10 do
        local rad = math.rad(i)
        local x = cx + math.floor(math.cos(rad) * radius * 1.5) 
        local y = cy + math.floor(math.sin(rad) * radius)
        if x >= 1 and x <= w and y >= 2 and y <= h then
            buffer.setCursorPos(x, y)
            buffer.write(".")
        end
    end

    -- 4. Centro do Radar (Você)
    buffer.setCursorPos(cx, cy)
    buffer.setTextColor(colors.white)
    buffer.write("X")

    -- 5. Linha de Varredura (Agora com um "rastro" sutil)
    for offset = 0, 2 do
        local sweepRad = math.rad(angle - (offset * 2))
        local col = offset == 0 and colors.lime or colors.green
        buffer.setTextColor(col)
        
        for r = 1, radius do
            local x = cx + math.floor(math.cos(sweepRad) * r * 1.5)
            local y = cy + math.floor(math.sin(sweepRad) * r)
            if x >= 1 and x <= w and y >= 2 and y <= h and not (x == cx and y == cy) then
                buffer.setCursorPos(x, y)
                buffer.write(offset == 0 and "+" or ".")
            end
        end
    end

    -- 6. Detecção de Jogadores
    local currentRange = ranges[rIndex]
    local success, players = pcall(detector.getOnlinePlayers)
    
    if success and type(players) == "table" then
        for _, nome in ipairs(players) do
            local successPos, pos = pcall(detector.getPlayerPos, nome)
            
            if successPos and pos and pos.x and pos.y and pos.z then
                local dx = pos.x - meuX
                local dy = pos.y - meuY
                local dz = pos.z - meuZ
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                if dist <= currentRange then
                    local visualRange = currentRange
                    if currentRange == 999999 then 
                        visualRange = math.max(dist, 3000) 
                    end
                    
                    local scale = radius / visualRange
                    local px = cx + math.floor(dx * scale * 1.5)
                    local pz = cy + math.floor(dz * scale)

                    if px >= 1 and px <= w and pz >= 2 and pz <= h then
                        -- Ponto
                        buffer.setCursorPos(px, pz)
                        buffer.setTextColor(colors.red)
                        buffer.write("O")
                        
                        -- Nome e Distância
                        buffer.setCursorPos(math.max(1, px - math.floor(#nome / 2)), pz + 1)
                        buffer.setTextColor(colors.white)
                        buffer.write(nome)
                        
                        local distText = math.floor(dist) .. "m"
                        buffer.setCursorPos(math.max(1, px - math.floor(#distText / 2)), pz + 2)
                        buffer.setTextColor(colors.lightGray)
                        buffer.write(distText)
                    end
                end
            end
        end
    end

    -- Atualiza o monitor real instantaneamente com o que foi desenhado no buffer
    buffer.setVisible(true)
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================
while true do
    drawRadar()
    
    angle = (angle + speeds[sIndex]) % 360

    -- Timer ultrarrápido graças ao buffer
    local timer = os.startTimer(0.05)
    local event, p1, p2, p3 = os.pullEvent()

    if event == "monitor_touch" then
        local clickX, clickY = p2, p3
        
        if clickY == 1 then
            -- Se clicar na área do Alcance
            if clickX <= 15 then
                rIndex = rIndex + 1
                if rIndex > #ranges then rIndex = 1 end
            -- Se clicar na área da Velocidade
            elseif clickX >= 16 and clickX <= 30 then
                sIndex = sIndex + 1
                if sIndex > #speeds then sIndex = 1 end
            end
        end
    end
end
