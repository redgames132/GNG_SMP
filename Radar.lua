-- ==========================================
-- Radar estilo HUD com Agrupamento
-- Requisitos: Advanced Peripherals, Monitor
-- ==========================================

-- Desta vez, dizemos exatamente onde estão os aparelhos com base na sua imagem
local detector = peripheral.wrap("top")
local monitor = peripheral.wrap("left")

-- Verificações de segurança
if not detector then
    -- Tenta procurar pelo nome atualizado caso o "wrap" falhe por algum motivo
    detector = peripheral.find("playerDetector") or peripheral.find("player_detector")
    if not detector then
        print("Erro: Detetor de jogadores não encontrado no topo!")
        return
    end
end

if not monitor then
    monitor = peripheral.find("monitor")
    if not monitor then
        print("Erro: Monitor não encontrado à esquerda!")
        return
    end
end

monitor.setTextScale(0.5) -- Deixa os "píxeis" mais pequenos para maior resolução
local w, h = monitor.getSize()
local centerX, centerY = math.floor(w / 2), math.floor(h / 2)

-- Configurações de Raio
local ranges = {200, 1000, "Inf"}
local currentRangeIdx = 1

-- Cores baseadas na imagem de referência original
local colorBg = colors.black
local colorRadar = colors.green
local colorDot = colors.lime
local colorText = colors.lightGray

-- Limpa e prepara o monitor
local function clear()
    monitor.setBackgroundColor(colorBg)
    monitor.clear()
end

-- Desenha um círculo simples (anéis do radar)
local function drawCircle(x0, y0, radius, color)
    monitor.setBackgroundColor(colorBg)
    monitor.setTextColor(color)
    for x = -radius, radius do
        local y = math.floor(math.sqrt(radius * radius - x * x) + 0.5)
        monitor.setCursorPos(x0 + x, y0 + y)
        monitor.write(".")
        monitor.setCursorPos(x0 + x, y0 - y)
        monitor.write(".")
        monitor.setCursorPos(x0 + y, y0 + x)
        monitor.write(".")
        monitor.setCursorPos(x0 - y, y0 + x)
        monitor.write(".")
    end
end

-- Procura os jogadores baseados na configuração
local function getTargetPlayers()
    local players = {}
    local maxDist = ranges[currentRangeIdx]
    
    local list = {}
    if maxDist == "Inf" then
        list = detector.getOnlinePlayers()
    else
        list = detector.getPlayersInRange(maxDist)
    end

    for _, name in ipairs(list) do
        local pos = detector.getPlayerPos(name)
        if pos then
            table.insert(players, {name = name, x = math.floor(pos.x), y = math.floor(pos.y), z = math.floor(pos.z)})
        end
    end
    return players
end

-- Agrupa jogadores próximos
local function clusterPlayers(players, groupDistanceThreshold)
    local clusters = {}
    for _, p in ipairs(players) do
        local added = false
        for _, c in ipairs(clusters) do
            -- Calcula a distância plana (X e Z)
            local dist = math.sqrt((p.x - c.centerX)^2 + (p.z - c.centerZ)^2)
            if dist <= groupDistanceThreshold then
                table.insert(c.members, p)
                c.centerX = (c.centerX + p.x) / 2
                c.centerZ = (c.centerZ + p.z) / 2
                added = true
                break
            end
        end
        if not added then
            table.insert(clusters, {centerX = p.x, centerZ = p.z, members = {p}})
        end
    end
    return clusters
end

-- Desenha a interface toda
local function drawRadar()
    clear()
    
    -- Fundo do Radar (Anéis)
    local maxRadius = math.min(centerX, centerY) - 2
    drawCircle(centerX, centerY, maxRadius, colorRadar)
    drawCircle(centerX, centerY, math.floor(maxRadius / 2), colorRadar)
    
    -- Mira central
    monitor.setTextColor(colorRadar)
    monitor.setCursorPos(centerX, centerY - 1) monitor.write("|")
    monitor.setCursorPos(centerX, centerY + 1) monitor.write("|")
    monitor.setCursorPos(centerX - 1, centerY) monitor.write("-")
    monitor.setCursorPos(centerX + 1, centerY) monitor.write("-")

    -- Botão de Raio (Canto Superior Direito)
    local rangeText = "[Raio: " .. tostring(ranges[currentRangeIdx]) .. "]"
    monitor.setCursorPos(w - string.len(rangeText) + 1, 1)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.gray)
    monitor.write(rangeText)
    monitor.setBackgroundColor(colorBg)

    -- Obter e processar jogadores
    local players = getTargetPlayers()
    -- Agrupa jogadores que estão a menos de 10 blocos uns dos outros
    local clusters = clusterPlayers(players, 10) 
    
    -- Variáveis para a tabela lateral
    local tableRow = h - 1 -- Começa a desenhar de baixo para cima
    local maxMapDist = ranges[currentRangeIdx]
    if maxMapDist == "Inf" then maxMapDist = 2000 end -- Zoom padrão para infinito

    -- Desenhar Pontos e preencher a tabela
    monitor.setTextColor(colorText)
    for _, cluster in ipairs(clusters) do
        -- Escalar as coordenadas para o ecrã
        local relX = (cluster.centerX / maxMapDist) * maxRadius
        local relZ = (cluster.centerZ / maxMapDist) * maxRadius
        
        local screenX = math.floor(centerX + relX)
        local screenY = math.floor(centerY + relZ) -- Z vira Y no ecrã 2D
        
        -- Desenhar o ponto apenas se estiver dentro do ecrã
        if screenX > 0 and screenX <= w and screenY > 0 and screenY <= h then
            monitor.setCursorPos(screenX, screenY)
            monitor.setTextColor(colorDot)
            monitor.write("o")
            
            local label = ""
            if #cluster.members > 1 then
                label = "Grupo"
            else
                label = cluster.members[1].name
            end
            
            monitor.setCursorPos(screenX - math.floor(string.len(label)/2), screenY + 1)
            monitor.setTextColor(colors.white)
            monitor.write(label)
        end
        
        -- Escrever na tabela
        monitor.setTextColor(colorText)
        for _, member in ipairs(cluster.members) do
            if tableRow > 1 then
                monitor.setCursorPos(1, tableRow)
                monitor.write(string.sub(member.name, 1, 10) .. ": " .. member.x .. "," .. member.y .. "," .. member.z)
                tableRow = tableRow - 1
            end
        end
    end
end

-- Ciclo principal
local function main()
    while true do
        drawRadar()
        
        -- Espera por um evento de clique no monitor ou um temporizador para atualizar
        local timer = os.startTimer(1) -- Atualiza a cada 1 segundo (Evita lag no servidor)
        local event, side, x, y = os.pullEvent()
        
        if event == "monitor_touch" then
            -- Verifica se clicou na área do botão superior direito
            local rangeTextLen = string.len("[Raio: " .. tostring(ranges[currentRangeIdx]) .. "]")
            if y == 1 and x >= (w - rangeTextLen) then
                currentRangeIdx = currentRangeIdx + 1
                if currentRangeIdx > #ranges then currentRangeIdx = 1 end
            end
        end
    end
end

-- Inicia o programa
local ok, err = pcall(main)
if not ok then
    print("Erro ou Radar interrompido: ", err)
    monitor.clear()
end
