-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (DUO-CORE V2)
-- Sistema DEFCON + Elevação de Alvos + EQ Visual
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
-- CONFIGURAÇÕES DA EQUIPE
-- ==========================================
local baseX, baseY, baseZ = -573, 57, -1446
local raioAlerta = 250

local offsetMiraX = 0  
local offsetMiraY = 1  

local operadores = { "redgames132", "cadipadi" }
local tracker = {
    ["redgames132"] = {lastX = nil, lastY = nil, lastZ = nil, speed = 0, online = false, hp = 20, food = 20, x = 0, y = 0, z = 0},
    ["cadipadi"]    = {lastX = nil, lastY = nil, lastZ = nil, speed = 0, online = false, hp = 20, food = 20, x = 0, y = 0, z = 0}
}
local aliados = { ["KAIOX_NEGROX"] = true, ["goonerstickle69"] = true }

-- Paleta Holográfica
local C_TRANS = 0
local C_VERMELHO = colors.red
local C_BRANCO = colors.white
local C_AMARELO = colors.yellow
local C_ALERTA = colors.orange
local C_CYAN = colors.cyan
local C_VERDE = colors.lime
local C_AZUL_CLARO = colors.lightBlue
local C_CINZA = colors.gray

local frame = 0
local speedTicks = 0
local startTime = os.clock()

