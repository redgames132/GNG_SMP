-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (ANTI-LAG)
-- Buffer Ativo = Zero Piscar (Flicker)
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

-- ==========================================
-- CONFIGURAÇÕES DA TELA (BUFFER INVISÍVEL)
-- ==========================================
hud.setSize(100, 50)
local w, h = hud.getSize()

-- Cria a janela invisível na memória para impedir a tela de piscar
local buffer = window.create(hud, 1, 1, w, h, false)

-- ==========================================
-- CONFIGURAÇÕES DA EQUIPE
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
local startTime = os.clock()

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
    if math.abs(dx) > math.abs(dz) then return dx > 0 and "L" or "O"
    else return dz > 0 and "S" or "N" end
end

-- Pré-calcula os pontos do círculo do Minimapa
local radarCX, radarCY = 14, 9
local visualRadius = 7
local circlePoints = {}
for i = 0, 359, 10 do
    local rad = math.rad(i)
    local px = radarCX + math.floor(math.cos(rad) * visualRadius * 1.5)
    local py = radarCY + math.floor(math.sin(rad) * visualRadius)
    table.insert(circlePoints, {x = px, y = py})
end

-- ==========================================
-- DESENHO DO HUD DE COMBATE NO BUFFER
-- ==========================================
local function drawHUD()
    -- Começa a desenhar na tela invisível
    buffer.setVisible(false)
    buffer.setBackgroundColor(C_FUNDO)
    buffer.clear()

    local myX, myY, myZ = baseX, baseY, baseZ
    local players = {}
    local inimigosProximos = 0
    
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
        local suc, pList = pcall(detector.getOnlinePlayers)
        if suc and type(pList) == "table" then players = pList end
    end

    local distBase = math.floor(math.sqrt((myX - baseX)^2 + (myY - baseY)^2 + (myZ - baseZ)^2))

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

    if inimigosProximos > 0 and speaker then
        if frame % 10 == 0 then speaker.playSound("entity.wither.spawn", 3.0, 0.5)
        elseif frame % 10 == 5 then 
            speaker.playSound("block.bell.resonate", 3.0, 0.5)
            speaker.playSound("entity.ghast.scream", 3.0, 0.6)
        end
    end

    local hexCode = string.format("0x%04X", math.random(0, 65535))
    local colorTheme = inimigosProximos > 0 and C_VERMELHO or C_CYAN

    -- 1. DECORAÇÕES CENTRAIS (MIRA)
    local midX = math.floor(w/2)
    local midY = math.floor(h/2)
    
    buffer.setTextColor(colorTheme)
    buffer.setCursorPos(midX - 10, midY - 2) buffer.write("/")
    buffer.setCursorPos(midX - 12, midY)     buffer.write("[")
    buffer.setCursorPos(midX - 10, midY + 2) buffer.write("\\")
    
    buffer.setCursorPos(midX + 10, midY - 2) buffer.write("\\")
    buffer.setCursorPos(midX + 12, midY)     buffer.write("]")
    buffer.setCursorPos(midX + 10, midY + 2) buffer.write("/")

    -- 2. CANTO SUPERIOR ESQUERDO (MINIMAPA 2D)
    buffer.setCursorPos(1, 1)
    buffer.setTextColor(C_VERMELHO)
    buffer.write("+--[ ")
    buffer.setTextColor(C_BRANCO)
    buffer.write("MINIMAPA (" .. raioAlerta .. "m)")
    buffer.setTextColor(C_VERMELHO)
    buffer.write(" ]--+")

    buffer.setTextColor(C_CINZA)
    for _, pt in ipairs(circlePoints) do
        buffer.setCursorPos(pt.x, pt.y)
        buffer.write(".")
    end
    
    buffer.setCursorPos(radarCX, radarCY)
    buffer.setTextColor(C_BRANCO)
    buffer.write("+")
    buffer.setCursorPos(radarCX, radarCY - visualRadius) buffer.setTextColor(C_CINZA) buffer.write("N")
    buffer.setCursorPos(radarCX, radarCY + visualRadius) buffer.write("S")

    local radarLog = {}
    for _, p in ipairs(players) do
        if p ~= meuNick then
            local sP, pos = pcall(detector.getPlayerPos, p)
            if sP and type(pos) == "table" and pos.x then
                local dx, dz = pos.x - myX, pos.z - myZ
                local dist = math.floor(math.sqrt((dx*dx) + ((pos.y - myY)^2) + (dz*dz)))
                
                if dist <= raioAlerta then
                    local scale = visualRadius / raioAlerta
                    local plotX = radarCX + math.floor(dx * scale * 1.5)
                    local plotY = radarCY + math.floor(dz * scale)
                    
                    buffer.setCursorPos(plotX, plotY)
                    if aliados[p] then
                        buffer.setTextColor(C_VERDE)
                        buffer.write("O")
                    else
                        buffer.setTextColor(C_ALERTA)
                        buffer.write("X")
                    end
                    table.insert(radarLog, {nome = p, d = dist, aliado = aliados[p]})
                end
            end
        end
    end

    -- 3. CANTO INFERIOR ESQUERDO (LOG DE AMEAÇAS)
    local blY = h - 6
    buffer.setCursorPos(1, blY)
    buffer.setTextColor(C_VERMELHO)
    buffer.write("+--[ ")
    buffer.setTextColor(C_BRANCO)
    buffer.write("LOG DE CONTATOS")
    buffer.setTextColor(C_VERMELHO)
    buffer.write(" ]")

    local row = 1
    for i, alvo in ipairs(radarLog) do
        if row <= 5 then
            buffer.setCursorPos(1, blY + row)
            buffer.setTextColor(C_VERMELHO)
            buffer.write("| ")
            if alvo.aliado then
                buffer.setTextColor(C_VERDE)
                buffer.write(string.format("[O] %-14s %-5s", alvo.nome, alvo.d.."m"))
            else
                buffer.setTextColor(C_ALERTA)
                buffer.write(string.format("[X] %-14s %-5s", alvo.nome, alvo.d.."m"))
            end
            row = row + 1
        end
    end
    if #radarLog == 0 then
        buffer.setCursorPos(1, blY + 1)
        buffer.setTextColor(C_VERMELHO)
        buffer.write("| ")
        buffer.setTextColor(C_CINZA)
        buffer.write("PERIMETRO LIMPO.")
    end

    -- 4. CANTO SUPERIOR DIREITO (TELEMETRIA E DADOS)
    local trX = w - 30
    buffer.setCursorPos(trX, 1)
    buffer.setTextColor(colorTheme)
    buffer.write("[ ")
    buffer.setTextColor(C_BRANCO)
    buffer.write("DADOS DO TRAJE")
    buffer.setTextColor(colorTheme)
    buffer.write(" ]--+")

    buffer.setCursorPos(trX, 2)
    buffer.setTextColor(C_CINZA)
    buffer.write("  XYZ   : ")
    buffer.setTextColor(C_BRANCO)
    buffer.write(string.format("%-21s", myX .. "," .. myY .. "," .. myZ))
    buffer.setTextColor(colorTheme)
    buffer.write("|")

    buffer.setCursorPos(trX, 3)
    buffer.setTextColor(C_CINZA)
    buffer.write("  VELOC : ")
    buffer.setTextColor(C_BRANCO)
    buffer.write(string.format("%-12s", speed .. " b/s"))
    buffer.setTextColor(C_CYAN)
    buffer.write(string.format("%-9s", compass))
    buffer.setTextColor(colorTheme)
    buffer.write("|")

    buffer.setCursorPos(trX, 4)
    buffer.setTextColor(C_CINZA)
    buffer.write("  D.BASE: ")
    buffer.setTextColor(C_ALERTA)
    buffer.write(string.format("%-21s", distBase .. "m"))
    buffer.setTextColor(colorTheme)
    buffer.write("|")

    buffer.setCursorPos(trX, 5)
    buffer.setTextColor(C_CINZA)
    buffer.write("  ARMOR : ")
    buffer.setTextColor(C_VERDE)
    buffer.write(string.format("%-21s", "100% [||||||||]"))
    buffer.setTextColor(colorTheme)
    buffer.write("|")

    buffer.setCursorPos(trX, 6)
    buffer.write("-------------------------+")

    -- 5. CANTO INFERIOR DIREITO (SISTEMA DE REDE)
    local brY = h - 4
    local brX = w - 30

    buffer.setCursorPos(brX, brY)
    buffer.setTextColor(C_VERMELHO)
    buffer.write("[ ")
    buffer.setTextColor(C_BRANCO)
    buffer.write("SISTEMA CORE_OS")
    buffer.setTextColor(C_VERMELHO)
    buffer.write(" ]--+")

    buffer.setCursorPos(brX, brY + 1)
    buffer.setTextColor(C_CINZA)
    buffer.write("  SYNC : ")
    buffer.setTextColor(C_BRANCO)
    buffer.write(string.format("%-21s", "IRL " .. os.date("%H:%M") .. " | MC " .. formatTime(os.time())))
    buffer.setTextColor(C_VERMELHO)
    buffer.write("|")

    buffer.setCursorPos(brX, brY + 2)
    buffer.setTextColor(C_CINZA)
    buffer.write("  UPT  : ")
    buffer.setTextColor(C_CYAN)
    buffer.write(string.format("%-21s", formatUptime(os.clock() - startTime)))
    buffer.setTextColor(C_VERMELHO)
    buffer.write("|")

    buffer.setCursorPos(brX, brY + 3)
    buffer.setTextColor(C_CINZA)
    buffer.write("  PING : ")
    buffer.setTextColor(C_VERDE)
    buffer.write(string.format("%-21s", math.random(12, 18) .. "ms"))
    buffer.setTextColor(C_VERMELHO)
    buffer.write("|")

    buffer.setCursorPos(brX, brY + 4)
    buffer.setTextColor(C_CINZA)
    buffer.write("  HASH : ")
    buffer.setTextColor(C_ALERTA)
    buffer.write(string.format("%-21s", hexCode))
    buffer.setTextColor(C_VERMELHO)
    buffer.write("|")
    
    -- Empurra toda a imagem invisível para a tela de uma vez só
    buffer.setVisible(true)
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.red)
print("======================================")
print(" RED_INDUSTRIES :: COMBAT VISOR (BUFFERED)")
print("======================================")
term.setTextColor(colors.white)
print(" > Anti-Flicker (Buffer) Ativado.")
print(" > Pressione [Q] para DESLIGAR.")

local running = true
local timer = os.startTimer(0.1) 

while running do
    local event, p1 = os.pullEvent()

    if event == "timer" and p1 == timer then
        drawHUD()
        frame = frame + 1
        timer = os.startTimer(0.1)
    elseif event == "key" then
        if p1 == keys.q then
            running = false
        end
    end
end

-- Limpa a tela antes de sair
buffer.setVisible(false)
buffer.setBackgroundColor(C_FUNDO)
buffer.clear()
buffer.setVisible(true)

term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.lime)
print("Visor de Combate encerrado.")
