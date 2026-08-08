-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (PANORAMIC)
-- Layout Distribuído 4 Cantos + Novas Métricas
-- ==========================================

local hud = peripheral.find("hud_glasses")
local detector = peripheral.find("player_detector")
local speaker = peripheral.find("speaker")

if not hud then
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.red)
    print("ERRO CRITICO: HUD Modem nao encontrado!")
    return
end

-- Mantém a resolução em 100x50 para criar espaço de sobra
hud.setSize(100, 50)
local w, h = hud.getSize()

-- ==========================================
-- CONFIGURAÇÕES DA EQUIPE
-- ==========================================
local meuNick = "redgames132"
local raioAlerta = 100
local baseX, baseY, baseZ = -573, 57, -1446

local aliados = {
    ["redgames132"] = true,
    ["KAIOX_NEGROX"] = true,
    ["goonerstickle69"] = true,
    ["cadipadi"] = true
}

-- Cores Táticas
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
local startTime = os.clock() -- Tempo que o sistema foi ligado

-- Funções Utilitárias
local function formatTime(t)
    local hora = math.floor(t)
    local min = math.floor((t - hora) * 60)
    return string.format("%02d:%02d", hora, min)
end

local function formatUptime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

local function getDirection(dx, dz)
    if dx == 0 and dz == 0 then return compass end
    if math.abs(dx) > math.abs(dz) then return dx > 0 and "LESTE" or "OESTE"
    else return dz > 0 and "SUL" or "NORTE" end
end

