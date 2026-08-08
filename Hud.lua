-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (HOLO)
-- Design Holografico, Cores Neon, Zero Tijolos
-- ==========================================

local hud = peripheral.find("hud_glasses")
local detector = peripheral.find("player_detector")
local speaker = peripheral.find("speaker")
local env = peripheral.find("environmentDetector") or peripheral.find("environment_detector")

if not hud then
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.red)
    print("ERRO CRITICO: HUD Modem nao encontrado!")
    return
end

hud.setSize(100, 50)
local w, h = hud.getSize()

-- ==========================================
-- CONFIGURAÇÕES
-- ==========================================
local meuNick = "redgames132"
local raioAlerta = 250
local baseX, baseY, baseZ = -573, 57, -1446

local aliados = {
    ["redgames132"] = true,
    ["KAIOX_NEGROX"] = true,
    ["goonerstickle69"] = true,
    ["cadipadi"] = true
}

-- Cores (Paleta Neon para Alto Contraste)
local C_TRANS = 0
local C_VERMELHO = colors.red
local C_BRANCO = colors.white
local C_AMARELO = colors.yellow
local C_ALERTA = colors.orange
local C_CYAN = colors.cyan
local C_VERDE = colors.lime
local C_AZUL_CLARO = colors.lightBlue

local lastX, lastY, lastZ = nil, nil, nil
local speed, speedTicks = 0, 0
local compass = "-"
local frame = 0
local startTime = os.clock()

local jarvisDicas = {
    "DICA: Estamina alta e crucial para evasao.",
    "DICA: Minimapa operando em capacidade maxima.",
    "DICA: Recuo tatico e uma estrategia valida.",
    "DICA: Parametros vitais sob monitoramento.",
    "DICA: O cenario atual favorece armadilhas."
}
local jarvisAtual = ""
local jarvisProgresso = 0
local jarvisTempoTela = 0

local radarCX, radarCY = 14, 10
local visualRadius = 7
local circlePoints = {}
for i = 0, 359, 15 do
    local rad = math.rad(i)
    table.insert(circlePoints, {
        x = radarCX + math.floor(math.cos(rad) * visualRadius * 1.5),
        y = radarCY + math.floor(math.sin(rad) * visualRadius)
    })
end

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
-- FUNÇÃO MÁGICA: ESCREVE E APAGA O FUNDO
-- ==========================================
local function writeData(x, y, label, colLabel, value, colValue, pad)
    hud.setCursorPos(x, y)
    hud.setTextColour(colLabel)
    hud.write(label)
    hud.setTextColour(colValue)
    local str = tostring(value)
    local emptySpace = pad - #str
    if emptySpace < 0 then emptySpace = 0 end
    -- O espaço em branco no final garante que os números antigos sumam sem tela preta!
    hud.write(str .. string.rep(" ", emptySpace))
end

-- ==========================================
-- 1. DESENHO ESTÁTICO (RODA UMA VEZ)
-- ==========================================
local function drawStaticHUD()
    hud.setBackgroundColour(C_TRANS)
    hud.clear()

    local midX = math.floor(w/2)
    local midY = math.floor(h/2)
    
    -- Mira Central (Mais limpa e holográfica)
    hud.setTextColour(C_CYAN)
    hud.setCursorPos(midX - 1, midY) hud.write("-")
    hud.setCursorPos(midX + 1, midY) hud.write("-")
    hud.setCursorPos(midX, midY - 1) hud.write("|")
    hud.setCursorPos(midX, midY + 1) hud.write("|")

    -- Títulos principais
    hud.setTextColour(C_AZUL_CLARO)
    hud.setCursorPos(1, 1) hud.write("RADAR TÁTICO")
    hud.setCursorPos(w - 20, 1) hud.write("TELEMETRIA")
    hud.setCursorPos(1, h - 8) hud.write("SISTEMAS VITAIS")
    hud.setCursorPos(w - 20, h - 5) hud.write("RED_OS CORE")

    -- Bússola Decorativa Superior
    hud.setCursorPos(midX - 15, 2)
    hud.setTextColour(C_BRANCO)
    hud.write("-W- - - - -NW- - - - -N- - - - -NE- - - - -E-")
    hud.setCursorPos(midX, 1)
    hud.setTextColour(C_AMARELO)
    hud.write("V")
end

