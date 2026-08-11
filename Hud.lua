-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (DUO V5)
-- Triple-Radar (Global + Local + Minerios)
-- ==========================================

local hud = peripheral.find("hud_glasses")
local detector = peripheral.find("player_detector")
local speaker = peripheral.find("speaker")
local env = peripheral.find("environmentDetector") or peripheral.find("environment_detector")
local geo = peripheral.find("geoScanner") or peripheral.find("geo_scanner")

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
-- CONFIGURAÇÕES DA EQUIPE E BASE
-- ==========================================
local meuNick = "redgames132"
local baseX, baseY, baseZ = -573, 57, -1446
local raioGlobal = 250
local raioLocal = 50

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
local C_CINZA_ESCURO = colors.lightGray
local C_DIAMANTE = colors.lightBlue
local C_ESMERALDA = colors.lime
local C_OURO = colors.yellow
local C_FERRO = colors.white

local frame = 0
local speedTicks = 0
local startTime = os.clock()

-- Banco de Dados Geo Scanner
local dadosMinerios = {}
local geoCooldown = 0

-- Sistema JARVIS
local jarvisAtivo = true 
local jarvisDicas = {
    "JARVIS: Radares online. Vantagem tatica estabelecida.",
    "JARVIS: Defesa de perimetro ativada. Monitorando a base.",
    "JARVIS: Trabalhem em conjunto. O fogo cruzado e letal.",
    "JARVIS: Acompanhe os indicadores de elevacao no radar.",
    "JARVIS: O cenario atual favorece emboscadas. Atencao.",
    "JARVIS: O modulo GeoScanner procura por minerais de alto valor.",
    "JARVIS: Rede neural estabilizada entre os operadores."
}
local jarvisAtual = ""
local jarvisProgresso = 0
local jarvisTempoTela = 0

-- Geometria dos 3 Radares
local radar1CX, radar1CY = 14, 8   -- Global (Base)
local radar2CX, radar2CY = 14, 22  -- Local (Você)
local radar3CX, radar3CY = 14, 37  -- Minérios (Geo Scanner)

local radius1, radius2, radius3 = 5, 5, 5
local circle1Points, circle2Points, circle3Points = {}, {}, {}

for i = 0, 359, 15 do
    local rad = math.rad(i)
    local rx = math.floor(math.cos(rad) * radius1 * 1.5)
    local ry = math.floor(math.sin(rad) * radius1)
    
    table.insert(circle1Points, { x = radar1CX + rx, y = radar1CY + ry })
    table.insert(circle2Points, { x = radar2CX + rx, y = radar2CY + ry })
    table.insert(circle3Points, { x = radar3CX + rx, y = radar3CY + ry })
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

