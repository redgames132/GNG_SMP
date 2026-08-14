-- ==========================================
-- Radar estilo HUD com Agrupamento
-- Requisitos: Advanced Peripherals, Monitor
-- ==========================================

local detector = peripheral.find("playerDetector")
local monitor = peripheral.find("monitor")

if not detector or not monitor then
    print("Erro: Player Detector ou Monitor nao encontrados!")
    return
end

monitor.setTextScale(0.5) -- Deixa os "pixels" menores para mais resolucao
local w, h = monitor.getSize()
local centerX, centerY = math.floor(w / 2), math.floor(h / 2)

-- Configuracoes de Raio
local ranges = {200, 1000, "Inf"}
local currentRangeIdx = 1

-- Cores baseadas na sua imagem de referencia
local colorBg = colors.black
local colorRadar = colors.green
local colorDot = colors.lime
local colorText = colors.lightGray

-- Limpa e prepara o monitor
local function clear()
    monitor.setBackgroundColor(colorBg)
    monitor.clear()
end

-- Desenha um circulo simples (anéis do radar)
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

-- Busca os jogadores baseados na configuracao
local function getTargetPlayers()
    local players = {}
    local maxDist = ranges[currentRangeIdx]
    
    local list = {}
    if maxDist == "Inf" then
        list = detector.getOnlinePlayers()
    else
        list = detector.getPlayersInRange(maxDist)
    end

    local radarPos = {x = 0, y = 0, z = 0} -- Centro virtual
    -- Opcional: Se quiser que o centro seja o detector, descomente abaixo se a API suportar
    -- local centerCoords = detector.getPlayerPos(list[1]) 

    for _, name in ipairs(list) do
        local pos = detector.getPlayerPos(name)
        if pos then
            table.insert(players, {name = name, x = math.floor(pos.x), y = math.floor(pos.y), z = math.floor(pos.z)})
        end
    end
    return players
end

-- Agrupa jogadores proximos
local function clusterPlayers(players, groupDistanceThreshold)
    local clusters = {}
    for _, p in ipairs(players) do
        local added = false
        for _, c in ipairs(clusters) do
            -- Calcula distancia plana (X e Z)
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
    
    -- Fundo do Radar (Aneis)
    local maxRadius = math.min(centerX, centerY) - 2
    drawCircle(centerX, centerY, maxRadius, colorRadar)
    drawCircle(centerX, centerY, math.floor(maxRadius / 2), colorRadar)
    
    -- Mira central
    monitor.setTextColor(colorRadar)
    monitor.setCursorPos(centerX, centerY - 1) monitor.write("|")
    monitor.setCursorPos(centerX, centerY + 1) monitor.write("|")
    monitor.setCursorPos(centerX - 1, centerY) monitor.write("-")
    monitor.setCursorPos(centerX + 1, centerY) monitor.write("-")

    -- Botao de Raio (Topo Direito)
    local rangeText = "[Raio: " .. tostring(ranges[currentRangeIdx]) .. "]"
    monitor.setCursorPos(w - string.len(rangeText) + 1, 1)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.gray)
    monitor.write(rangeText)
    monitor.setBackgroundColor(colorBg)

    -- Obter e processar jogadores
    local players = getTargetPlayers()
    -- Agrupa jogadores que estao a menos de 10 blocos um do outro
    local clusters = clusterPlayers(players, 10) 
    
    -- Variaveis para a tabela lateral
    local tableRow = h - 6 -- Comeca a desenhar de baixo para cima
    local maxMapDist = ranges[currentRangeIdx]
    if maxMapDist == "Inf" then maxMapDist = 2000 end -- Zoom padrao pro infinito

    -- Desenhar Pontos e preencher tabela
    monitor.setTextColor(colorText)
    for _, cluster in ipairs(clusters) do
        -- Escalar coordenadas para a tela
        local relX = (cluster.centerX / maxMapDist) * maxRadius
        local relZ = (cluster.centerZ / maxMapDist) * maxRadius
        
        local screenX = math.floor(centerX + relX)
        local screenY = math.floor(centerY + relZ) -- Z vira Y na tela 2D
        
        -- Desenhar ponto apenas se estiver dentro da tela
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
                monitor.write(string.sub(member.name, 1, 10) .. ": " .. member.x .. ", " .. member.y .. ", " .. member.z)
                tableRow = tableRow - 1
            end
        end
    end
end

-- Loop principal
local function main()
    while true do
        drawRadar()
        
        -- Espera por evento de clique no monitor ou temporizador para atualizar
        local timer = os.startTimer(1) -- Atualiza a cada 1 segundo (Evita lag)
        local event, side, x, y = os.pullEvent()
        
        if event == "monitor_touch" then
            -- Verifica se clicou na area do botao superior direito
            local rangeTextLen = string.len("[Raio: " .. tostring(ranges[currentRangeIdx]) .. "]")
            if y == 1 and x >= (w - rangeTextLen) then
                currentRangeIdx = currentRangeIdx + 1
                if currentRangeIdx > #ranges then currentRangeIdx = 1 end
            end
        end
    end
end

-- Inicia o programa com captura de erro limpa
local ok, err = pcall(main)
if not ok then
    print("Erro ou Radar interrompido: ", err)
    monitor.clear()
end
