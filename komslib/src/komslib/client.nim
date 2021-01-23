import asyncdispatch
import asyncnet
import strformat
import threadpool

import ./protocol

type
  Client* = ref object
    server_address: string
    port: Port
    id: int
    is_connected*: bool
    socket: AsyncSocket

proc new_client*(
  server_address: string;
  port: Port | uint16 = 7687;
  socket: AsyncSocket = newAsyncSocket();
  id: int = -1;
): Client = Client(
  server_address: server_address,
  port: Port(port),
  id: id,
  is_connected: false,
  socket: socket,
)

proc `$`*(self: Client): string =
  fmt"[{self.id} - {self.server_address}:{self.port.int}]"

func server_address*(self: Client): auto = self.server_address
func id*(self: Client): auto = self.id
func port*(self: Client): auto = self.port
func socket*(self: Client): auto = self.socket

proc close*(self: Client) = self.socket.close()

proc connect(self: Client) {.async.} =
  echo fmt"Connecting to {self}..."
  await self.socket.connect(self.server_address, self.port)
  echo "Connected!"

  while true:
    let line = await self.socket.recvLine()
    let parsed = line.new_message()
    echo(parsed.username, " said ", parsed.message)

proc send*(self: Client; message: Message) {.async.} =
  await self.socket.send(message.stringify())

proc run*(self: Client) {.async.} =
  asyncCheck self.connect()
  var message_flow = spawn stdin.readLine()
  
  while true:
    if message_flow.is_ready():
      let msg = new_message("Anonymous", ^message_flow)
      asyncCheck self.send(msg)
      message_flow = spawn stdin.readLine()
    poll()
