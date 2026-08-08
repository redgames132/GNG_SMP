-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (HOLO V5)
-- Sem Mira Central + Moldura Tática + Funções
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

-- Ajuste para os textos centrais (Alvo e Jarvis)
local offsetMiraX = 0  
local offsetMiraY = 1  

local aliados = {
    ["redgames132"] = true,
    ["KAIOX_NEGROX"] = true,
    ["goonerstickle69"] = true,
    ["cadipadi"] = true
}

-- Paleta Neon Holográfica
local C_TRANS = 0
local C_VERMELHO = colors.red
local C_BRANCO = colors.white
local C_AMARELO = colors.yellow
local C_ALERTA = colors.orange
local C_CYAN = colors.cyan
local C_VERDE = colors.lime
local C_AZUL_CLARO = colors.lightBlue
local C_CINZA = colors.gray

local lastX, lastY, lastZ = nil, nil, nil
local speed, speedTicks = 0, 0
local totalDistance = 0 -- NOVO: Odômetro
local frame = 0
local startTime = os.clock()

-- Sistema JARVIS
local jarvisAtivo = true 
local jarvisDicas = {
    "JARVIS: Mantenha sua estamina alta para evasao.",
    "JARVIS: O minimapa e a sua maior vantagem.",
    "JARVIS: Recuo tatico e uma estrategia valida.",
    "JARVIS: Parametros vitais sob monitoramento.",
    "JARVIS: O cenario atual favorece armadilhas.",
    "JARVIS: Mapeamento do perimetro concluido.",
    "JARVIS: Varredura termica nao detectou anomalias.",
    "JARVIS: Rede neural sincronizada com a base.",
    "JARVIS: Odometro registrando movimentacao."
}
local jarvisAtual = ""
local jarvisProgresso = 0
local jarvisTempoTela = 0

local radarCX, radarCY = 14, 9
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

local function getDayCycle(t)
    if t >= 0 and t < 12 then return "DIA"
    elseif t >= 12 and t < 13.5 then return "TARDE"
    else return "NOITE" end
end

local function formatUptime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

local function writeData(x, y, label, colLabel, value, colValue, pad)
    hud.setCursorPos(x, y)
    hud.setTextColour(colLabel)
    hud.write(label)
    hud.setTextColour(colValue)
    local str = tostring(value)
    local emptySpace = pad - #str
    if emptySpace < 0 then emptySpace = 0 end
    hud.write(str .. string.rep(" ", emptySpace))
end

local function getProgressBar(valor, maximo, tamanho)
    local preenchido = math.floor((valor / maximo) * tamanho)
    local vazio = tamanho - preenchido
    return "[" .. string.rep("|", preenchido) .. string.rep(".", vazio) .. "]"
end

