from nativesockets import Port

import asyncdispatch
import asyncnet
import strformat

import ./client
import ./protocol


type
  Server* = ref object
    address: string
    clients: seq[Client]
    port: Port
    socket: AsyncSocket
    is_running: bool

proc new_server*(
  address: string;
  port: Port = Port(7687);
): Server =
  Server(
    address: address,
    clients: @[],
    port: port,
    socket: newAsyncSocket(),
  )

proc process_messages(
  self: Server;
  client: Client;
) {.async.} =
  while true:
    let line = await client.socket.recvLine()
    if line.len == 0:
      echo(client, " disconnected")
      client.is_connected = false
      client.close()
      return
    let msg = line.new_message()
    echo(client, " ", msg.username, ": ", msg.message)
    for c in self.clients:
      if c.id != client.id and c.is_connected:
        await c.send(msg)

proc run*(self: Server) {.async.} =
  echo "Starting server..."
  self.socket.bindAddr(
    self.port,
    self.address
  )
  self.socket.listen()
  echo fmt"Listening at {self.address}:{self.port.int}"

  self.is_running = true
  while self.is_running:
    let (address, client_socket) = await self.socket.acceptAddr()
    echo fmt"Accepted connection from {address}"
    
    let client = new_client(
      address,
      socket=client_socket,
      id=self.clients.len,
    )
    self.clients &= client
    asyncCheck self.process_messages(client)
