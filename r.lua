-- ==========================================
-- Radar HUD Avançado V2
-- Requisitos: Advanced Peripherals, Monitor
-- ==========================================

local detector = peripheral.wrap("top")
local monitor = peripheral.wrap("left")

if not detector or not monitor then
    print("Erro: Verifique se o detetor esta no topo e o monitor a esquerda!")
    return
end

-- ==========================================
-- CONFIGURAÇÕES IMPORTANTES (Edite aqui!)
-- ==========================================
-- Coloque as coordenadas X e Z exatas de onde esta o seu radar no mundo.
-- Olhando para a sua imagem, parece ser em X = -8500 e Z = -397.
local radarX = -8500
local radarZ = -397

local aspect = 0.65 -- Compensacao para deixar o circulo redondo (nao mexa)
monitor.setTextScale(0.5)

-- Listas de opções
local ranges = {50, 100, 200, 500, 1000, 2000, "Inf"}
local currentRangeIdx = 3 -- Comeca no 200

local speeds = {0.5, 1, 2, 5, 10}
local currentSpeedIdx = 2 -- Comeca em 1 segundo

-- Cores
local colorBg = colors.black
local colorPanelBg = colors.gray
local colorRadar = colors.green
local colorDot = colors.lime
local colorText = colors.white
local colorButton = colors.lightGray

local w, h = monitor.getSize()
local radarSize = math.min(w - 25, h) -- Reserva 25 colunas para o painel esquerdo
local centerX = w - math.floor(radarSize / 2)
local centerY = math.floor(h / 2)
local maxRadiusX = math.floor(radarSize / 2) - 2
local maxRadiusY = math.floor(maxRadiusX * aspect)

local buttons = {}

-- Limpa a tela
local function clear()
    monitor.setBackgroundColor(colorBg)
    monitor.clear()
    buttons = {}
end

-- Função para desenhar botoes clicaveis
local function drawButton(id, x, y, text, bg, fg)
    monitor.setCursorPos(x, y)
    monitor.setBackgroundColor(bg)
    monitor.setTextColor(fg)
    monitor.write(text)
    table.insert(buttons, {id=id, x=x, y=y, len=string.len(text)})
end

-- Desenha um circulo compensando a distorcao da tela
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

-- Busca jogadores
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

-- Interface Grafica
local function drawUI()
    clear()
    
    -- Desenha a divisao do painel
    monitor.setBackgroundColor(colorPanelBg)
    for y = 1, h do
        monitor.setCursorPos(24, y)
        monitor.write(" ")
    end
    monitor.setBackgroundColor(colorBg)

    -- Controlos: Raio
    monitor.setTextColor(colorText)
    monitor.setCursorPos(2, 2) monitor.write("Alcance:")
    drawButton("range_down", 2, 4, "[ - ]", colorButton, colors.black)
    
    local rangeText = tostring(ranges[currentRangeIdx])
    monitor.setCursorPos(9, 4)
    monitor.setBackgroundColor(colorBg)
    monitor.setTextColor(colorText)
    monitor.write(string.rep(" ", 6 - string.len(rangeText)) .. rangeText)
    
    drawButton("range_up", 17, 4, "[ + ]", colorButton, colors.black)

    -- Controlos: Velocidade
    monitor.setTextColor(colorText)
    monitor.setCursorPos(2, 7) monitor.write("Atualizacao (Seg):")
    drawButton("speed_down", 2, 9, "[ - ]", colorButton, colors.black)
    
    local speedText = tostring(speeds[currentSpeedIdx])
    monitor.setCursorPos(9, 9)
    monitor.setBackgroundColor(colorBg)
    monitor.setTextColor(colorText)
    monitor.write(string.rep(" ", 6 - string.len(speedText)) .. speedText)
    
    drawButton("speed_up", 17, 9, "[ + ]", colorButton, colors.black)

    -- Radar de Fundo
    drawCircle(centerX, centerY, maxRadiusX, colorRadar)
    drawCircle(centerX, centerY, math.floor(maxRadiusX / 2), colorRadar)
    
    -- Mira central do radar
    monitor.setTextColor(colors.gray)
    monitor.setCursorPos(centerX, centerY) monitor.write("+")

    -- Jogadores
    local players = getTargetPlayers()
    local tableRow = 12 -- A tabela de nomes comeca na linha 12 do lado esquerdo
    local maxMapDist = ranges[currentRangeIdx]
    if maxMapDist == "Inf" then maxMapDist = 2000 end
    
    monitor.setCursorPos(2, tableRow)
    monitor.setTextColor(colors.yellow)
    monitor.write("SINAIS DETETADOS:")
    tableRow = tableRow + 2

    for _, p in ipairs(players) do
        -- Calcular posicao no ecra em relacao ao centro do radar
        local relX = p.x - radarX
        local relZ = p.z - radarZ
        
        local screenRelX = (relX / maxMapDist) * maxRadiusX
        local screenRelZ = (relZ / maxMapDist) * maxRadiusX * aspect
        
        local screenX = math.floor(centerX + screenRelX)
        local screenY = math.floor(centerY + screenRelZ)
        
        -- Desenhar ponto verde brilhante se estiver dentro do circulo do radar
        if screenX > 25 and screenX <= w and screenY > 0 and screenY <= h then
            monitor.setCursorPos(screenX, screenY)
            monitor.setTextColor(colorDot)
            monitor.write("o")
            
            -- Pequeno nome em cima do ponto
            monitor.setCursorPos(screenX - math.floor(string.len(p.name)/2), screenY - 1)
            monitor.setTextColor(colors.white)
            monitor.write(string.sub(p.name, 1, 5))
        end
        
        -- Adicionar a tabela esquerda (se houver espaco)
        if tableRow <= h then
            monitor.setCursorPos(2, tableRow)
            monitor.setTextColor(colorText)
            monitor.write(string.sub(p.name, 1, 10))
            monitor.setCursorPos(2, tableRow + 1)
            monitor.setTextColor(colors.gray)
            monitor.write("X:" .. p.x .. " Z:" .. p.z)
            tableRow = tableRow + 3
        end
    end
end

-- Função para processar os cliques
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
            return true -- Houve uma alteracao
        end
    end
    return false
end

-- Loop Principal
local function main()
    while true do
        drawUI()
        
        local currentDelay = speeds[currentSpeedIdx]
        local timer = os.startTimer(currentDelay)
        
        while true do
            local event, side, x, y = os.pullEvent()
            
            if event == "timer" and side == timer then
                break -- Sai do mini-loop para redesenhar a UI
            elseif event == "monitor_touch" then
                if handleClick(x, y) then
                    os.cancelTimer(timer)
                    break -- Sai para redesenhar a UI com a nova configuracao imediatamente
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
