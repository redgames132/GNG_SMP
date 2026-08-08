-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (MICRO)
-- Mais funcoes, menos espaco na tela!
-- ==========================================

local hud = peripheral.find("hud_glasses")
local detector = peripheral.find("player_detector")

if not hud then
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.red)
    print("ERRO CRITICO: HUD Modem nao encontrado!")
    return
end

-- ==========================================
-- CONFIGURAÇÕES (MUDE O SEU NICK AQUI)
-- ==========================================
local meuNick = "redgames132" -- Substitua pelo seu nick exato!
local raioAlerta = 50

-- Cores Táticas
local C_FUNDO = 0
local C_VERMELHO = colors.red
local C_CINZA = colors.gray
local C_BRANCO = colors.white
local C_ALERTA = colors.orange
local C_CYAN = colors.cyan

-- Sistema de Velocímetro
local lastX, lastY, lastZ = nil, nil, nil
local speed = 0
local speedTicks = 0

local function formatTime(t)
    local hora = math.floor(t)
    local min = math.floor((t - hora) * 60)
    return string.format("%02d:%02d", hora, min)
end

local function drawHUD()
    hud.setBackgroundColour(C_FUNDO)
    hud.clear()

    -- Puxa as suas coordenadas
    local myX, myY, myZ = -573, 57, -1446
    local totalPlayers = 0
    local players = {}
    
    if detector then
        local sucMyPos, myPos = pcall(detector.getPlayerPos, meuNick)
        if sucMyPos and myPos and myPos.x then
            myX, myY, myZ = math.floor(myPos.x), math.floor(myPos.y), math.floor(myPos.z)
            
            -- Lógica do Velocímetro (Atualiza a cada 1 segundo = 4 ticks de 0.25s)
            if lastX == nil then lastX, lastY, lastZ = myX, myY, myZ end
            speedTicks = speedTicks + 1
            if speedTicks >= 4 then
                local dx, dy, dz = myX - lastX, myY - lastY, myZ - lastZ
                speed = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                lastX, lastY, lastZ = myX, myY, myZ
                speedTicks = 0
            end
        end
        
        local suc, pList = pcall(detector.getOnlinePlayers)
        if suc and type(pList) == "table" then
            players = pList
            totalPlayers = #players
        end
    end

    -- ==========================================
    -- LINHA 1: Título, Hora Real e Hora Minecraft
    -- ==========================================
    hud.setCursorPos(1, 1)
    hud.setTextColour(C_VERMELHO)
    hud.write("[RED_OS] ")
    hud.setTextColour(C_CINZA)
    hud.write("IRL:")
    hud.setTextColour(C_BRANCO)
    hud.write(os.date("%H:%M")) -- Hora do Mundo Real
    hud.setTextColour(C_CINZA)
    hud.write(" MC:")
    hud.setTextColour(C_BRANCO)
    hud.write(formatTime(os.time()))

    -- ==========================================
    -- LINHA 2: Coordenadas e Velocidade
    -- ==========================================
    hud.setCursorPos(1, 2)
    hud.setTextColour(C_CINZA)
    hud.write("XYZ: ")
    hud.setTextColour(C_CYAN)
    hud.write(myX .. " " .. myY .. " " .. myZ)
    hud.setTextColour(C_CINZA)
    hud.write(" VEL: ")
    hud.setTextColour(C_BRANCO)
    hud.write(speed .. " b/s")

    -- ==========================================
    -- LINHA 3: Cabeçalho do Radar
    -- ==========================================
    hud.setCursorPos(1, 3)
    hud.setTextColour(C_VERMELHO)
    hud.write("RADAR(" .. raioAlerta .. "m) ")
    hud.setTextColour(C_CINZA)
    hud.write("ON: ")
    hud.setTextColour(C_BRANCO)
    hud.write(tostring(totalPlayers))

    -- ==========================================
    -- LINHAS 4+: Jogadores
    -- ==========================================
    if detector then
        local row = 4
        local mostrados = 0
        
        for _, p in ipairs(players) do
            if p ~= meuNick then
                local sP, pos = pcall(detector.getPlayerPos, p)
                if sP and pos and pos.x then
                    local dx, dy, dz = pos.x - myX, pos.y - myY, pos.z - myZ
                    local dist = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                    
                    hud.setCursorPos(1, row)
                    
                    if dist <= raioAlerta then
                        hud.setTextColour(C_ALERTA)
                        hud.write(" ! " .. p .. " (" .. dist .. "m)")
                    else
                        hud.setTextColour(C_CINZA)
                        hud.write(" - " .. p .. " (" .. dist .. "m)")
                    end
                    
                    row = row + 1
                    mostrados = mostrados + 1
                    if mostrados >= 5 then break end -- Mostra no máximo 5 para não poluir
                end
            end
        end
    end
end

-- ==========================================
-- LOOP PRINCIPAL E TECLA Q
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.red)
print("RED_INDUSTRIES MICRO-HUD")
term.setTextColor(colors.white)
print(" > Transmissao super compacta.")
print(" > Pressione [Q] para SAIR.")

local running = true
local timer = os.startTimer(0.25)

while running do
    local event, p1 = os.pullEvent()

    if event == "timer" and p1 == timer then
        drawHUD()
        timer = os.startTimer(0.25)
    elseif event == "key" then
        if p1 == keys.q then
            running = false
        end
    end
end

-- Limpeza
hud.setBackgroundColour(C_FUNDO)
hud.clear()
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.lime)
print("Micro-HUD encerrado.")
