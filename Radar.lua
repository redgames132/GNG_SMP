-- ==========================================
-- RADAR DE JOGADORES 3D - COMPUTERCRAFT (V4)
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
local meuX = 0  -- Substitua pelo seu X
local meuY = 0  -- Substitua pelo seu Y
local meuZ = 0  -- Substitua pelo seu Z

-- Configurações de Controle
local ranges = {200, 1000, 999999}
local rangeNomes = {"200", "1000", "Inf"}
local rIndex = 1

local speeds = {2, 5, 12}
local speedNomes = {"Lenta", "Normal", "Rapida"}
local sIndex = 2

-- Prepara a Tela e o Buffer
monitor.setTextScale(0.5)
local w, h = monitor.getSize()
local buffer = window.create(monitor, 1, 1, w, h, false)

local cx = math.floor(w / 2)
local cy = math.floor(h / 2) + 1
local radius = math.floor(math.min(cx / 1.5, cy)) - 3
local angle = 0

local function drawRadar()
    buffer.setVisible(false)
    buffer.setBackgroundColor(colors.black)
    buffer.clear()

    -- 1. Barra Superior de Interface (UI)
    buffer.setCursorPos(1, 1)
    buffer.setBackgroundColor(colors.gray)
    buffer.write(string.rep(" ", w)) -- Preenche o fundo cinza

    -- Botão Alcance (Esquerda)
    local txtAlc = " ALC: " .. rangeNomes[rIndex] .. " "
    buffer.setCursorPos(2, 1)
    buffer.setBackgroundColor(colors.gray)
    buffer.setTextColor(colors.yellow)
    buffer.write(txtAlc)

    -- Botão Velocidade (Direita)
    local txtVel = " VEL: " .. speedNomes[sIndex] .. " "
    buffer.setCursorPos(w - #txtVel, 1)
    buffer.setBackgroundColor(colors.gray)
    buffer.setTextColor(colors.cyan)
    buffer.write(txtVel)

    buffer.setBackgroundColor(colors.black)

    -- 2. Rosa dos Ventos (Pontos Cardeais)
    buffer.setTextColor(colors.gray)
    buffer.setCursorPos(cx, math.max(2, cy - radius - 1))
    buffer.write("N")
    buffer.setCursorPos(cx, math.min(h, cy + radius + 1))
    buffer.write("S")
    buffer.setCursorPos(math.min(w, cx + math.floor(radius * 1.5) + 1), cy)
    buffer.write("L")
    buffer.setCursorPos(math.max(1, cx - math.floor(radius * 1.5) - 1), cy)
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

    -- 4. Centro (Sua Posição)
    buffer.setCursorPos(cx, cy)
    buffer.setTextColor(colors.white)
    buffer.write("X")

    -- 5. Linha de Varredura Suave
    for offset = 0, 2 do
        local sweepRad = math.rad(angle - (offset * 2))
        local col = (offset == 0) and colors.lime or colors.green
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

    -- 6. Detecção e Posição dos Jogadores
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
                        
                        -- Nome
                        buffer.setCursorPos(math.max(1, px - math.floor(#nome / 2)), pz + 1)
                        buffer.setTextColor(colors.white)
                        buffer.write(nome)
                        
                        -- Distância
                        local distText = math.floor(dist) .. "m"
                        buffer.setCursorPos(math.max(1, px - math.floor(#distText / 2)), pz + 2)
                        buffer.setTextColor(colors.lightGray)
                        buffer.write(distText)
                    end
                end
            end
        end
    end

    buffer.setVisible(true)
end

-- ==========================================
-- LOOP DE EVENTOS (GERENCIAMENTO DE ENTRADAS)
-- ==========================================

term.clear()
term.setCursorPos(1, 1)
print("--------------------------------------")
print(" RADAR ATIVO")
print(" - Clique na barra superior do monitor")
print(" - Pressione [F] no computador p/ sair")
print("--------------------------------------")

local running = true
local myTimer = os.startTimer(0.05)

while running do
    local event, p1, p2, p3 = os.pullEvent()

    -- 1. Atualização do Frame da Animação
    if event == "timer" and p1 == myTimer then
        angle = (angle + speeds[sIndex]) % 360
        drawRadar()
        myTimer = os.startTimer(0.05) -- Inicia o próximo timer sincronizado

    -- 2. Clique no Monitor
    elseif event == "monitor_touch" then
        local clickX, clickY = p2, p3
        
        -- Clicou na barra superior (linha 1)
        if clickY == 1 then
            local meio = math.floor(w / 2)
            if clickX <= meio then
                -- Lado Esquerdo -> Alcance
                rIndex = rIndex + 1
                if rIndex > #ranges then rIndex = 1 end
            else
                -- Lado Direito -> Velocidade
                sIndex = sIndex + 1
                if sIndex > #speeds then sIndex = 1 end
            end
            drawRadar() -- Força a atualização visual imediata ao clicar
        end

    -- 3. Tecla Pressionada no Computador
    elseif event == "key" then
        if p1 == keys.f then
            running = false
        end
    end
end

-- ==========================================
-- FINALIZAÇÃO E LIMPEZA
-- ==========================================
monitor.setBackgroundColor(colors.black)
monitor.clear()
monitor.setCursorPos(1, 1)
monitor.setTextColor(colors.red)
monitor.write("RADAR DESLIGADO")

term.setBackgroundColor(colors.black)
term.setTextColor(colors.yellow)
print("\nRadar encerrado com sucesso!")
