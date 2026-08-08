-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (DEFESA)
-- UI Nano + Sistema de Aliados e Alarme
-- ==========================================

local hud = peripheral.find("hud_glasses")
local detector = peripheral.find("player_detector")
local speaker = peripheral.find("speaker") -- NECESSÁRIO PARA O SOM!

if not hud then
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.red)
    print("ERRO CRITICO: HUD Modem nao encontrado!")
    return
end

hud.setSize(100, 50) -- Resolução que deixa a UI pequena

-- ==========================================
-- CONFIGURAÇÕES (MUDE AQUI)
-- ==========================================
local meuNick = "SEU_NICK_AQUI"
local raioAlerta = 100

-- Lista do seu Time (Coloque os nicks dos seus amigos como true)
local aliados = {
    [meuNick] = true,
    ["AMIGO_1"] = true,
    ["AMIGO_2"] = true
}

local baseX, baseY, baseZ = -573, 57, -1446

-- Cores
local C_FUNDO = 0
local C_VERMELHO = colors.red
local C_CINZA = colors.gray
local C_BRANCO = colors.white
local C_ALERTA = colors.orange
local C_CYAN = colors.cyan
local C_VERDE = colors.lime

local lastX, lastY, lastZ = nil, nil, nil
local speed, speedTicks = 0, 0
local compass = "-"
local frame = 0

local function formatTime(t)
    local hora = math.floor(t)
    local min = math.floor((t - hora) * 60)
    return string.format("%02d:%02d", hora, min)
end

local function getDirection(dx, dz)
    if dx == 0 and dz == 0 then return compass end
    if math.abs(dx) > math.abs(dz) then return dx > 0 and "LESTE" or "OESTE"
    else return dz > 0 and "SUL" or "NORTE" end
end

local function drawHUD()
    hud.setBackgroundColour(C_FUNDO)
    hud.clear()

    local myX, myY, myZ = baseX, baseY, baseZ
    local totalPlayers = 0
    local players = {}
    local inimigosProximos = 0
    
    if detector then
        local sucMyPos, myPos = pcall(detector.getPlayerPos, meuNick)
        -- CORREÇÃO DA LINHA 71: type(myPos) == "table" previne o crash!
        if sucMyPos and type(myPos) == "table" and myPos.x then
            myX, myY, myZ = math.floor(myPos.x), math.floor(myPos.y), math.floor(myPos.z)
            
            if lastX == nil then lastX, lastY, lastZ = myX, myY, myZ end
            speedTicks = speedTicks + 1
            if speedTicks >= 4 then 
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

    local distBase = math.floor(math.sqrt((myX - baseX)^2 + (myY - baseY)^2 + (myZ - baseZ)^2))

    -- LINHA 1
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

    -- LINHA 2
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

    -- LINHAS 3+ (Radar)
    if detector then
        local row = 4
        
        -- Conta inimigos e dispara alarme
        for _, p in ipairs(players) do
            if not aliados[p] then
                local sP, pos = pcall(detector.getPlayerPos, p)
                if sP and type(pos) == "table" and pos.x then
                    local dx, dy, dz = pos.x - myX, pos.y - myY, pos.z - myZ
                    if math.floor(math.sqrt(dx*dx + dy*dy + dz*dz)) <= raioAlerta then
                        inimigosProximos = inimigosProximos + 1
                    end
                end
            end
        end

        -- Alarme Sonoro (Apita a cada 1 segundo se tiver inimigo e Speaker conectado)
        if inimigosProximos > 0 and speaker and (frame % 4 == 0) then
            speaker.playNote("bell", 3, 12) -- Toca um sino agudo
        end

        -- Cabeçalho do Radar
        hud.setCursorPos(1, 3)
        hud.setTextColour(C_VERMELHO)
        hud.write("RADAR(" .. raioAlerta .. "m) [")
        hud.setTextColour(inimigosProximos > 0 and C_VERMELHO or C_VERDE)
        hud.write(inimigosProximos > 0 and "INVASOR DETECTADO" or "SEGURO")
        hud.setTextColour(C_VERMELHO)
        hud.write("]")

        -- Desenha jogadores
        local mostrados = 0
        for _, p in ipairs(players) do
            if p ~= meuNick then
                local sP, pos = pcall(detector.getPlayerPos, p)
                if sP and type(pos) == "table" and pos.x then
                    local dx, dy, dz = pos.x - myX, pos.y - myY, pos.z - myZ
                    local dist = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                    
                    hud.setCursorPos(1, row)
                    
                    if dist <= raioAlerta then
                        if aliados[p] then
                            hud.setTextColour(C_VERDE)
                            hud.write(" + " .. p .. " (" .. dist .. "m)")
                        else
                            hud.setTextColour(C_ALERTA)
                            hud.write(" ! " .. p .. " (" .. dist .. "m)")
                        end
                        row = row + 1
                        mostrados = mostrados + 1
                    elseif mostrados < 3 then 
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
-- LOOP PRINCIPAL
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.red)
print("RED_INDUSTRIES HUD - SISTEMA DE DEFESA")
term.setTextColor(colors.white)
print(" > Alarme sonoro pronto (Requer Speaker).")
print(" > Aliados configurados.")
print(" > Pressione [Q] para SAIR.")

local running = true
local timer = os.startTimer(0.25)

while running do
    local event, p1 = os.pullEvent()

    if event == "timer" and p1 == timer then
        drawHUD()
        frame = frame + 1
        timer = os.startTimer(0.25)
    elseif event == "key" then
        if p1 == keys.q then
            running = false
        end
    end
end

hud.setBackgroundColour(C_FUNDO)
hud.clear()
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.lime)
print("HUD encerrado.")