-- ==========================================
-- 2. DESENHO DINÂMICO
-- ==========================================
local function updateDynamicHUD()
    hud.setBackgroundColour(C_TRANS)

    local myX, myY, myZ = baseX, baseY, baseZ
    local myHealth, myFood = 20, 20
    local inimigosProximos = 0
    local inimigoMaisProximo = nil
    local menorDistanciaInimigo = 99999
    local dadosRadar = {}
    
    local currentBiome, currentLight = "OFFLINE", 15
    local spawnRisk = false

    if env then
        pcall(function() currentBiome = env.getBiome() end)
        pcall(function() currentLight = env.getLightLevel() end)
        if currentLight < 7 then spawnRisk = true end
    end
    
    if detector then
        local sucMyPos, myPos = pcall(detector.getPlayerPos, meuNick)
        if sucMyPos and type(myPos) == "table" and myPos.x then
            myX, myY, myZ = math.floor(myPos.x), math.floor(myPos.y), math.floor(myPos.z)
            if lastX == nil then lastX, lastY, lastZ = myX, myY, myZ end
            speedTicks = speedTicks + 1
            if speedTicks >= 10 then 
                local dx, dy, dz = myX - lastX, myY - lastY, myZ - lastZ
                speed = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                if speed > 0 then compass = getDirection(dx, dz) end
                lastX, lastY, lastZ = myX, myY, myZ
                speedTicks = 0
            end
        end

        if detector.getPlayer then
            local okMeta, meta = pcall(detector.getPlayer, meuNick)
            if okMeta and type(meta) == "table" then
                if meta.health then myHealth = tonumber(meta.health) end
                if meta.foodLevel then myFood = tonumber(meta.foodLevel) end
            end
        end

        local suc, pList = pcall(detector.getOnlinePlayers)
        if suc and type(pList) == "table" then
            for _, p in ipairs(pList) do
                if p ~= meuNick then
                    local sP, pos = pcall(detector.getPlayerPos, p)
                    if sP and type(pos) == "table" and pos.x then
                        local dx, dy, dz = pos.x - myX, pos.y - myY, pos.z - myZ
                        local dist = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                        local isAliado = aliados[p] == true
                        table.insert(dadosRadar, {nome = p, d = dist, dx = dx, dz = dz, aliado = isAliado})
                        
                        if dist <= raioAlerta and not isAliado then
                            inimigosProximos = inimigosProximos + 1
                            if dist < menorDistanciaInimigo then
                                menorDistanciaInimigo = dist
                                inimigoMaisProximo = p
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(dadosRadar, function(a, b) return a.d < b.d end)

    if inimigosProximos > 0 and speaker then
        if frame % 10 == 0 then speaker.playSound("entity.wither.spawn", 3.0, 0.5)
        elseif frame % 10 == 5 then speaker.playSound("entity.ghast.scream", 3.0, 0.6) end
    end

    local midX, midY = math.floor(w/2), math.floor(h/2)

    -- Alvo e Direção no Centro
    if inimigoMaisProximo then
        writeData(midX - 10, midY - 3, "ALVO: ", C_ALERTA, inimigoMaisProximo .. " ("..menorDistanciaInimigo.."m)", C_VERMELHO, 20)
    else
        writeData(midX - 10, midY - 3, "", C_ALERTA, "", C_VERMELHO, 25)
    end
    writeData(midX - 2, midY + 3, "", C_BRANCO, compass, C_AMARELO, 10)

    -- Jarvis (Centro Inferior)
    if jarvisAtual == "" then
        if spawnRisk and math.random(1, 150) == 1 then
            jarvisAtual = "ALERTA: Area escura detectada. Hostis iminentes."
            jarvisProgresso = 0
            jarvisTempoTela = 60
        elseif math.random(1, 300) == 1 then
            jarvisAtual = jarvisDicas[math.random(1, #jarvisDicas)]
            jarvisProgresso = 0
            jarvisTempoTela = 60
        end
    end

    if jarvisAtual ~= "" then
        if jarvisProgresso < #jarvisAtual then
            jarvisProgresso = jarvisProgresso + 2 
            if jarvisProgresso > #jarvisAtual then jarvisProgresso = #jarvisAtual end
            if speaker then speaker.playSound("block.note_block.bit", 2.0, 1.5 + (math.random(-2,2)*0.1)) end
        else
            jarvisTempoTela = jarvisTempoTela - 1
            if jarvisTempoTela <= 0 then jarvisAtual = "" end
        end
        local displayString = string.sub(jarvisAtual, 1, math.floor(jarvisProgresso))
        writeData(math.floor(midX - (#displayString / 2)), midY + 8, "", C_BRANCO, displayString, C_CYAN, 50)
    else
        writeData(midX - 25, midY + 8, "", C_BRANCO, "", C_CYAN, 50)
    end

    -- Limpeza do Radar e Redesenho
    for rY = radarCY - 7, radarCY + 7 do
        hud.setCursorPos(radarCX - 12, rY)
        hud.write("                        ")
    end

    hud.setTextColour(C_BRANCO)
    for _, pt in ipairs(circlePoints) do
        hud.setCursorPos(pt.x, pt.y) hud.write(".")
    end
    hud.setCursorPos(radarCX, radarCY) hud.setTextColour(C_AMARELO) hud.write("+")

    for _, alvo in ipairs(dadosRadar) do
        if alvo.d <= raioAlerta then
            local scale = visualRadius / raioAlerta
            local plotX = radarCX + math.floor(alvo.dx * scale * 1.5)
            local plotY = radarCY + math.floor(alvo.dz * scale)
            hud.setCursorPos(plotX, plotY)
            hud.setTextColour(alvo.aliado and C_VERDE or C_ALERTA)
            hud.write(alvo.aliado and "O" or "X")
        end
    end

    -- Assistente Vital (Inferior Esquerdo)
    local blY = h - 7
    if myHealth <= 10 then writeData(1, blY + 1, "[!]", C_VERMELHO, " DANO CRITICO", C_VERMELHO, 20)
    elseif spawnRisk then writeData(1, blY + 1, "[!]", C_ALERTA, " RISCO DE SPAWN ("..currentLight..")", C_ALERTA, 20)
    elseif myFood <= 6 then writeData(1, blY + 1, "[!]", C_ALERTA, " FOME ALTA", C_ALERTA, 20)
    else writeData(1, blY + 1, "[OK]", C_VERDE, " SISTEMAS ESTAVEIS", C_BRANCO, 20) end

    local row = 2
    local printados = 0
    for _, alvo in ipairs(dadosRadar) do
        if alvo.d <= raioAlerta and printados < 4 then
            local icon = alvo.aliado and "[ALIADO] " or "[HOSTIL] "
            local col = alvo.aliado and C_VERDE or C_ALERTA
            writeData(1, blY + row, icon, col, string.sub(alvo.nome, 1, 10) .. " " .. alvo.d .. "m", C_BRANCO, 25)
            row = row + 1
            printados = printados + 1
        end
    end
    for r = row, 5 do
        writeData(1, blY + r, "", C_BRANCO, "", C_BRANCO, 25)
    end

    -- Telemetria (Superior Direita)
    local trX = w - 20
    writeData(trX, 2, "POS: ", C_AZUL_CLARO, myX..","..myY..","..myZ, C_BRANCO, 15)
    writeData(trX, 3, "VEL: ", C_AZUL_CLARO, speed .. " b/s", C_BRANCO, 15)
    writeData(trX, 4, "BIO: ", C_AZUL_CLARO, string.sub(currentBiome, 1, 12), C_BRANCO, 15)
    writeData(trX, 5, "LUZ: ", C_AZUL_CLARO, currentLight .. "/15", spawnRisk and C_ALERTA or C_VERDE, 15)

    -- Core OS (Inferior Direito)
    local brY = h - 4
    writeData(trX, brY + 1, "MC : ", C_AZUL_CLARO, formatTime(os.time()), C_BRANCO, 15)
    writeData(trX, brY + 2, "IRL: ", C_AZUL_CLARO, os.date("%H:%M"), C_BRANCO, 15)
    writeData(trX, brY + 3, "UPT: ", C_AZUL_CLARO, formatUptime(os.clock() - startTime), C_BRANCO, 15)
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.red)
print("======================================")
print(" RED_INDUSTRIES :: HOLOGRAPHIC OS")
print("======================================")
term.setTextColor(colors.white)
print(" > Visual Limpo (Zero Tijolos).")
print(" > Cores Neon de Alto Contraste.")
print(" > Pressione [Q] para DESLIGAR.")

drawStaticHUD() 

local running = true
local timer = os.startTimer(0.1)

while running do
    local event, p1 = os.pullEvent()

    if event == "timer" and p1 == timer then
        updateDynamicHUD() 
        frame = frame + 1
        timer = os.startTimer(0.1)
    elseif event == "key" then
        if p1 == keys.q then
            running = false
        end
    end
end

hud.setBackgroundColour(C_TRANS)
hud.clear()
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.lime)
print("Visor Holografico encerrado.")