-- ==========================================
-- 1. DESENHO ESTÁTICO (MOLDURAS ESTRUTURAIS)
-- ==========================================
local function drawStaticHUD()
    hud.setBackgroundColour(C_TRANS)
    hud.clear()
    hud.setTextColour(C_AZUL_CLARO)

    hud.setCursorPos(1, 1) hud.write("+==[ GLOBAL: BASE ]===============-")
    hud.setCursorPos(1, 2) hud.write("||")
    
    hud.setCursorPos(1, 15) hud.write("+==[ LOCAL: VOCE ]================-")
    hud.setCursorPos(1, 16) hud.write("||")

    hud.setCursorPos(1, 30) hud.write("+==[ GEO SCANNER ]================-")
    hud.setCursorPos(1, 31) hud.write("||")

    hud.setCursorPos(w - 38, 1) hud.write("-===================[ TELEMETRIA ]==+")
    hud.setCursorPos(w - 1, 2) hud.write("||")

    hud.setCursorPos(1, h - 1) hud.write("||")
    hud.setCursorPos(1, h)     hud.write("+==[ EQUIPE E VITAIS ]============-")

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

    local myX, myY, myZ = baseX, baseY, baseZ
    local inimigosProximos = 0
    local inimigoMaisProximo = nil
    local menorDistanciaDeMim = 99999
    local dadosRadar = {}
    
    local currentBiome, currentLight = "OFFLINE", 15
    local spawnRisk = false

    -- Sensores do Ambiente
    if env then
        pcall(function() currentBiome = env.getBiome() end)
        pcall(function() currentLight = env.getLightLevel() end)
        if currentLight < 7 then spawnRisk = true end
    end
    
    -- Leitura dos Jogadores
    if detector then
        for _, op in ipairs(operadores) do tracker[op].online = false end
        speedTicks = speedTicks + 1
        
        local sucMy, myPos = pcall(detector.getPlayerPos, meuNick)
        if sucMy and type(myPos) == "table" and myPos.x then
            myX, myY, myZ = math.floor(myPos.x), math.floor(myPos.y), math.floor(myPos.z)
        end

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
                        local dxB, dzB = pos.x - baseX, pos.z - baseZ
                        local distBase = math.floor(math.sqrt(dxB*dxB + (pos.y - baseY)^2 + dzB*dzB))
                        
                        local dxM, dyM, dzM = pos.x - myX, pos.y - myY, pos.z - myZ
                        local distMe = math.floor(math.sqrt(dxM*dxM + dyM*dyM + dzM*dzM))
                        
                        local isAliado = aliados[p] == true
                        table.insert(dadosRadar, {
                            nome = p, 
                            dB = distBase, dxB = dxB, dzB = dzB,
                            dM = distMe, dxM = dxM, dyM = dyM, dzM = dzM,
                            aliado = isAliado
                        })
                        
                        if distMe <= raioGlobal and not isAliado then
                            inimigosProximos = inimigosProximos + 1
                            if distMe < menorDistanciaDeMim then
                                menorDistanciaDeMim = distMe
                                inimigoMaisProximo = p
                            end
                        end
                    end
                end
            end
        end
        if speedTicks >= 10 then speedTicks = 0 end
    end

    table.sort(dadosRadar, function(a, b) return a.dM < b.dM end)

    -- Leitura do Geo Scanner (A cada 20 frames / 2 segundos para evitar lag)
    if geo and frame % 20 == 0 then
        local sucGeo, scanResult = pcall(geo.scan, 12) -- Escaneia num raio de 12 blocos
        if sucGeo and type(scanResult) == "table" then
            dadosMinerios = {}
            for _, block in ipairs(scanResult) do
                local name = string.lower(block.name)
                -- Filtra apenas os minérios principais
                if string.find(name, "ore") or string.find(name, "ancient_debris") then
                    local color = C_CINZA
                    if string.find(name, "diamond") then color = C_DIAMANTE
                    elseif string.find(name, "emerald") then color = C_ESMERALDA
                    elseif string.find(name, "gold") then color = C_OURO
                    elseif string.find(name, "iron") then color = C_FERRO
                    elseif string.find(name, "ancient_debris") then color = C_VERMELHO end
                    
                    table.insert(dadosMinerios, {x = block.x, y = block.y, z = block.z, col = color})
                end
            end
        end
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
        if menorDistanciaDeMim <= 30 then defconLvl, defconCol, defconTxt = 1, C_VERMELHO, "INVASAO"
        elseif menorDistanciaDeMim <= 80 then defconLvl, defconCol, defconTxt = 2, C_VERMELHO, "PERIGO"
        elseif menorDistanciaDeMim <= 150 then defconLvl, defconCol, defconTxt = 3, C_ALERTA, "ALERTA"
        else defconLvl, defconCol, defconTxt = 4, C_AMARELO, "CAUTELA" end
    end
    writeData(midX - 10, 2, "DEFCON " .. defconLvl .. " :: ", C_BRANCO, defconTxt, defconCol, 15)

    -- Alvo travado (Mostrando a distância real de você)
    if inimigoMaisProximo then
        writeData(midX - 12, midY - 2, ">> ALVO: ", C_ALERTA, inimigoMaisProximo .. " ("..menorDistanciaDeMim.."m)", C_VERMELHO, 25)
    else
        writeData(midX - 12, midY - 2, "", C_ALERTA, "", C_VERMELHO, 35)
    end

    -- ==========================================
    -- SISTEMA JARVIS
    -- ==========================================
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
    -- RADAR 1: GLOBAL (FOCADO NA BASE)
    -- ==========================================
    for rY = radar1CY - 6, radar1CY + 6 do hud.setCursorPos(radar1CX - 12, rY) hud.write("                        ") end
    hud.setTextColour(C_CINZA_ESCURO)
    for rY = radar1CY - 4, radar1CY + 4 do hud.setCursorPos(radar1CX, rY) hud.write("|") end
    hud.setCursorPos(radar1CX - 7, radar1CY) hud.write("-------+-------")

    hud.setTextColour(C_AZUL_CLARO)
    for _, pt in ipairs(circle1Points) do hud.setCursorPos(pt.x, pt.y) hud.write(".") end
    hud.setCursorPos(radar1CX, radar1CY) hud.setTextColour(C_AMARELO) hud.write("B")

    for _, alvo in ipairs(dadosRadar) do
        if alvo.dB <= raioGlobal then
            local scale = radius1 / raioGlobal
            local plotX = radar1CX + math.floor(alvo.dxB * scale * 1.5)
            local plotY = radar1CY + math.floor(alvo.dzB * scale)
            hud.setCursorPos(plotX, plotY)
            hud.setTextColour(alvo.aliado and C_VERDE or C_ALERTA)
            hud.write(alvo.aliado and "O" or "X")
        end
    end

    -- ==========================================
    -- RADAR 2: LOCAL (FOCADO EM VOCÊ - 50m)
    -- ==========================================
    for rY = radar2CY - 6, radar2CY + 6 do hud.setCursorPos(radar2CX - 12, rY) hud.write("                        ") end
    hud.setTextColour(C_CINZA_ESCURO)
    for rY = radar2CY - 4, radar2CY + 4 do hud.setCursorPos(radar2CX, rY) hud.write("|") end
    hud.setCursorPos(radar2CX - 7, radar2CY) hud.write("-------+-------")

    hud.setTextColour(C_VERMELHO)
    for _, pt in ipairs(circle2Points) do hud.setCursorPos(pt.x, pt.y) hud.write(".") end
    hud.setCursorPos(radar2CX, radar2CY) hud.setTextColour(C_CYAN) hud.write("V")

    for _, alvo in ipairs(dadosRadar) do
        if alvo.dM <= raioLocal then
            local scale = radius2 / raioLocal
            local plotX = radar2CX + math.floor(alvo.dxM * scale * 1.5)
            local plotY = radar2CY + math.floor(alvo.dzM * scale)
            hud.setCursorPos(plotX, plotY)
            hud.setTextColour(alvo.aliado and C_VERDE or C_BRANCO)
            hud.write(alvo.aliado and "O" or "X")
        end
    end

    -- ==========================================
    -- RADAR 3: GEO SCANNER (MINÉRIOS - 12m)
    -- ==========================================
    for rY = radar3CY - 6, radar3CY + 6 do hud.setCursorPos(radar3CX - 12, rY) hud.write("                        ") end
    hud.setTextColour(C_CINZA_ESCURO)
    for rY = radar3CY - 4, radar3CY + 4 do hud.setCursorPos(radar3CX, rY) hud.write("|") end
    hud.setCursorPos(radar3CX - 7, radar3CY) hud.write("-------+-------")

    if not geo then
        hud.setCursorPos(radar3CX - 6, radar3CY + 1)
        hud.setTextColour(C_VERMELHO)
        hud.write("[ OFFLINE ]")
    else
        hud.setTextColour(C_ESMERALDA)
        for _, pt in ipairs(circle3Points) do hud.setCursorPos(pt.x, pt.y) hud.write(".") end
        hud.setCursorPos(radar3CX, radar3CY) hud.setTextColour(C_CYAN) hud.write("V")

        -- Mapeia os minérios na tela
        for _, minerio in ipairs(dadosMinerios) do
            -- O GeoScanner retorna posições X e Z relativas!
            local scale = radius3 / 12 
            local plotX = radar3CX + math.floor(minerio.x * scale * 1.5)
            local plotY = radar3CY + math.floor(minerio.z * scale)
            
            -- Mantém os plots dentro do limite do círculo 3 visual
            if plotX > radar3CX - 9 and plotX < radar3CX + 9 and plotY > radar3CY - 6 and plotY < radar3CY + 6 then
                hud.setCursorPos(plotX, plotY)
                hud.setTextColour(minerio.col)
                hud.write("*")
            end
        end
    end

    -- ==========================================
    -- SINAIS VITAIS E LOG
    -- ==========================================
    local blY = h - 7
    local op1 = tracker["redgames132"]
    if op1.online then
        local bar1HP = getProgressBar(op1.hp, 20, 6)
        local bar1Fd = getProgressBar(op1.food, 20, 6)
        writeData(3, blY, "RED :: ", C_VERMELHO, "HP:"..bar1HP.." FD:"..bar1Fd, C_BRANCO, 20)
    else
        writeData(3, blY, "RED :: ", C_VERMELHO, "[ OFFLINE ]", C_CINZA, 20)
    end

    local op2 = tracker["cadipadi"]
    if op2.online then
        local bar2HP = getProgressBar(op2.hp, 20, 6)
        local bar2Fd = getProgressBar(op2.food, 20, 6)
        writeData(3, blY + 1, "CAD :: ", C_CYAN, "HP:"..bar2HP.." FD:"..bar2Fd, C_BRANCO, 20)
    else
        writeData(3, blY + 1, "CAD :: ", C_CYAN, "[ OFFLINE ]", C_CINZA, 20)
    end

    hud.setCursorPos(3, blY + 2)
    hud.setTextColour(C_AZUL_CLARO)
    hud.write("ALVOS (DE VOCE):")

    local row = 3
    local printados = 0
    for _, alvo in ipairs(dadosRadar) do
        if alvo.dM <= raioGlobal and printados < 4 then
            local icon = alvo.aliado and "[ALIADO]" or "[HOSTIL]"
            local col = alvo.aliado and C_VERDE or C_ALERTA
            local elev = "-"
            if alvo.dyM > 4 then elev = "^" elseif alvo.dyM < -4 then elev = "v" end
            
            writeData(3, blY + row, icon, col, " " .. elev .. " " .. string.sub(alvo.nome, 1, 10) .. " " .. alvo.dM .. "m", C_BRANCO, 25)
            row = row + 1
            printados = printados + 1
        end
    end
    for r = row, 6 do writeData(3, blY + r, "", C_BRANCO, "", C_BRANCO, 25) end

    -- ==========================================
    -- TELEMETRIA E CORE OS
    -- ==========================================
    local trX = w - 28
    local cycle = getDayCycle(os.time())

    if op1.online then
        writeData(trX, 3, "RED :: ", C_VERMELHO, op1.x..","..op1.y..","..op1.z, C_BRANCO, 22)
    else
        writeData(trX, 3, "RED :: ", C_VERMELHO, "[ SINAL PERDIDO ]", C_CINZA, 22)
    end

    if op2.online then
        writeData(trX, 4, "CAD :: ", C_CYAN, op2.x..","..op2.y..","..op2.z, C_BRANCO, 22)
    else
        writeData(trX, 4, "CAD :: ", C_CYAN, "[ SINAL PERDIDO ]", C_CINZA, 22)
    end

    writeData(trX, 6, "BIO :: ", C_AZUL_CLARO, string.sub(currentBiome, 1, 20), C_BRANCO, 22)
    writeData(trX, 7, "LUZ :: ", C_AZUL_CLARO, currentLight .. "/15 ("..cycle..")", spawnRisk and C_ALERTA or C_VERDE, 22)

    local brY = h - 5
    local trXC = w - 24
    
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
print(" RED_INDUSTRIES :: DUO-CORE V5")
print("======================================")
term.setTextColor(colors.white)
print(" > Modulo Geo Scanner acoplado.")
print(" > [J] Liga/Desliga Jarvis.")
print(" > [Q] Desliga o HUD.")

drawStaticHUD() 

local running = true
local timer = os.startTimer(0.1)

while running do
    local event, p1 = os.pullEvent()

    if event == "timer" and p1 == timer then
        frame = frame + 1
        updateDynamicHUD() 
        timer = os.startTimer(0.1)
    elseif event == "key" then
        if p1 == keys.q then
            running = false
        elseif p1 == keys.j then
            jarvisAtivo = not jarvisAtivo
            if not jarvisAtivo then
                jarvisAtual = "" 
            end
        end
    end
end

hud.setBackgroundColour(C_TRANS)
hud.clear()
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.lime)
print("Visor DUO-CORE encerrado.")