-- ==========================================
-- 1. DESENHO ESTÁTICO (DECORAÇÃO DAS BORDAS)
-- ==========================================
local function drawStaticHUD()
    hud.setBackgroundColour(C_TRANS)
    hud.clear()

    hud.setTextColour(C_AZUL_CLARO)

    -- MOLDURA DO CAPACETE (CANTOS)
    -- Canto Superior Esquerdo
    hud.setCursorPos(1, 1) hud.write("+==[ RADAR ]======================-")
    hud.setCursorPos(1, 2) hud.write("||")
    hud.setCursorPos(1, 3) hud.write("||")

    -- Canto Superior Direito
    hud.setCursorPos(w - 34, 1) hud.write("-===================[ TELEMETRIA ]==+")
    hud.setCursorPos(w - 1, 2) hud.write("||")
    hud.setCursorPos(w - 1, 3) hud.write("||")

    -- Canto Inferior Esquerdo
    hud.setCursorPos(1, h - 2) hud.write("||")
    hud.setCursorPos(1, h - 1) hud.write("||")
    hud.setCursorPos(1, h)     hud.write("+==[ VITAIS ]=====================-")

    -- Canto Inferior Direito
    hud.setCursorPos(w - 1, h - 2) hud.write("||")
    hud.setCursorPos(w - 1, h - 1) hud.write("||")
    hud.setCursorPos(w - 34, h)    hud.write("-======================[ CORE OS ]==+")

    -- Detalhes Laterais (Scanning brackets)
    hud.setTextColour(C_CINZA)
    hud.setCursorPos(2, math.floor(h/2) - 1) hud.write("[")
    hud.setCursorPos(2, math.floor(h/2) + 1) hud.write("[")
    hud.setCursorPos(w - 1, math.floor(h/2) - 1) hud.write("]")
    hud.setCursorPos(w - 1, math.floor(h/2) + 1) hud.write("]")
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
                totalDistance = totalDistance + speed -- Atualiza o Odômetro
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

    local midX = math.floor(w/2) + offsetMiraX
    local midY = math.floor(h/2) + offsetMiraY

    -- Alvo travado flutuando no centro (sem a mira física)
    if inimigoMaisProximo then
        writeData(midX - 12, midY - 2, ">> ALVO: ", C_ALERTA, inimigoMaisProximo .. " ("..menorDistanciaInimigo.."m)", C_VERMELHO, 25)
    else
        writeData(midX - 12, midY - 2, "", C_ALERTA, "", C_VERMELHO, 35)
    end

    -- ==========================================
    -- SISTEMA JARVIS
    -- ==========================================
    if jarvisAtivo then
        if jarvisAtual == "" then
            if spawnRisk and math.random(1, 40) == 1 then
                jarvisAtual = "ALERTA: Nivel de luz critico. Hostis iminentes."
                jarvisProgresso = 0
                jarvisTempoTela = 60
            elseif math.random(1, 80) == 1 then
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
            writeData(math.floor(midX - (#displayString / 2)), midY + 4, "", C_BRANCO, displayString, C_CYAN, 60)
        else
            writeData(midX - 30, midY + 4, "", C_BRANCO, "", C_CYAN, 60)
        end
    else
        writeData(midX - 30, midY + 4, "", C_BRANCO, "", C_CYAN, 60)
    end

    -- ==========================================
    -- MINIMAPA
    -- ==========================================
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

    -- ==========================================
    -- SINAIS VITAIS & NÍVEL DE AMEAÇA
    -- ==========================================
    local blY = h - 10
    local barHP = getProgressBar(myHealth, 20, 10)
    local barFood = getProgressBar(myFood, 20, 10)
    -- Medidor de Ameaça (Cap máximo de 5 inimigos para encher a barra)
    local barThreat = getProgressBar(math.min(inimigosProximos, 5), 5, 10)
    
    writeData(3, blY + 1, "HP  : ", C_AZUL_CLARO, barHP, myHealth <= 6 and C_VERMELHO or C_VERDE, 20)
    writeData(3, blY + 2, "FOME: ", C_AZUL_CLARO, barFood, myFood <= 6 and C_ALERTA or C_AMARELO, 20)
    writeData(3, blY + 3, "RISK: ", C_AZUL_CLARO, barThreat, inimigosProximos > 0 and C_VERMELHO or C_VERDE, 20)

    local row = 4
    local printados = 0
    for _, alvo in ipairs(dadosRadar) do
        if alvo.d <= raioAlerta and printados < 4 then
            local icon = alvo.aliado and "[ALIADO]" or "[HOSTIL]"
            local col = alvo.aliado and C_VERDE or C_ALERTA
            writeData(3, blY + row, icon, col, " " .. string.sub(alvo.nome, 1, 10) .. " " .. alvo.d .. "m", C_BRANCO, 25)
            row = row + 1
            printados = printados + 1
        end
    end
    for r = row, 7 do
        writeData(3, blY + r, "", C_BRANCO, "", C_BRANCO, 25)
    end

    -- ==========================================
    -- TELEMETRIA
    -- ==========================================
    local trX = w - 24
    local cycle = getDayCycle(os.time())

    writeData(trX, 3, "POS :: ", C_AZUL_CLARO, myX..","..myY..","..myZ, C_BRANCO, 17)
    writeData(trX, 4, "VEL :: ", C_AZUL_CLARO, speed .. " b/s", C_BRANCO, 17)
    writeData(trX, 5, "TRV :: ", C_AZUL_CLARO, totalDistance .. " m", C_AMARELO, 17) -- Odômetro
    writeData(trX, 6, "BIO :: ", C_AZUL_CLARO, string.sub(currentBiome, 1, 14), C_BRANCO, 17)
    writeData(trX, 7, "LUZ :: ", C_AZUL_CLARO, currentLight .. "/15 ("..cycle..")", spawnRisk and C_ALERTA or C_VERDE, 17)

    -- ==========================================
    -- CORE OS
    -- ==========================================
    local brY = h - 5
    writeData(trX, brY + 1, "MC  :: ", C_AZUL_CLARO, formatTime(os.time()), C_BRANCO, 17)
    writeData(trX, brY + 2, "IRL :: ", C_AZUL_CLARO, os.date("%H:%M"), C_BRANCO, 17)
    writeData(trX, brY + 3, "UPT :: ", C_AZUL_CLARO, formatUptime(os.clock() - startTime), C_BRANCO, 17)
    
    local jStatus = jarvisAtivo and "[ ONLINE ]" or "[ OFFLINE ]"
    local jColor = jarvisAtivo and C_VERDE or C_CINZA
    writeData(trX, brY + 4, "A.I :: ", C_AZUL_CLARO, jStatus, jColor, 17)
end

-- ==========================================
-- LOOP PRINCIPAL E TECLAS
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.red)
print("======================================")
print(" RED_INDUSTRIES :: HOLOGRAPHIC V5")
print("======================================")
term.setTextColor(colors.white)
print(" > Mira Central Removida.")
print(" > Odometro e Nivel de Ameaça Ativos.")
print(" > [J] Liga/Desliga Jarvis.")
print(" > [Q] Desliga o HUD.")

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
        elseif p1 == keys.j then
            jarvisAtivo = not jarvisAtivo
            if not jarvisAtivo then
                jarvisAtual = "" 
                if speaker then speaker.playSound("block.beacon.deactivate", 1.0, 1.0) end
            else
                if speaker then speaker.playSound("block.beacon.activate", 1.0, 2.0) end
            end
        end
    end
end

hud.setBackgroundColour(C_TRANS)
hud.clear()
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.lime)
print("Visor Holografico encerrado.")