-- ==========================================
-- DESENHO DO HUD PANORÂMICO
-- ==========================================
local function drawHUD()
    hud.setBackgroundColour(C_FUNDO)
    hud.clear()

    local myX, myY, myZ = baseX, baseY, baseZ
    local players = {}
    local inimigosProximos = 0
    local distBase = 0
    
    -- Leitura dos Sensores
    if detector then
        local sucMyPos, myPos = pcall(detector.getPlayerPos, meuNick)
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
        if suc and type(pList) == "table" then players = pList end
    end

    distBase = math.floor(math.sqrt((myX - baseX)^2 + (myY - baseY)^2 + (myZ - baseZ)^2))
    
    -- Pré-cálculo de Ameaças
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

    -- Disparo da Sirene (Wither + Ghast no max)
    if inimigosProximos > 0 and speaker then
        if frame % 8 == 0 then
            speaker.playSound("entity.wither.spawn", 3.0, 0.5)
        elseif frame % 8 == 4 then
            speaker.playSound("block.bell.resonate", 3.0, 0.5)
            speaker.playSound("entity.ghast.scream", 3.0, 0.6)
        end
    end

    -- Efeitos Visuais
    local hexCode = string.format("0x%04X", math.random(0, 65535))
    local isAlerta = inimigosProximos > 0
    local colorTheme = isAlerta and C_VERMELHO or C_CYAN
    local blink = frame % 2 == 0

    -- ==========================================
    -- 1. CANTO SUPERIOR ESQUERDO (RADAR E COMBATE)
    -- ==========================================
    hud.setCursorPos(1, 1)
    hud.setTextColour(C_VERMELHO)
    hud.write("+--[ ")
    hud.setTextColour(C_BRANCO)
    hud.write("RADAR TÁTICO (" .. raioAlerta .. "m)")
    hud.setTextColour(C_VERMELHO)
    hud.write(" ]")

    local row = 2
    local mostrados = 0
    for _, p in ipairs(players) do
        if p ~= meuNick then
            local sP, pos = pcall(detector.getPlayerPos, p)
            if sP and type(pos) == "table" and pos.x then
                local dx, dy, dz = pos.x - myX, pos.y - myY, pos.z - myZ
                local dist = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                
                if dist <= raioAlerta then
                    hud.setCursorPos(1, row)
                    hud.setTextColour(C_VERMELHO)
                    hud.write("| ")
                    if aliados[p] then
                        hud.setTextColour(C_VERDE)
                        hud.write(string.format("[O] %-14s %-5s", p, dist.."m"))
                    else
                        hud.setTextColour(blink and C_ALERTA or C_VERMELHO)
                        hud.write(string.format("[X] %-14s %-5s", p, dist.."m"))
                    end
                    row = row + 1
                    mostrados = mostrados + 1
                end
                if mostrados >= 5 then break end
            end
        end
    end
    
    if mostrados == 0 then
        hud.setCursorPos(1, row)
        hud.setTextColour(C_VERMELHO)
        hud.write("| ")
        hud.setTextColour(C_CINZA)
        hud.write("Nenhum contato.")
        row = row + 1
    end
    hud.setCursorPos(1, row)
    hud.setTextColour(C_VERMELHO)
    hud.write("+-------------------------")

    -- ==========================================
    -- 2. CANTO SUPERIOR DIREITO (TELEMETRIA E POSIÇÃO)
    -- ==========================================
    local trX = w - 30 -- Alinha a 30 caracteres do final da tela
    
    hud.setCursorPos(trX, 1)
    hud.setTextColour(colorTheme)
    hud.write("[ ")
    hud.setTextColour(C_BRANCO)
    hud.write("TELEMETRIA VITAL")
    hud.setTextColour(colorTheme)
    hud.write(" ]--+")

    hud.setCursorPos(trX, 2)
    hud.setTextColour(C_CINZA)
    hud.write("  COORD : ")
    hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-21s", myX .. "," .. myY .. "," .. myZ))
    hud.setTextColour(colorTheme)
    hud.write("|")

    hud.setCursorPos(trX, 3)
    hud.setTextColour(C_CINZA)
    hud.write("  DIREC : ")
    hud.setTextColour(C_CYAN)
    hud.write(string.format("%-21s", compass))
    hud.setTextColour(colorTheme)
    hud.write("|")

    hud.setCursorPos(trX, 4)
    hud.setTextColour(C_CINZA)
    hud.write("  VELOC : ")
    hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-21s", speed .. " b/s"))
    hud.setTextColour(colorTheme)
    hud.write("|")

    hud.setCursorPos(trX, 5)
    hud.setTextColour(C_CINZA)
    hud.write("  D.BASE: ")
    hud.setTextColour(C_ALERTA)
    hud.write(string.format("%-21s", distBase .. "m"))
    hud.setTextColour(colorTheme)
    hud.write("|")

    hud.setCursorPos(trX, 6)
    hud.write("-------------------------+")

    -- ==========================================
    -- 3. CANTO INFERIOR ESQUERDO (AMBIENTE / AMEAÇA)
    -- ==========================================
    local blY = h - 3
    
    hud.setCursorPos(1, blY)
    hud.setTextColour(colorTheme)
    hud.write("+--[ ")
    hud.setTextColour(C_BRANCO)
    hud.write("STATUS")
    hud.setTextColour(colorTheme)
    hud.write(" ]")

    hud.setCursorPos(1, blY + 1)
    hud.write("| ")
    hud.setTextColour(C_CINZA)
    hud.write("DEFESA: ")
    if isAlerta then
        hud.setTextColour(blink and C_ALERTA or C_VERMELHO)
        hud.write("EMERGENCIA!!")
    else
        hud.setTextColour(C_VERDE)
        hud.write("OTIMIZADA")
    end

    hud.setCursorPos(1, blY + 2)
    hud.setTextColour(colorTheme)
    hud.write("| ")
    hud.setTextColour(C_CINZA)
    hud.write("DIA MC: ")
    hud.setTextColour(C_BRANCO)
    hud.write(os.day())

    -- ==========================================
    -- 4. CANTO INFERIOR DIREITO (SISTEMA E RELÓGIO)
    -- ==========================================
    local brY = h - 4
    local brX = w - 30

    hud.setCursorPos(brX, brY)
    hud.setTextColour(C_VERMELHO)
    hud.write("[ ")
    hud.setTextColour(C_BRANCO)
    hud.write("RED_INDUSTRIES_OS")
    hud.setTextColour(C_VERMELHO)
    hud.write(" ]--+")

    hud.setCursorPos(brX, brY + 1)
    hud.setTextColour(C_CINZA)
    hud.write("  IRL : ")
    hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-21s", os.date("%H:%M")))
    hud.setTextColour(C_VERMELHO)
    hud.write("|")

    hud.setCursorPos(brX, brY + 2)
    hud.setTextColour(C_CINZA)
    hud.write("  GAME: ")
    hud.setTextColour(C_CYAN)
    hud.write(string.format("%-21s", formatTime(os.time())))
    hud.setTextColour(C_VERMELHO)
    hud.write("|")

    hud.setCursorPos(brX, brY + 3)
    hud.setTextColour(C_CINZA)
    hud.write("  UPT : ")
    hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-21s", formatUptime(os.clock() - startTime)))
    hud.setTextColour(C_VERMELHO)
    hud.write("|")

    hud.setCursorPos(brX, brY + 4)
    hud.setTextColour(C_CINZA)
    hud.write("  CORE: ")
    hud.setTextColour(C_ALERTA)
    hud.write(string.format("%-21s", hexCode))
    hud.setTextColour(C_VERMELHO)
    hud.write("|")
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.red)
print("======================================")
print(" RED_INDUSTRIES :: TACTICAL PANORAMA")
print("======================================")
term.setTextColor(colors.white)
print(" > Modulos distribuidos na tela 360.")
print(" > Pressione [Q] para DESLIGAR.")

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
print("Sistema encerrado com seguranca.")
