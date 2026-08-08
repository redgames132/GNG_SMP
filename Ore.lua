-- ==========================================
-- RED_INDUSTRIES - POCKET SCANNER AUTO
-- ==========================================

local scanner = peripheral.find("geo_scanner") or peripheral.find("geoScanner")

if not scanner then
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.red)
    print("ERRO CRITICO:")
    term.setTextColor(colors.white)
    print("Geo Scanner nao detectado no Pocket!")
    return
end

local radius = 8 -- Raio padrão do Scanner (altere se tiver upgrade)
local ores = {}
local status = "INICIANDO SISTEMA..."
local w, h = term.getSize()

-- Centraliza no espaço livre da tela (descontando as 2 linhas de baixo)
local cx = math.floor(w / 2)
local cy = math.floor((h - 2) / 2) 

local function getOreColor(name)
    local n = string.lower(name)
    if string.find(n, "diamond") then return colors.cyan end
    if string.find(n, "emerald") then return colors.lime end
    if string.find(n, "gold") then return colors.yellow end
    if string.find(n, "iron") then return colors.orange end
    if string.find(n, "copper") then return colors.brown end
    if string.find(n, "redstone") then return colors.red end
    if string.find(n, "lapis") then return colors.blue end
    if string.find(n, "coal") then return colors.gray end
    if string.find(n, "debris") then return colors.magenta end
    if string.find(n, "quartz") then return colors.white end
    if string.find(n, "zinc") then return colors.lightGray end
    if string.find(n, "osmium") then return colors.lightBlue end
    if string.find(n, "uranium") then return colors.green end
    return colors.lightGray
end

local function drawRadar()
    term.setBackgroundColor(colors.black)
    term.clear()

    -- 1. Centro (Sua Posição)
    term.setCursorPos(cx, cy)
    term.setTextColor(colors.white)
    term.write("X")

    -- 2. Desenhar Minérios (Tela Cheia)
    for _, b in ipairs(ores) do
        -- Escala X expandida para aproveitar a largura da tela do pocket
        local px = cx + math.floor(b.x * 1.5)
        local py = cy + b.z
        
        -- Desenha apenas se estiver dentro da área livre do mapa
        if px >= 1 and px <= w and py >= 1 and py <= h - 2 then
            if not (px == cx and py == cy) then
                term.setCursorPos(px, py)
                term.setBackgroundColor(getOreColor(b.name))
                term.write(" ") 
            end
        end
    end
    
    term.setBackgroundColor(colors.black)

    -- 3. Explicações e Legenda no Fundo
    term.setCursorPos(1, h - 1)
    term.setTextColor(colors.lightGray)
    term.write(" [Q] Sair | Raio: " .. radius .. "m ")
    
    -- 4. Barra de Status Dinâmica
    term.setCursorPos(1, h)
    term.write(string.rep(" ", w)) -- Limpa a linha
    term.setCursorPos(1, h)
    
    if string.find(status, "ERRO") then
        term.setTextColor(colors.red)
    elseif string.find(status, "CONCLUIDO") then
        term.setTextColor(colors.lime)
    else
        term.setTextColor(colors.yellow)
    end
    term.write(status)
end

local function doScan()
    local res, err
    local success = pcall(function()
        if scanner.scanBlocks then
            res, err = scanner.scanBlocks(radius)
        elseif scanner.scan then
            res, err = scanner.scan(radius)
        end
    end)
    
    if success and res then
        ores = {}
        for _, b in ipairs(res) do
            if string.find(b.name, "ore") or string.find(b.name, "debris") then
                table.insert(ores, b)
            end
        end
        status = "CONCLUIDO: " .. #ores .. " encontrados"
    else
        -- Geralmente erro de Cooldown por escanear rápido demais
        status = "ERRO: " .. (err or "Recarregando...") 
    end
    drawRadar()
end

-- ==========================================
-- GERENCIADOR DE EVENTOS (AUTOMÁTICO)
-- ==========================================
local running = true
-- Dispara o primeiro scan imediatamente (0 segundos)
local scanTimer = os.startTimer(0) 

drawRadar()

while running do
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "timer" and p1 == scanTimer then
        doScan()
        -- Configura o próximo scan para 1.5s depois para não bugar o mod
        scanTimer = os.startTimer(1.5)
        
    elseif event == "key" then
        if p1 == keys.q then
            running = false
        end
    end
end

-- Desliga
term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.green)
print("Scanner Red_Industries encerrado.")
