-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (ALIEN ED.)
-- Sigeon pex + Logo ASCII Segura
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
-- CONFIGURAÇÕES DO OPERADOR
-- ==========================================
local meuNick = "Alien_Le_pep" 
local raioAlerta = 50          

local offsetMiraX = 0  
local offsetMiraY = 1  

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

local lastX, lastY, lastZ = nil, nil, nil
local speed, speedTicks = 0, 0

-- Sistema SIGEON PEX
local sigeonAtivo = true 
local sigeonDicas = {
    "SIGEON PEX: Galalelo galala.",
    "SIGEON PEX: Tung Tung angel.",
    "SIGEON PEX: Babababindun .",
    "SIGEON PEX: Silili boy.",
    "SIGEON PEX: Cuidado tem um homem bebe macaco.",
    "SIGEON PEX: Vá fetalizar.",
    "SIGEON PEX: Sulfato de pernas azuis."
}
local sigeonAtual = ""
local sigeonProgresso = 0
local sigeonTempoTela = 0

-- Geometria do Radar
local radarCX, radarCY = 14, 15
local visualRadius = 7
local circlePoints = {}
for i = 0, 359, 15 do
    local rad = math.rad(i)
    table.insert(circlePoints, {
        x = radarCX + math.floor(math.cos(rad) * visualRadius * 1.5),
        y = radarCY + math.floor(math.sin(rad) * visualRadius)
    })
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
-- 1. DESENHO ESTÁTICO E LOGO RED INDUSTRIES
-- ==========================================
local function drawStaticHUD()
    hud.setBackgroundColour(C_TRANS)
    hud.clear()
    
    -- MOLDURAS
    hud.setTextColour(C_AZUL_CLARO)
    hud.setCursorPos(1, 1) hud.write("+==[ RADAR LOCAL ]================-")
    hud.setCursorPos(1, 2) hud.write("||")
    hud.setCursorPos(1, 3) hud.write("||")
    hud.setCursorPos(w - 38, 1) hud.write("-================[ STATUS VITAIS ]==+")
    hud.setCursorPos(w - 1, 2) hud.write("||")
    hud.setCursorPos(w - 1, 3) hud.write("||")

    -- ==========================================
    -- ASCII ART SEGURA: LOGO RED INDUSTRIES
    -- Usando caracteres normais para evitar glitches
    -- ==========================================
    local logoY = 30
    hud.setTextColour(C_VERMELHO)
    hud.setCursorPos(3, logoY)     hud.write("######\\")
    hud.setCursorPos(3, logoY + 1) hud.write("     ##")
    hud.setCursorPos(3, logoY + 2) hud.write("######/")
    hud.setCursorPos(3, logoY + 3) hud.write("##  \\")
    hud.setCursorPos(3, logoY + 4) hud.write("##   \\")
    
    hud.setCursorPos(1, logoY + 6)
    hud.write("-- R E D --")
    hud.setCursorPos(1, logoY + 7)
    hud.setTextColour(C_BRANCO)
    hud.write("INDUSTRIES")
end

