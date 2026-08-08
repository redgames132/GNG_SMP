-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (CYBERPUNK)
-- Sirene do Juizo Final & UI Tática
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

hud.setSize(100, 50) 

-- ==========================================
-- CONFIGURAÇÕES DA EQUIPE
-- ==========================================
local meuNick = "redgames132"
local raioAlerta = 200

-- Whitelist (Não disparam o alarme)
local aliados = {
    ["redgames132"] = true,
    ["KAIOX_NEGROX"] = true,
    ["goonerstickle69"] = true,
    ["cadipadi"] = true
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

-- ==========================================
-- DESENHO DO HUD
-- ==========================================
local function drawHUD()
    hud.setBackgroundColour(C_FUNDO)
    hud.clear()

    local myX, myY, myZ = baseX, baseY, baseZ
    local players = {}
    local inimigosProximos = 0
    
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

    local hexCode = string.format("0x%04X", math.random(0, 65535))

    -- TOPO: CABEÇALHO
    hud.setCursorPos(1, 1)
    hud.setTextColour(C_VERMELHO)
    hud.write("+======[ ")
    hud.setTextColour(C_BRANCO)
    hud.write("RED_INDUSTRIES :: CORE_OS")
    hud.setTextColour(C_VERMELHO)
    hud.write(" ]======+")

    hud.setCursorPos(1, 2)
    hud.setTextColour(C_VERMELHO)
    hud.write("| ")
    hud.setTextColour(C_CINZA)
    hud.write("SYS > ")
    hud.setTextColour(C_VERDE)
    hud.write("ONLINE ")
    hud.setTextColour(C_CINZA)
    hud.write(" // ")
    hud.setTextColour(C_ALERTA)
    hud.write(hexCode)
    hud.setTextColour(C_CINZA)
    hud.write(" // TICK: ")
    hud.setTextColour(C_BRANCO)
    hud.write(formatTime(os.time()))
    hud.setCursorPos(44, 2)
    hud.setTextColour(C_VERMELHO)
    hud.write("|")

    hud.setCursorPos(1, 3)
    hud.setTextColour(C_VERMELHO)
    hud.write("+-------------------------------------------+")

    -- MEIO: TELEMETRIA
    hud.setCursorPos(1, 4)
    hud.setTextColour(C_VERMELHO)
    hud.write("| ")
    hud.setTextColour(C_CINZA)
    hud.write("COORD :: ")
    hud.setTextColour(C_CYAN)
    hud.write(string.format("X:%-5s Y:%-3s Z:%-6s", myX, myY, myZ))
    hud.setCursorPos(44, 4)
    hud.setTextColour(C_VERMELHO)
    hud.write("|")

    hud.setCursorPos(1, 5)
    hud.setTextColour(C_VERMELHO)
    hud.write("| ")
    hud.setTextColour(C_CINZA)
    hud.write("SPEED :: ")
    hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-4s", speed .. "b/s"))
    hud.setTextColour(C_CINZA)
    hud.write(" | DIR :: ")
    hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-13s", compass))
    hud.setCursorPos(44, 5)
    hud.setTextColour(C_VERMELHO)
    hud.write("|")

    hud.setCursorPos(1, 6)
    hud.setTextColour(C_VERMELHO)
    hud.write("+======[ ")
    hud.setTextColour(C_BRANCO)
    hud.write("TACTICAL_RADAR (100m)")
    hud.setTextColour(C_VERMELHO)
    hud.write(" ]=========+")

    -- BASE: RADAR E SIRENE DE TERROR
    if detector then
        local row = 7
        
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

        -- ==========================================
        -- SIRENE DO JUÍZO FINAL
        -- Toca no volume 3.0 (Máximo) e alterna os sons
        -- ==========================================
        if inimigosProximos > 0 and speaker then
            if frame % 8 == 0 then
                -- Som do Wither (Grave e aterrorizante)
                speaker.playSound("entity.wither.spawn", 3.0, 0.5)
            elseif frame % 8 == 4 then
                -- Som de Sino e Grito do Ghast distorcido
                speaker.playSound("block.bell.resonate", 3.0, 0.5)
                speaker.playSound("entity.ghast.scream", 3.0, 0.6)
            end
        end

        hud.setCursorPos(1, 7)
        hud.setTextColour(C_VERMELHO)
        hud.write("| ")
        hud.setTextColour(C_CINZA)
        hud.write("STATE :: ")
        if inimigosProximos > 0 then
            hud.setTextColour(frame % 2 == 0 and C_ALERTA or C_VERMELHO)
            hud.write(string.format("%-30s", "[ AMEACA DETECTADA ]"))
        else
            hud.setTextColour(C_VERDE)
            hud.write(string.format("%-30s", "[ PERIMETRO SEGURO ]"))
        end
        hud.setCursorPos(44, 7)
        hud.setTextColour(C_VERMELHO)
        hud.write("|")

        local mostrados = 0
        for _, p in ipairs(players) do
            if p ~= meuNick then
                local sP, pos = pcall(detector.getPlayerPos, p)
                if sP and type(pos) == "table" and pos.x then
                    local dx, dy, dz = pos.x - myX, pos.y - myY, pos.z - myZ
                    local dist = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                    
                    hud.setCursorPos(1, row + 1)
                    
                    if dist <= raioAlerta then
                        hud.setTextColour(C_VERMELHO)
                        hud.write("| ")
                        if aliados[p] then
                            hud.setTextColour(C_VERDE)
                            hud.write(string.format("[O] %-15s %-5s <ALIADO> ", p, dist.."m"))
                        else
                            hud.setTextColour(C_ALERTA)
                            hud.write(string.format("[X] %-15s %-5s <HOSTIL> ", p, dist.."m"))
                        end
                        
                        hud.setCursorPos(44, row + 1)
                        hud.setTextColour(C_VERMELHO)
                        hud.write("|")
                        row = row + 1
                        mostrados = mostrados + 1
                    end
                    if mostrados >= 5 then break end
                end
            end
        end
        
        hud.setCursorPos(1, row + 1)
        hud.setTextColour(C_VERMELHO)
        hud.write("+===========================================+")
    end
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.red)
print("======================================")
print(" RED_INDUSTRIES :: SISTEMA DE TERROR")
print("======================================")
term.setTextColor(colors.white)
print(" > Alarme Nivel Wither configurado.")
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
print("Sistema encerrado.")
