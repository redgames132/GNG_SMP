-- ==========================================
-- RED_INDUSTRIES - POCKET ORE SCANNER (VISUAL LIMPO)
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

local radius = 8
local ores = {}
local status = "AGUARDANDO COMANDO..."
local w, h = term.getSize()
local cx = math.floor(w / 2)
local cy = 9

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
    return colors.lightGray -- Cor padrão para outros minérios
end

local function drawRadar()
    -- Fundo preto limpo
    term.setBackgroundColor(colors.black)
    term.clear()

    -- 1. Barra de Título
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.red)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    term.write("RED_INDUSTRIES SCANNER")
    term.setBackgroundColor(colors.black)

    -- 2. Centro (Sua Posição)
    term.setCursorPos(cx, cy)
    term.setTextColor(colors.white)
    term.write("X")

    -- 3. Desenhar Minérios como Cubos Coloridos
    for _, b in ipairs(ores) do
        local px = cx + math.floor(b.x * 1.5)
        local py = cy + b.z
        
        -- Garante que o cubo vai ser desenhado dentro da tela livre
        if px >= 1 and px <= w and py >= 2 and py <= h - 2 then
            -- Não desenha por cima do "X" do jogador
            if not (px == cx and py == cy) then
                term.setCursorPos(px, py)
                -- O segredo do cubo: Muda a cor do fundo e escreve um espaço vazio!
                term.setBackgroundColor(getOreColor(b.name))
                term.write(" ") 
            end
        end
    end
    -- Reseta o fundo para preto antes de desenhar os menus
    term.setBackgroundColor(colors.black)

    -- 4. Interface (Botão)
    term.setCursorPos(1, h - 1)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.yellow)
    term.write(string.rep(" ", w))
    local txtBtn = "[ ESCANEAR ]"
    term.setCursorPos(math.floor((w - #txtBtn)/2) + 1, h - 1)
    term.write(txtBtn)
    term.setBackgroundColor(colors.black)

    -- 5. Barra de Status
    term.setCursorPos(1, h)
    term.write(string.rep(" ", w))
    term.setCursorPos(1, h)
    
    if string.find(status, "ERRO") then
        term.setTextColor(colors.red)
    elseif string.find(status, "CONCLUIDO") then
        term.setTextColor(colors.lime)
    else
        term.setTextColor(colors.white)
    end
    term.write(status)
end

local function doScan()
    status = "ESCANEANDO..."
    drawRadar()
    
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
            -- Filtra tudo que for minério (ore) ou detritos (debris) no sistema
            if string.find(b.name, "ore") or string.find(b.name, "debris") then
                table.insert(ores, b)
            end
        end
        status = "CONCLUIDO: " .. #ores .. " encontrados"
    else
        status = "ERRO: " .. (err or "Falha no Scanner")
    end
    drawRadar()
end

-- ==========================================
-- GERENCIADOR DE ENTRADAS (TOUCH E TECLADO)
-- ==========================================
local running = true
drawRadar()

while running do
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "mouse_click" then
        local clickX, clickY = p2, p3
        -- Se clicar na linha do botão
        if clickY == h - 1 then
            doScan()
        end
    elseif event == "key" then
        -- Tecla Q para sair
        if p1 == keys.q then
            running = false
        -- Espaço ou Enter para escanear
        elseif p1 == keys.enter or p1 == keys.space then
            doScan()
        end
    end
end

-- Limpa a tela ao fechar
term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.green)
print("Scanner Red_Industries encerrado.")
