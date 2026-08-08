-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (NANO)
-- Resolucao aumentada = Letras menores!
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
-- O SEGREDO DO TAMANHO (RESOLUÇÃO)
-- Aumentar a resolução faz as letras encolherem na sua tela!
-- Se ficar MUITO pequeno, mude para (80, 40).
-- ==========================================
hud.setSize(100, 50)

-- ==========================================
-- CONFIGURAÇÕES 
-- ==========================================
local meuNick = "redgames132" -- NÃO ESQUEÇA DE MUDAR!
local raioAlerta = 50

-- Coordenadas do Centro da sua Base
local baseX, baseY, baseZ = -573, 57, -1446

-- Cores
local C_FUNDO = 0
local C_VERMELHO = colors.red
local C_CINZA = colors.gray
local C_BRANCO = colors.white
local C_ALERTA = colors.orange
local C_CYAN = colors.cyan
local C_VERDE = colors.lime

-- Sistema de Rastreamento (Velocidade e Bússola)
local lastX, lastY, lastZ = nil, nil, nil
local speed = 0
local speedTicks = 0
local compass = "-"

local function formatTime(t)
    local hora = math.floor(t)
    local min = math.floor((t - hora) * 60)
    return string.format("%02d:%02d", hora, min)
end

-- Função que descobre para onde você está andando
local function getDirection(dx, dz)
    if dx == 0 and dz == 0 then return compass end
    if math.abs(dx) > math.abs(dz) then
        return dx > 0 and "LESTE" or "OESTE"
    else
        return dz > 0 and "SUL" or "NORTE"
    end
end

local function drawHUD()
    hud.setBackgroundColour(C_FUNDO)
    hud.clear()

    local myX, myY, myZ = baseX, baseY, baseZ
    local totalPlayers = 0
    local players = {}
    local ameaças = 0
    
    if detector then
        local sucMyPos, myPos = pcall(detector.getPlayerPos, meuNick)
        if sucMyPos and myPos and myPos.x then
            myX, myY, myZ = math.floor(myPos.x), math.floor(myPos.y), math.floor(myPos.z)
            
            -- Atualiza Velocidade e Direção
            if lastX == nil then lastX, lastY, lastZ = myX, myY, myZ end
            speedTicks = speedTicks + 1
            if speedTicks >= 4 then -- Atualiza a cada 1 segundo
                local dx, dy, dz = myX - lastX, myY - lastY, myZ - lastZ
                speed = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                if speed > 0 then compass = getDirection(dx, dz) end
                
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

    -- Calcula a distância até a sua base
    local distBase = math.floor(math.sqrt((myX - baseX)^2 + (myY - baseY)^2 + (myZ - baseZ)^2))

    -- ==========================================
    -- LINHA 1: Red OS | Bússola | Hora
    -- ==========================================
    hud.setCursorPos(1, 1)
    hud.setTextColour(C_VERMELHO)
    hud.write("[RED_OS] ")
    hud.setTextColour(C_CINZA)
    hud.write("DIR: ")
    hud.setTextColour(C_CYAN)
    hud.write(compass)
    hud.setTextColour(C_CINZA)
    hud.write(" | MC: ")
    hud.setTextColour(C_BRANCO)
    hud.write(formatTime(os.time()))

    -- ==========================================
    -- LINHA 2: Coord | Vel | Distância da Base
    -- ==========================================
    hud.setCursorPos(1, 2)
    hud.setTextColour(C_CINZA)
    hud.write("XYZ: ")
    hud.setTextColour(C_BRANCO)
    hud.write(myX .. " " .. myY .. " " .. myZ)
    hud.setTextColour(C_CINZA)
    hud.write(" | VEL: ")
    hud.setTextColour(C_BRANCO)
    hud.write(speed .. "b/s")
    hud.setTextColour(C_CINZA)
    hud.write(" | BASE: ")
    hud.setTextColour(C_ALERTA)
    hud.write(distBase .. "m")

    -- ==========================================
    -- LINHAS 3+: Radar Dinâmico
    -- ==========================================
    if detector then
        local row = 4
        
        -- Primeiro verifica as ameaças antes de desenhar
        for _, p in ipairs(players) do
            if p ~= meuNick then
                local sP, pos = pcall(detector.getPlayerPos, p)
                if sP and pos and pos.x then
                    local dx, dy, dz = pos.x - myX, pos.y - myY, pos.z - myZ
                    if math.floor(math.sqrt(dx*dx + dy*dy + dz*dz)) <= raioAlerta then
                        ameaças = ameaças + 1
                    end
                end
            end
        end

        -- Cabeçalho do Radar
        hud.setCursorPos(1, 3)
        hud.setTextColour(C_VERMELHO)
        hud.write("RADAR(" .. raioAlerta .. "m) [")
        hud.setTextColour(ameaças > 0 and C_VERMELHO or C_VERDE)
        hud.write(ameaças > 0 and "ALERTA" or "SEGURO")
        hud.setTextColour(C_VERMELHO)
        hud.write("]")

        -- Desenha os jogadores
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
                        row = row + 1
                        mostrados = mostrados + 1
                    elseif mostrados < 3 then 
                        -- Mostra no máximo 3 pessoas longe só para não ficar vazio
                        hud.setTextColour(C_CINZA)
                        hud.write(" - " .. p .. " (" .. dist .. "m)")
                        row = row + 1
                        mostrados = mostrados + 1
                    end
                    
                    if mostrados >= 5 then break end
                end
            end
        end
    end
end

-- ==========================================
-- LOOP PRINCIPAL (TECLA Q PARA SAIR)
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.red)
print("RED_INDUSTRIES HUD - ALTA RESOLUCAO")
term.setTextColor(colors.white)
print(" > Fonte reduzida e painel encolhido.")
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
print("HUD encerrado.")