-- Sistema JARVIS
local jarvisAtivo = true 
local jarvisDicas = {
    "JARVIS: Equipe, mantenham a estamina alta para evasao.",
    "JARVIS: Defesa de perimetro ativada. Monitorando a base.",
    "JARVIS: Trabalhem em conjunto. O fogo cruzado e letal.",
    "JARVIS: Acompanhe os indicadores de elevacao no radar.",
    "JARVIS: O cenario atual favorece emboscadas. Atencao.",
    "JARVIS: Varredura termica conjunta nao detectou anomalias.",
    "JARVIS: Rede neural estabilizada entre os operadores."
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
    if valor < 0 then valor = 0 end
    if valor > maximo then valor = maximo end
    local preenchido = math.floor((valor / maximo) * tamanho)
    local vazio = tamanho - preenchido
    return "[" .. string.rep("|", preenchido) .. string.rep(".", vazio) .. "]"
end

local function getDirection(dx, dz)
    if dx == 0 and dz == 0 then return "-" end
    if math.abs(dx) > math.abs(dz) then return dx > 0 and "LESTE" or "OESTE"
    else return dz > 0 and "SUL" or "NORTE" end
end

-- ==========================================
-- 1. DESENHO ESTÁTICO
-- ==========================================
local function drawStaticHUD()
    hud.setBackgroundColour(C_TRANS)
    hud.clear()
    hud.setTextColour(C_AZUL_CLARO)

    hud.setCursorPos(1, 1) hud.write("+==[ RADAR DA BASE ]==============-")
    hud.setCursorPos(1, 2) hud.write("||")
    hud.setCursorPos(1, 3) hud.write("||")

    hud.setCursorPos(w - 38, 1) hud.write("-===================[ TELEMETRIA ]==+")
    hud.setCursorPos(w - 1, 2) hud.write("||")
    hud.setCursorPos(w - 1, 3) hud.write("||")

    hud.setCursorPos(1, h - 2) hud.write("||")
    hud.setCursorPos(1, h - 1) hud.write("||")
    hud.setCursorPos(1, h)     hud.write("+==[ EQUIPE E VITAIS ]============-")

    hud.setCursorPos(w - 1, h - 2) hud.write("||")
    hud.setCursorPos(w - 1, h - 1) hud.write("||")
    hud.setCursorPos(w - 34, h)    hud.write("-======================[ CORE OS ]==+")

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

    local inimigosProximos = 0
    local inimigoMaisProximo = nil
    local menorDistanciaInimigo = 99999
    local dadosRadar = {}
    local principalCompass = "-"
    
    local currentBiome, currentLight = "OFFLINE", 15
    local spawnRisk = false

    if env then
        pcall(function() currentBiome = env.getBiome() end)
        pcall(function() currentLight = env.getLightLevel() end)
        if currentLight < 7 then spawnRisk = true end
    end
    
    if detector then
        for _, op in ipairs(operadores) do tracker[op].online = false end
        speedTicks = speedTicks + 1
        
        local suc, pList = pcall(detector.getOnlinePlayers)
        if suc and type(pList) == "table" then
            for _, p in ipairs(pList) do
                local sP, pos = pcall(detector.getPlayerPos, p)
                if sP and type(pos) == "table" and pos.x then
                    
                    if tracker[p] then
                        tracker[p].online = true
                        tracker[p].x, tracker[p].y, tracker[p].z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
                        
                        if tracker[p].lastX == nil then
                            tracker[p].lastX, tracker[p].lastY, tracker[p].lastZ = tracker[p].x, tracker[p].y, tracker[p].z
                        end
                        if speedTicks >= 10 then
                            local dx = tracker[p].x - tracker[p].lastX
                            local dy = tracker[p].y - tracker[p].lastY
                            local dz = tracker[p].z - tracker[p].lastZ
                            tracker[p].speed = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                            
                            -- Pega a direção do usuário principal que está rodando o óculos
                            if p == operadores[1] and tracker[p].speed > 0 then
                                principalCompass = getDirection(dx, dz)
                            end
                            
                            tracker[p].lastX, tracker[p].lastY, tracker[p].lastZ = tracker[p].x, tracker[p].y, tracker[p].z
                        end

                        if detector.getPlayer then
                            local okMeta, meta = pcall(detector.getPlayer, p)
                            if okMeta and type(meta) == "table" then
                                if meta.health then tracker[p].hp = tonumber(meta.health) end
                                if meta.foodLevel then tracker[p].food = tonumber(meta.foodLevel) end
                            end
                        end
                    else
                        local dx, dy, dz = pos.x - baseX, pos.y - baseY, pos.z - baseZ
                        local dist = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                        local isAliado = aliados[p] == true
                        table.insert(dadosRadar, {nome = p, d = dist, dx = dx, dy = dy, dz = dz, aliado = isAliado})
                        
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
        if speedTicks >= 10 then speedTicks = 0 end
    end

    table.sort(dadosRadar, function(a, b) return a.d < b.d end)

    if inimigosProximos > 0 and speaker then
        if frame % 10 == 0 then speaker.playSound("entity.wither.spawn", 3.0, 0.5)
        elseif frame % 10 == 5 then speaker.playSound("entity.ghast.scream", 3.0, 0.6) end
    end

    local midX = math.floor(w/2) + offsetMiraX
    local midY = math.floor(h/2) + offsetMiraY

    -- ==========================================
    -- SISTEMA DEFCON (TOPO CENTRAL)
    -- ==========================================
    local defconLvl = 5
    local defconCol = C_VERDE
    local defconTxt = "SEGURO"
    
    if inimigosProximos > 0 then
        if menorDistanciaInimigo <= 30 then defconLvl, defconCol, defconTxt = 1, C_VERMELHO, "INVASAO"
        elseif menorDistanciaInimigo <= 80 then defconLvl, defconCol, defconTxt = 2, C_VERMELHO, "PERIGO"
        elseif menorDistanciaInimigo <= 150 then defconLvl, defconCol, defconTxt = 3, C_ALERTA, "ALERTA"
        else defconLvl, defconCol, defconTxt = 4, C_AMARELO, "CAUTELA" end
    end

    writeData(midX - 10, 2, "DEFCON " .. defconLvl .. " :: ", C_BRANCO, defconTxt, defconCol, 15)

    -- Alvo travado
    if inimigoMaisProximo then
        writeData(midX - 12, midY - 2, ">> ALVO: ", C_ALERTA, inimigoMaisProximo .. " ("..menorDistanciaInimigo.."m)", C_VERMELHO, 25)
    else
        writeData(midX - 12, midY - 2, "", C_ALERTA, "", C_VERMELHO, 35)
    end

    -- ==========================================
    -- SISTEMA JARVIS E BÚSSOLA
    -- ==========================================
    writeData(midX - 3, midY + 3, "", C_BRANCO, principalCompass, C_AMARELO, 10)

    if jarvisAtivo then
        if jarvisAtual == "" then
            if spawnRisk and math.random(1, 40) == 1 then
                jarvisAtual = "ALERTA: Luz baixa no perimetro. Risco de invasao."
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
            writeData(math.floor(midX - (#displayString / 2)), midY + 5, "", C_BRANCO, displayString, C_CYAN, 60)
        else
            writeData(midX - 30, midY + 5, "", C_BRANCO, "", C_CYAN, 60)
        end
    else
        writeData(midX - 30, midY + 5, "", C_BRANCO, "", C_CYAN, 60)
    end

    -- ==========================================
    -- MINIMAPA (CENTRO = BASE)
    -- ==========================================
    for rY = radarCY - 7, radarCY + 7 do
        hud.setCursorPos(radarCX - 12, rY)
        hud.write("                        ")
    end

    hud.setTextColour(C_BRANCO)
    for _, pt in ipairs(circlePoints) do
        hud.setCursorPos(pt.x, pt.y) hud.write(".")
    end
    hud.setCursorPos(radarCX, radarCY) hud.setTextColour(C_AMARELO) hud.write("B")

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
    -- SINAIS VITAIS DA EQUIPE E ALVOS
    -- ==========================================
    local blY = h - 9
    
    local op1 = tracker["redgames132"]
    if op1.online then
        local bar1HP = getProgressBar(op1.hp, 20, 6)
        local bar1Fd = getProgressBar(op1.food, 20, 6)
        writeData(3, blY + 1, "RED :: ", C_VERMELHO, "HP:"..bar1HP.." FD:"..bar1Fd, C_BRANCO, 20)
    else
        writeData(3, blY + 1, "RED :: ", C_VERMELHO, "[ OFFLINE ]", C_CINZA, 20)
    end

    local op2 = tracker["cadipadi"]
    if op2.online then
        local bar2HP = getProgressBar(op2.hp, 20, 6)
        local bar2Fd = getProgressBar(op2.food, 20, 6)
        writeData(3, blY + 2, "CAD :: ", C_CYAN, "HP:"..bar2HP.." FD:"..bar2Fd, C_BRANCO, 20)
    else
        writeData(3, blY + 2, "CAD :: ", C_CYAN, "[ OFFLINE ]", C_CINZA, 20)
    end

    hud.setCursorPos(3, blY + 3)
    hud.setTextColour(C_AZUL_CLARO)
    hud.write("ALVOS (ELEVACAO):")

    local row = 4
    local printados = 0
    for _, alvo in ipairs(dadosRadar) do
        if alvo.d <= raioAlerta and printados < 4 then
            local icon = alvo.aliado and "[ALIADO]" or "[HOSTIL]"
            local col = alvo.aliado and C_VERDE or C_ALERTA
            
            -- Lógica de Elevação
            local elev = "-"
            if alvo.dy > 4 then elev = "^" elseif alvo.dy < -4 then elev = "v" end
            
            writeData(3, blY + row, icon, col, " " .. elev .. " " .. string.sub(alvo.nome, 1, 10) .. " " .. alvo.d .. "m", C_BRANCO, 25)
            row = row + 1
            printados = printados + 1
        end
    end
    for r = row, 7 do writeData(3, blY + r, "", C_BRANCO, "", C_BRANCO, 25) end

    -- ==========================================
    -- TELEMETRIA DA EQUIPE
    -- ==========================================
    local trX = w - 28
    local cycle = getDayCycle(os.time())

    if op1.online then
        writeData(trX, 3, "RED :: ", C_VERMELHO, op1.x..","..op1.y..","..op1.z .. " ("..op1.speed.."b/s)", C_BRANCO, 22)
    else
        writeData(trX, 3, "RED :: ", C_VERMELHO, "[ SINAL PERDIDO ]", C_CINZA, 22)
    end

    if op2.online then
        writeData(trX, 4, "CAD :: ", C_CYAN, op2.x..","..op2.y..","..op2.z .. " ("..op2.speed.."b/s)", C_BRANCO, 22)
    else
        writeData(trX, 4, "CAD :: ", C_CYAN, "[ SINAL PERDIDO ]", C_CINZA, 22)
    end

    writeData(trX, 6, "BIO :: ", C_AZUL_CLARO, string.sub(currentBiome, 1, 20), C_BRANCO, 22)
    writeData(trX, 7, "LUZ :: ", C_AZUL_CLARO, currentLight .. "/15 ("..cycle..")", spawnRisk and C_ALERTA or C_VERDE, 22)

    -- ==========================================
    -- CORE OS E VISUALIZER DE REDE
    -- ==========================================
    local brY = h - 5
    local trXC = w - 24
    
    -- Animação de Rede Neural Fake
    local eqBars = {"|", "||", "|||", "||||", "|||||"}
    local eq1, eq2, eq3 = eqBars[math.random(1,5)], eqBars[math.random(1,5)], eqBars[math.random(1,5)]
    
    writeData(trXC, brY + 1, "SYNC:: ", C_AZUL_CLARO, eq1.." "..eq2.." "..eq3, C_VERDE, 17)
    writeData(trXC, brY + 2, "IRL :: ", C_AZUL_CLARO, os.date("%H:%M"), C_BRANCO, 17)
    writeData(trXC, brY + 3, "UPT :: ", C_AZUL_CLARO, formatUptime(os.clock() - startTime), C_BRANCO, 17)
    
    local jStatus = jarvisAtivo and "[ ONLINE ]" or "[ OFFLINE ]"
    local jColor = jarvisAtivo and C_VERDE or C_CINZA
    writeData(trXC, brY + 4, "A.I :: ", C_AZUL_CLARO, jStatus, jColor, 17)
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.red)
print("======================================")
print(" RED_INDUSTRIES :: DUO-CORE (DEFCON)")
print("======================================")
term.setTextColor(colors.white)
print(" > Modulo DEFCON e Elevacao Ativos.")
print(" > Bússola centralizada e Spectrum Visualizer.")
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
print("Visor DEFCON encerrado.")
