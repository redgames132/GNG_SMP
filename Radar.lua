-- ==========================================
-- RADAR DE JOGADORES - COMPUTERCRAFT
-- Atualizado para versão 1.21.1 (Neoforge)
-- ==========================================

-- Tenta conectar pelo nome
local detector = peripheral.find("player_detector")
local monitor = peripheral.find("monitor")

-- Sistema anti-falha: Força a conexão pelos lados mostrados na sua foto
if not detector then detector = peripheral.wrap("left") end
if not monitor then monitor = peripheral.wrap("front") end

-- Verifica se conectou
if not monitor then
    print("ERRO: Monitor não encontrado na frente!")
    return
end
if not detector then
    print("ERRO: Player Detector não encontrado na esquerda!")
    return
end

-- ==========================================
-- CONFIGURAÇÕES (MUDE ISTO ANTES DE USAR)
-- Coloque as coordenadas reais de onde o computador está:
-- ==========================================
local meuX = 0  -- Substitua 0 pelo seu X
local meuZ = 0  -- Substitua 0 pelo seu Z

-- Configuração dos alcances
local ranges = {200, 1000, 999999}
local rangeNomes = {"200", "1000", "Infinito"}
local rIndex = 1

-- Prepara o monitor
monitor.setTextScale(0.5)
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

    -- 2. Desenha o círculo do radar (Fundo verde escuro)
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

    -- 3. Desenha a linha de varredura (Sweep Verde Claro)
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

    -- 4. Pega os jogadores e desenha no mapa
    local currentRange = ranges[rIndex]
    
    -- "pcall" previne que o programa quebre se o mod der algum erro de leitura
    local success, players = pcall(detector.getOnlinePlayers)
    
    if success and type(players) == "table" then
        for _, nome in ipairs(players) do
            local successPos, pos = pcall(detector.getPlayerPos, nome)
            
            if successPos and pos and pos.x and pos.z then
                local dx = pos.x - meuX
                local dz = pos.z - meuZ
                local dist = math.sqrt(dx*dx + dz*dz)

                if dist <= currentRange then
                    -- Ajuste de escala (se for infinito, trava o zoom visual em 3000 blocos para caber na tela)
                    local visualRange = currentRange
                    if currentRange == 999999 then 
                        visualRange = math.max(dist, 3000) 
                    end
                    
                    local scale = radius / visualRange
                    local px = cx + math.floor(dx * scale * 2)
                    local pz = cy + math.floor(dz * scale)

                    -- Garante que o ponto não vai sair da tela
                    if px >= 1 and px <= w and pz >= 1 and pz <= h then
                        -- Desenha Ponto
                        monitor.setCursorPos(px, pz)
                        monitor.setTextColor(colors.red)
                        monitor.write("O")
                        
                        -- Desenha Nome
                        monitor.setCursorPos(math.max(1, px - math.floor(#nome / 2)), pz + 1)
                        monitor.setTextColor(colors.white)
                        monitor.write(nome)
                        
                        -- Desenha Coordenadas
                        local coordText = math.floor(pos.x) .. "," .. math.floor(pos.z)
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
-- LOOP PRINCIPAL (Giro do radar e Cliques)
-- ==========================================
while true do
    drawRadar()
    
    -- Velocidade de rotação da linha
    angle = (angle + 15) % 360

    -- Atualiza a tela a cada 0.2 segundos
    local timer = os.startTimer(0.2)
    local event, p1, p2, p3 = os.pullEvent()

    -- Se o jogador clicar no monitor
    if event == "monitor_touch" then
        local clickX, clickY = p2, p3
        -- Checa se o clique foi no botão superior esquerdo
        if clickY == 1 and clickX <= 25 then
            rIndex = rIndex + 1
            if rIndex > #ranges then rIndex = 1 end
        end
    end
end
