-- ==========================================
-- RADAR DE JOGADORES 3D - COMPUTERCRAFT
-- ==========================================

-- Conecta os periféricos
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
-- Coloque as coordenadas reais do computador:
-- ==========================================
local meuX = 0  -- Substitua pelo seu X
local meuY = 0  -- Substitua pelo seu Y (Altura)
local meuZ = 0  -- Substitua pelo seu Z

-- Configurações de Alcance
local ranges = {200, 1000, 999999}
local rangeNomes = {"200", "1000", "Infinito"}
local rIndex = 1

-- Configurações de Velocidade da Varredura
local speeds = {5, 15, 35} -- Quantos graus a linha pula
local speedNomes = {"Lenta", "Normal", "Rapida"}
local sIndex = 2 -- Começa na Normal

-- Prepara o monitor
monitor.setTextScale(0.5)
local w, h = monitor.getSize()
local cx = math.floor(w / 2)
local cy = math.floor(h / 2)
local radius = math.min(cx, cy) - 2
local angle = 0

-- Função para desenhar a interface
local function drawRadar()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    -- 1. Botão de Alcance
    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(colors.gray)
    monitor.setTextColor(colors.white)
    monitor.write(" Alcance: " .. rangeNomes[rIndex] .. " ")
    
    -- 2. Botão de Velocidade
    monitor.setCursorPos(1, 2)
    monitor.write(" Vel: " .. speedNomes[sIndex] .. " ")
    monitor.setBackgroundColor(colors.black)

    -- 3. Desenha o círculo fixo do radar
    monitor.setTextColor(colors.green)
    for i = 0, 359, 10 do
        local rad = math.rad(i)
        local x = cx + math.floor(math.cos(rad) * radius * 2) 
        local y = cy + math.floor(math.sin(rad) * radius)
        if x >= 1 and x <= w and y >= 1 and y <= h then
            monitor.setCursorPos(x, y)
            monitor.write(".")
        end
    end

    -- 4. Desenha a linha de varredura
    local sweepRad = math.rad(angle)
    for r = 1, radius do
        local x = cx + math.floor(math.cos(sweepRad) * r * 2)
        local y = cy + math.floor(math.sin(sweepRad) * r)
        if x >= 1 and x <= w and y >= 1 and y <= h then
            monitor.setCursorPos(x, y)
            monitor.setTextColor(colors.lime)
            monitor.write("+")
        end
    end

    -- 5. Busca os jogadores (Cálculo 3D)
    local currentRange = ranges[rIndex]
    local success, players = pcall(detector.getOnlinePlayers)
    
    if success and type(players) == "table" then
        for _, nome in ipairs(players) do
            local successPos, pos = pcall(detector.getPlayerPos, nome)
            
            if successPos and pos and pos.x and pos.y and pos.z then
                -- CÁLCULO 3D (Incluindo o eixo Y)
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
                    local px = cx + math.floor(dx * scale * 2)
                    local pz = cy + math.floor(dz * scale) -- Z vira o eixo vertical no mapa 2D

                    -- Desenha o jogador se couber na tela
                    if px >= 1 and px <= w and pz >= 1 and pz <= h then
                        -- Ponto Vermelho
                        monitor.setCursorPos(px, pz)
                        monitor.setTextColor(colors.red)
                        monitor.write("O")
                        
                        -- Nome
                        monitor.setCursorPos(math.max(1, px - math.floor(#nome / 2)), pz + 1)
                        monitor.setTextColor(colors.white)
                        monitor.write(nome)
                        
                        -- Coordenadas 3D (X, Y, Z)
                        local coordText = math.floor(pos.x) .. "," .. math.floor(pos.y) .. "," .. math.floor(pos.z)
                        monitor.setCursorPos(math.max(1, px - math.floor(#coordText / 2)), pz + 2)
                        monitor.setTextColor(colors.lightGray)
                        monitor.write(coordText)
                    end
                end
            end
        end
    end
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================
while true do
    drawRadar()
    
    -- Gira a linha com a velocidade selecionada
    angle = (angle + speeds[sIndex]) % 360

    -- Atualização mais rápida para a animação ficar fluida
    local timer = os.startTimer(0.1)
    local event, p1, p2, p3 = os.pullEvent()

    -- Cliques na tela
    if event == "monitor_touch" then
        local clickX, clickY = p2, p3
        
        -- Botão 1: Alcance (Linha 1)
        if clickY == 1 and clickX <= 22 then
            rIndex = rIndex + 1
            if rIndex > #ranges then rIndex = 1 end
        end
        
        -- Botão 2: Velocidade (Linha 2)
        if clickY == 2 and clickX <= 22 then
            sIndex = sIndex + 1
            if sIndex > #speeds then sIndex = 1 end
        end
    end
end
