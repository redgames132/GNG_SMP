-- ==========================================
-- RADAR DE JOGADORES - COMPUTERCRAFT
-- ==========================================

-- Conecta os periféricos
local monitor = peripheral.find("monitor")
local detector = peripheral.find("player_detector")

if not monitor then
    print("ERRO: Monitor não encontrado!")
    return
end
if not detector then
    print("ERRO: Player Detector não encontrado!")
    return
end

-- ==========================================
-- CONFIGURAÇÕES (ALTERE AQUI)
-- Coloque as coordenadas reais da sua base:
-- ==========================================
local meuX = 150  -- Mude para o seu X
local meuZ = -320 -- Mude para o seu Z

-- Configuração dos alcances (200, 1000, 999999 simulando infinito)
local ranges = {200, 1000, 999999}
local rangeNomes = {"200", "1000", "Infinito"}
local rIndex = 1

-- Prepara o monitor
monitor.setTextScale(0.5) -- Deixa os "pixels" menores
local w, h = monitor.getSize()
local cx = math.floor(w / 2)
local cy = math.floor(h / 2)
local radius = math.min(cx, cy) - 2
local angle = 0

-- Função principal de desenho
local function drawRadar()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    -- 1. Desenha o botão de configuração
    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(colors.gray)
    monitor.setTextColor(colors.white)
    monitor.write(" [ Alcance: " .. rangeNomes[rIndex] .. " ] ")
    monitor.setBackgroundColor(colors.black)

    -- 2. Desenha o círculo do radar
    monitor.setTextColor(colors.green)
    for i = 0, 359, 10 do
        local rad = math.rad(i)
        -- Multiplicamos o X por 2 porque as letras no CC são mais altas do que largas
        local x = cx + math.floor(math.cos(rad) * radius * 2) 
        local y = cy + math.floor(math.sin(rad) * radius)
        if x > 0 and x <= w and y > 0 and y <= h then
            monitor.setCursorPos(x, y)
            monitor.write(".")
        end
    end

    -- 3. Desenha a linha de varredura (Sweep)
    local sweepRad = math.rad(angle)
    for r = 1, radius do
        local x = cx + math.floor(math.cos(sweepRad) * r * 2)
        local y = cy + math.floor(math.sin(sweepRad) * r)
        if x > 0 and x <= w and y > 0 and y <= h then
            monitor.setCursorPos(x, y)
            monitor.setTextColor(colors.lime)
            monitor.write("+")
        end
    end

    -- 4. Pega os jogadores e desenha no mapa
    local currentRange = ranges[rIndex]
    local success, players = pcall(detector.getOnlinePlayers)
    
    if success and players then
        for _, nome in ipairs(players) do
            local pos = detector.getPlayerPos(nome)
            
            if pos and pos.x and pos.z then
                -- Calcula a distância entre o radar e o jogador
                local dx = pos.x - meuX
                local dz = pos.z - meuZ
                local dist = math.sqrt(dx*dx + dz*dz)

                -- Se estiver dentro do alcance selecionado, desenha na tela
                if dist <= currentRange then
                    local scale = radius / currentRange
                    local px = cx + math.floor(dx * scale * 2)
                    local pz = cy + math.floor(dz * scale)

                    -- Garante que o ponto não vai sair da tela
                    if px > 0 and px <= w and pz > 0 and pz <= h then
                        -- Desenha o ponto do jogador
                        monitor.setCursorPos(px, pz)
                        monitor.setTextColor(colors.red)
                        monitor.write("O")
                        
                        -- Desenha o Nome
                        monitor.setCursorPos(px - math.floor(#nome / 2), pz + 1)
                        monitor.setTextColor(colors.white)
                        monitor.write(nome)
                        
                        -- Desenha as Coordenadas
                        local coordText = math.floor(pos.x) .. ", " .. math.floor(pos.z)
                        monitor.setCursorPos(px - math.floor(#coordText / 2), pz + 2)
                        monitor.setTextColor(colors.lightGray)
                        monitor.write(coordText)
                    end
                end
            end
        end
    end
end

-- ==========================================
-- LOOP PRINCIPAL (Varredura e Cliques)
-- ==========================================
while true do
    drawRadar()
    
    -- Gira a linha do radar em 15 graus por quadro
    angle = (angle + 15) % 360

    -- Inicia um timer rápido para atualizar a tela
    local timer = os.startTimer(0.3)
    
    -- Espera por um clique na tela ou o timer acabar
    local event, p1, p2, p3 = os.pullEvent()

    if event == "monitor_touch" then
        local clickX, clickY = p2, p3
        -- Se o clique foi na região do botão superior esquerdo
        if clickY == 1 and clickX <= 25 then
            rIndex = rIndex + 1
            if rIndex > #ranges then rIndex = 1 end
        end
    end
end