-- ==========================================
-- 2. DESENHO DINÂMICO
-- ==========================================
local function updateDynamicHUD()
    hud.setBackgroundColour(C_TRANS)

    local myX, myY, myZ = 0, 0, 0
    local myHealth, myFood = 20, 20
    local dadosRadar = {}
    local inimigosProximos = 0
    local inimigoMaisProximo = nil
    local menorDistanciaDeMim = 99999
    
    if detector then
        speedTicks = speedTicks + 1
        
        local sucMy, myPos = pcall(detector.getPlayerPos, meuNick)
        if sucMy and type(myPos) == "table" and myPos.x then
            myX, myY, myZ = math.floor(myPos.x), math.floor(myPos.y), math.floor(myPos.z)
            
            if lastX == nil then lastX, lastY, lastZ = myX, myY, myZ end
            if speedTicks >= 10 then
                local dx, dy, dz = myX - lastX, myY - lastY, myZ - lastZ
                speed = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
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
                        local dxM, dyM, dzM = pos.x - myX, pos.y - myY, pos.z - myZ
                        local distMe = math.floor(math.sqrt(dxM*dxM + dyM*dyM + dzM*dzM))
                        
                        table.insert(dadosRadar, {
                            nome = p, dM = distMe, dxM = dxM, dyM = dyM, dzM = dzM
                        })
                        
                        if distMe <= raioAlerta then
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
    end

    table.sort(dadosRadar, function(a, b) return a.dM < b.dM end)

    local midX = math.floor(w/2) + offsetMiraX
    local midY = math.floor(h/2) + offsetMiraY

    if inimigoMaisProximo then
        writeData(midX - 12, midY - 2, ">> ALVO: ", C_ALERTA, inimigoMaisProximo .. " ("..menorDistanciaDeMim.."m)", C_VERMELHO, 25)
    else
        writeData(midX - 12, midY - 2, "", C_ALERTA, "", C_VERMELHO, 35)
    end

    -- ==========================================
    -- SISTEMA SIGEON PEX
    -- ==========================================
    if sigeonAtivo then
        if sigeonAtual == "" then
            if math.random(1, 80) == 1 then
                sigeonAtual = sigeonDicas[math.random(1, #sigeonDicas)]
                sigeonProgresso = 0
                sigeonTempoTela = 60
            end
        end

        if sigeonAtual ~= "" then
            if sigeonProgresso < #sigeonAtual then
                sigeonProgresso = sigeonProgresso + 2 
                if sigeonProgresso > #sigeonAtual then sigeonProgresso = #sigeonAtual end
                if speaker then speaker.playSound("block.note_block.bit", 2.0, 1.5 + (math.random(-2,2)*0.1)) end
            else
                sigeonTempoTela = sigeonTempoTela - 1
                if sigeonTempoTela <= 0 then sigeonAtual = "" end
            end
            local displayString = string.sub(sigeonAtual, 1, math.floor(sigeonProgresso))
            writeData(math.floor(midX - (#displayString / 2)), midY + 4, "", C_BRANCO, displayString, C_CYAN, 60)
        else
            writeData(midX - 30, midY + 4, "", C_BRANCO, "", C_CYAN, 60)
        end
    else
        writeData(midX - 30, midY + 4, "", C_BRANCO, "", C_CYAN, 60)
    end

    -- ==========================================
    -- RADAR LOCAL (GRADE HOLOGRÁFICA)
    -- ==========================================
    for rY = radarCY - 7, radarCY + 7 do
        hud.setCursorPos(radarCX - 12, rY)
        hud.write("                        ")
    end

    hud.setTextColour(C_CINZA_ESCURO)
    for rY = radarCY - 5, radarCY + 5 do hud.setCursorPos(radarCX, rY) hud.write("|") end
    hud.setCursorPos(radarCX - 8, radarCY) hud.write("-------+-------")

    hud.setTextColour(C_AZUL_CLARO)
    for _, pt in ipairs(circlePoints) do hud.setCursorPos(pt.x, pt.y) hud.write(".") end
    
    hud.setCursorPos(radarCX, radarCY) hud.setTextColour(C_CYAN) hud.write("V")

    for _, alvo in ipairs(dadosRadar) do
        if alvo.dM <= raioAlerta then
            local scale = visualRadius / raioAlerta
            local plotX = radarCX + math.floor(alvo.dxM * scale * 1.5)
            local plotY = radarCY + math.floor(alvo.dzM * scale)
            hud.setCursorPos(plotX, plotY)
            hud.setTextColour(C_VERMELHO)
            hud.write("X")
        end
    end

    -- ==========================================
    -- STATUS DO ALIEN_LE_PEP (DIREITA)
    -- ==========================================
    local trX = w - 24
    
    local barHP = getProgressBar(myHealth, 20, 10)
    local barFood = getProgressBar(myFood, 20, 10)
    
    writeData(trX, 3, "OP  :: ", C_AZUL_CLARO, string.sub(meuNick, 1, 14), C_BRANCO, 17)
    writeData(trX, 4, "XYZ :: ", C_AZUL_CLARO, myX..","..myY..","..myZ, C_BRANCO, 17)
    writeData(trX, 5, "VEL :: ", C_AZUL_CLARO, speed .. " b/s", C_BRANCO, 17)
    writeData(trX, 7, "HP  :: ", C_AZUL_CLARO, barHP, myHealth <= 6 and C_VERMELHO or C_VERDE, 17)
    writeData(trX, 8, "FD  :: ", C_AZUL_CLARO, barFood, myFood <= 6 and C_ALERTA or C_AMARELO, 17)

    local jStatus = sigeonAtivo and "[ ONLINE ]" or "[ OFFLINE ]"
    local jColor = sigeonAtivo and C_VERDE or C_CINZA
    writeData(trX, 10, "A.I :: ", C_AZUL_CLARO, jStatus, jColor, 17)

    -- ==========================================
    -- LOG DE ALVOS (INFERIOR DIREITO)
    -- ==========================================
    local brY = h - 6
    hud.setCursorPos(w - 24, brY)
    hud.setTextColour(C_AZUL_CLARO)
    hud.write("AMEACAS PROXIMAS:")

    local row = 1
    local printados = 0
    for _, alvo in ipairs(dadosRadar) do
        if alvo.dM <= raioAlerta and printados < 4 then
            local elev = "-"
            if alvo.dyM > 4 then elev = "^" elseif alvo.dyM < -4 then elev = "v" end
            
            writeData(w - 24, brY + row, "[!]", C_ALERTA, " " .. elev .. " " .. string.sub(alvo.nome, 1, 10) .. " " .. alvo.dM .. "m", C_VERMELHO, 25)
            row = row + 1
            printados = printados + 1
        end
    end
    for r = row, 4 do writeData(w - 24, brY + r, "", C_BRANCO, "", C_BRANCO, 25) end
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.cyan)
print("======================================")
print(" RED_INDUSTRIES :: ALIEN EDITION")
print("======================================")
term.setTextColor(colors.white)
print(" > Focado exclusivamente no operador.")
print(" > Assistente Sigeon pex online.")
print(" > [S] Liga/Desliga Sigeon pex.")
print(" > [Q] Desliga o HUD.")

drawStaticHUD() 

local running = true
local timer = os.startTimer(0.1)

while running do
    local event, p1 = os.pullEvent()

    if event == "timer" and p1 == timer then
        updateDynamicHUD() 
        timer = os.startTimer(0.1)
    elseif event == "key" then
        if p1 == keys.q then
            running = false
        elseif p1 == keys.s then
            sigeonAtivo = not sigeonAtivo
            if not sigeonAtivo then
                sigeonAtual = "" 
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
print("Visor ALIEN encerrado.")
