-- ==========================================
-- RADAR DE JOGADORES 3D - COMPUTERCRAFT (V5)
-- UI Profissional e Cliques Corrigidos
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
-- CONFIGURAÇÕES DA SUA BASE (MUDE AQUI)
-- ==========================================
local meuX = -573
local meuY = 57
local meuZ = -1446

-- Configurações
local ranges = {200, 1000, 999999}
local rangeNomes = {"200m", "1000m", "Infin"}
local rIndex = 1

local speeds = {2, 5, 12}
local speedNomes = {"Lenta", "Normal", "Rapida"}
local sIndex = 2

-- Tela e Buffer
monitor.setTextScale(0.5)
local w, h = monitor.getSize()
local buffer = window.create(monitor, 1, 1, w, h, false)

-- Centro reajustado por conta dos botões grandes
local cx = math.floor(w / 2)
local cy = math.floor(h / 2) + 2
local radius = math.floor(math.min(cx / 1.5, cy)) - 4
local angle = 0

local function drawRadar()
    buffer.setVisible(false)
    buffer.setBackgroundColor(colors.black)
    buffer.clear()

    local meio = math.floor(w / 2)

    -- ==========================================
    -- 1. UI - BOTOES DE CONTROLE (CAIXAS GRANDES)
    -- ==========================================
    
    -- Botão Esquerdo (ALCANCE)
    for y = 1, 2 do
        buffer.setCursorPos(1, y)
        buffer.setBackgroundColor(colors.gray)
        buffer.write(string.rep(" ", meio))
    end
    buffer.setCursorPos(2, 1)
    buffer.setTextColor(colors.white)
    buffer.write("ALCANCE:")
    buffer.setCursorPos(2, 2)
    buffer.setTextColor(colors.yellow)
    buffer.write("> " .. rangeNomes[rIndex] .. " <")

    -- Botão Direito (VELOCIDADE)
    local startX = meio + 1
    local widthRight = w - meio
    for y = 1, 2 do
        buffer.setCursorPos(startX, y)
        buffer.setBackgroundColor(colors.lightGray)
        buffer.write(string.rep(" ", widthRight))
    end
    buffer.setCursorPos(startX + 1, 1)
    buffer.setTextColor(colors.black)
    buffer.write("VELOCIDADE:")
    buffer.setCursorPos(startX + 1, 2)
    buffer.setTextColor(colors.cyan)
    buffer.write("> " .. speedNomes[sIndex] .. " <")

    buffer.setBackgroundColor(colors.black)

    -- ==========================================
    -- 2. DESENHO DO RADAR E LINHAS
    -- ==========================================
    
    -- Rosa dos Ventos
    buffer.setTextColor(colors.gray)
    buffer.setCursorPos(cx, math.max(4, cy - radius - 1))
    buffer.write("N")
    buffer.setCursorPos(cx, math.min(h, cy + radius + 1))
    buffer.write("S")
    buffer.setCursorPos(math.min(w, cx + math.floor(radius * 1.5) + 1), cy)
    buffer.write("L")
    buffer.setCursorPos(math.max(1, cx - math.floor(radius * 1.5) - 1), cy)
    buffer.write("O")

    -- Círculo Principal
    buffer.setTextColor(colors.green)
    for i = 0, 359, 10 do
        local rad = math.rad(i)
        local x = cx + math.floor(math.cos(rad) * radius * 1.5) 
        local y = cy + math.floor(math.sin(rad) * radius)
        if x >= 1 and x <= w and y >= 4 and y <= h then
            buffer.setCursorPos(x, y)
            buffer.write(".")
        end
    end

    -- Centro
    buffer.setCursorPos(cx, cy)
    buffer.setTextColor(colors.white)
    buffer.write("X")

    -- Linha de Varredura
    for offset = 0, 2 do
        local sweepRad = math.rad(angle - (offset * 2))
        local col = (offset == 0) and colors.lime or colors.green
        buffer.setTextColor(col)
        
        for r = 1, radius do
            local x = cx + math.floor(math.cos(sweepRad) * r * 1.5)
            local y = cy + math.floor(math.sin(sweepRad) * r)
            if x >= 1 and x <= w and y >= 4 and y <= h and not (x == cx and y == cy) then
                buffer.setCursorPos(x, y)
                buffer.write(offset == 0 and "+" or ".")
            end
        end
    end

    -- ==========================================
    -- 3. JOGADORES NO MAPA
    -- ==========================================
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

                    if px >= 1 and px <= w and pz >= 4 and pz <= h then
                        buffer.setCursorPos(px, pz)
                        buffer.setTextColor(colors.red)
                        buffer.write("O")
                        
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

    buffer.setVisible(true)
end

-- ==========================================
-- GERENCIADOR DE EVENTOS (ROBUSTO)
-- ==========================================

term.clear()
term.setCursorPos(1, 1)
print("======================================")
print(" RADAR INICIADO - SISTEMA ATIVO")
print("======================================")
print(" > Clique nos blocos no topo da tela")
print(" > Pressione [F] aqui para desligar")

local running = true
local updateTimer = os.startTimer(0.05)

while running do
    local event, p1, p2, p3 = os.pullEvent()

    -- Atualiza animação quando o timer estoura
    if event == "timer" and p1 == updateTimer then
        angle = (angle + speeds[sIndex]) % 360
        drawRadar()
        updateTimer = os.startTimer(0.05) 

    -- Detecta o clique instantaneamente
    elseif event == "monitor_touch" then
        local clickX, clickY = p2, p3
        
        -- Hitbox GIGANTE: Clicar em qualquer lugar das 3 primeiras linhas
        if clickY <= 3 then
            local meio = math.floor(w / 2)
            if clickX <= meio then
                rIndex = rIndex + 1
                if rIndex > #ranges then rIndex = 1 end
            else
                sIndex = sIndex + 1
                if sIndex > #speeds then sIndex = 1 end
            end
            
            -- Desenha a mudança imediatamente
            drawRadar()
        end

    -- Desliga o radar ao apertar F
    elseif event == "key" then
        if p1 == keys.f then
            running = false
        end
    end
end

-- Finaliza e limpa a tela
monitor.setBackgroundColor(colors.black)
monitor.clear()
monitor.setCursorPos(1, 1)
monitor.setTextColor(colors.red)
monitor.write("SISTEMA DESLIGADO")

term.setBackgroundColor(colors.black)
term.setTextColor(colors.green)
print("\nDesligado com sucesso. Bom jogo!")
