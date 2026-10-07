-- lan play. udp discovery, tcp game connection, host relays.

local json = require("json")

local lan = {}

local DISCOVERY_PORT = 23400
local GAME_PORT = 23401
local MAX_PLAYERS = 4
local ANNOUNCE_INTERVAL = 1000
local GAME_TIMEOUT = 4000
local GO_TIMEOUT = 10000
local MAX_BUFFERED_EVENTS = 200

local socket
do
  local ok, library = pcall(require, "socket")
  if ok then
    socket = library
  end
end

local role
local handler
local pending = {}
local playerName = ""

local server, announcer
local clients = {}
local hostPlayer
local mapId = 1
local started = false
local lastAnnounce = 0
local goDeadline

local connection
local joining = false
local joinDeadline

local scanner
local found = {}

function lan.isAvailable()
  return socket ~= nil
end

function lan.getRole()
  return role
end

function lan.isActive()
  return role ~= nil
end

function lan.getName()
  return playerName
end

function lan.isStarted()
  return started
end

function lan.getMap()
  return mapId
end

local function emit(event)
  if handler then
    handler(event)
  else
    pending[#pending + 1] = event
    if #pending > MAX_BUFFERED_EVENTS then
      table.remove(pending, 1)
    end
  end
end

function lan.setHandler(fn)
  handler = fn
  if handler then
    local events = pending
    pending = {}
    for _, event in ipairs(events) do
      handler(event)
    end
  end
end

local function queue(link, message)
  link.out = link.out .. json.encode(message) .. "\n"
end

local function flush(link)
  if link.out == "" then
    return true
  end
  local sent, err, partial = link.sock:send(link.out)
  if sent then
    link.out = ""
    return true
  elseif err == "timeout" then
    link.out = link.out:sub((partial or 0) + 1)
    return true
  end
  return false
end

local function receive(link)
  local messages = {}
  local open = true
  while true do
    local data, err, partial = link.sock:receive(8192)
    data = data or partial
    if data and #data > 0 then
      link.buffer = link.buffer .. data
    end
    if err == "closed" then
      open = false
    end
    if err then
      break
    end
  end
  while true do
    local line, rest = link.buffer:match("^([^\n]*)\n(.*)$")
    if not line then
      break
    end
    link.buffer = rest
    local ok, message = pcall(json.decode, line)
    if ok and type(message) == "table" then
      messages[#messages + 1] = message
    end
  end
  return messages, open
end

local function newLink(sock)
  sock:settimeout(0)
  pcall(sock.setoption, sock, "tcp-nodelay", true)
  return { sock = sock, buffer = "", out = "" }
end

local function closeLink(link)
  if link and link.sock then
    pcall(link.sock.close, link.sock)
    link.sock = nil
  end
end

local function lobbyPacket()
  local players = { hostPlayer }
  for _, c in ipairs(clients) do
    if c.joined then
      players[#players + 1] = { n = c.name, a = c.avatar }
    end
  end
  return { t = "lobby", players = players, map = mapId, started = started }
end

local function joinedCount()
  local count = 1
  for _, c in ipairs(clients) do
    if c.joined then
      count = count + 1
    end
  end
  return count
end

local function broadcast(message, except)
  for _, c in ipairs(clients) do
    if c.joined and c ~= except then
      queue(c, message)
    end
  end
end

local function broadcastLobby()
  local packet = lobbyPacket()
  broadcast(packet)
  emit({ type = "lobby", players = packet.players, map = packet.map })
end

local function uniqueName(wanted)
  local function taken(name)
    if name:lower() == hostPlayer.n:lower() then
      return true
    end
    for _, c in ipairs(clients) do
      if c.joined and c.name:lower() == name:lower() then
        return true
      end
    end
    return false
  end
  local name, number = wanted, 1
  while taken(name) do
    number = number + 1
    name = wanted:sub(1, 12) .. number
  end
  return name
end

local function removeClient(client, reason)
  for i, c in ipairs(clients) do
    if c == client then
      table.remove(clients, i)
      break
    end
  end
  closeLink(client)
  if client.joined then
    client.joined = false
    if started then
      broadcast({ t = "gone", name = client.name })
      emit({ type = "gone", name = client.name })
    else
      broadcastLobby()
    end
  end
end

local function sendGo()
  goDeadline = nil
  broadcast({ t = "go" })
  emit({ type = "go" })
end

local function checkAllReady()
  if not goDeadline then
    return
  end
  for _, c in ipairs(clients) do
    if c.joined and not c.ready then
      return
    end
  end
  if hostReady then
    sendGo()
  end
end

local function handleClientMessage(client, message)
  local t = message.t
  if t == "join" then
    if client.joined then
      return
    end
    if started then
      queue(client, { t = "refused", reason = "started" })
    elseif joinedCount() >= MAX_PLAYERS then
      queue(client, { t = "refused", reason = "full" })
    else
      client.name = uniqueName(tostring(message.name or "Player"):sub(1, 15))
      client.avatar = message.avatar or { 1, 1, 1, 1 }
      client.joined = true
      queue(client, { t = "welcome", name = client.name })
      broadcastLobby()
    end
  elseif not client.joined then
    return
  elseif t == "hello" then
    queue(client, lobbyPacket())
  elseif t == "ready" then
    client.ready = true
    checkAllReady()
  elseif t == "leave" then
    removeClient(client)
  elseif t == "r" and message.msg then
    broadcast(message, client)
    emit({ type = "race", msg = message.msg })
  end
end

local function hostUpdate(now)

  while true do
    local sock = server:accept()
    if not sock then
      break
    end
    local client = newLink(sock)
    client.joined = false
    clients[#clients + 1] = client
  end

  for _, client in ipairs({ unpack(clients) }) do
    if client.sock then
      local messages, open = receive(client)
      for _, message in ipairs(messages) do
        if client.sock then
          handleClientMessage(client, message)
        end
      end
      if open and client.sock and not flush(client) then
        open = false
      end
      if not open then
        removeClient(client)
      end
    end
  end

  if announcer and now - lastAnnounce >= ANNOUNCE_INTERVAL then
    lastAnnounce = now
    local packet = json.encode({
      t = "fr1", name = hostPlayer.n, port = GAME_PORT, players = joinedCount(), started = started,
    })
    pcall(announcer.sendto, announcer, packet, "255.255.255.255", DISCOVERY_PORT)
    pcall(announcer.sendto, announcer, packet, "127.0.0.1", DISCOVERY_PORT)
  end
  if goDeadline and now > goDeadline then
    sendGo()
  end
end

function lan.host(name, avatar)
  if not socket then
    return false, "unavailable"
  end
  lan.leave()
  local listener, err = socket.bind("*", GAME_PORT)
  if not listener then
    return false, tostring(err)
  end
  listener:settimeout(0)
  server = listener
  announcer = socket.udp()
  if announcer then
    announcer:settimeout(0)
    pcall(announcer.setoption, announcer, "broadcast", true)
  end
  role = "host"
  playerName = name
  hostPlayer = { n = name, a = avatar }
  clients = {}
  started = false
  goDeadline = nil
  pending = {}
  lastAnnounce = 0
  return true
end

function lan.setMap(id)
  if role == "host" and not started then
    mapId = id
    broadcastLobby()
  end
end

function lan.getPlayers()
  if role == "host" then
    return lobbyPacket().players
  end
end

function lan.start()
  if role ~= "host" or started or joinedCount() < 2 then
    return false
  end
  started = true
  hostReady = false
  for _, c in ipairs(clients) do
    c.ready = false
  end
  local players = lobbyPacket().players
  broadcast({ t = "start", map = mapId, players = players })
  emit({ type = "start", map = mapId, players = players })
  goDeadline = system.getTimer() + GO_TIMEOUT
  return true
end

local function clientUpdate(now)
  if not connection then
    return
  end
  local messages, open = receive(connection)
  for _, message in ipairs(messages) do
    local t = message.t
    if t == "welcome" then
      joining = false
      playerName = message.name
      emit({ type = "joined", name = message.name })
    elseif t == "refused" then
      joining = false
      lan.leave()
      emit({ type = "closed", reason = message.reason or "refused" })
      return
    elseif t == "lobby" then
      started = message.started and true or false
      mapId = message.map or mapId
      emit({ type = "lobby", players = message.players, map = message.map })
    elseif t == "start" then
      started = true
      emit({ type = "start", map = message.map, players = message.players })
    elseif t == "go" then
      emit({ type = "go" })
    elseif t == "gone" then
      emit({ type = "gone", name = message.name })
    elseif t == "r" and message.msg then
      emit({ type = "race", msg = message.msg })
    end
  end
  if open and not flush(connection) then
    open = false
  end
  if not open then
    lan.leave()
    emit({ type = "closed", reason = "lost" })
    return
  end
  if joining and now > joinDeadline then
    lan.leave()
    emit({ type = "closed", reason = "timeout" })
  end
end

function lan.join(ip, port, name, avatar)
  if not socket then
    return false, "unavailable"
  end
  lan.leave()
  local sock = socket.tcp()
  sock:settimeout(1.5)
  local ok, err = sock:connect(ip, port or GAME_PORT)
  if not ok then
    pcall(sock.close, sock)
    return false, tostring(err)
  end
  connection = newLink(sock)
  role = "client"
  playerName = name
  started = false
  joining = true
  joinDeadline = system.getTimer() + GAME_TIMEOUT
  pending = {}
  queue(connection, { t = "join", name = name, avatar = avatar })
  return true
end

function lan.requestLobby()
  if role == "host" then
    started = false
    broadcastLobby()
  elseif role == "client" and connection then
    queue(connection, { t = "hello" })
  end
end

function lan.sendReady()
  if role == "host" then
    hostReady = true
    checkAllReady()
  elseif role == "client" and connection then
    queue(connection, { t = "ready" })
  end
end

function lan.sendRace(msg)
  if role == "host" then
    broadcast({ t = "r", msg = msg })
  elseif role == "client" and connection then
    queue(connection, { t = "r", msg = msg })
  end
end

function lan.leave()
  if role == "client" and connection and connection.sock then
    queue(connection, { t = "leave" })
    flush(connection)
  end
  for _, c in ipairs(clients) do
    queue(c, { t = "refused", reason = "hostLeft" })
    flush(c)
    closeLink(c)
  end
  clients = {}
  closeLink(connection)
  connection = nil
  if server then
    pcall(server.close, server)
    server = nil
  end
  if announcer then
    pcall(announcer.close, announcer)
    announcer = nil
  end
  role = nil
  started = false
  joining = false
  goDeadline = nil
end

function lan.startScan()
  if not socket or scanner then
    return
  end
  scanner = socket.udp()
  if not scanner then
    return
  end
  pcall(scanner.setoption, scanner, "reuseaddr", true)
  if not scanner:setsockname("*", DISCOVERY_PORT) then
    scanner:close()
    scanner = nil
    return
  end
  scanner:settimeout(0)
  found = {}
end

function lan.stopScan()
  if scanner then
    pcall(scanner.close, scanner)
    scanner = nil
  end
  found = {}
end

function lan.getFound()
  local now = system.getTimer()
  local list = {}
  for key, game in pairs(found) do
    if now - game.seen > 3000 then
      found[key] = nil
    elseif not game.started and game.players < MAX_PLAYERS then
      list[#list + 1] = game
    end
  end
  table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
  return list
end

local function scanUpdate(now)
  if not scanner then
    return
  end
  for _ = 1, 20 do
    local data, ip = scanner:receivefrom()
    if not data then
      break
    end
    local ok, packet = pcall(json.decode, data)
    if ok and type(packet) == "table" and packet.t == "fr1" and packet.port then
      found[ip .. ":" .. packet.port] = {
        ip = ip, port = packet.port, name = tostring(packet.name), players = packet.players or 1,
        started = packet.started, seen = now,
      }
    end
  end
end

function lan.getLocalIP()
  if not socket then
    return nil
  end
  local udp = socket.udp()
  if not udp then
    return nil
  end
  local ip
  if pcall(udp.setpeername, udp, "8.8.8.8", 80) then
    ip = udp:getsockname()
  end
  udp:close()
  if ip == "0.0.0.0" then
    ip = nil
  end
  return ip
end

local function onFrame()
  local now = system.getTimer()
  if role == "host" and server then
    hostUpdate(now)
  elseif role == "client" then
    clientUpdate(now)
  end
  scanUpdate(now)
end

Runtime:addEventListener("enterFrame", onFrame)

return lan
