from sugar import `=>`

import asyncdispatch
import asyncnet
import std/exitprocs
import strformat
import threadpool

import ./protocol

type
  Client* = ref object
    server_address: string
    port: Port
    id: int
    is_connected: bool
    socket: AsyncSocket
    username: string

proc is_connected*(self: Client): auto = self.is_connected

proc username*(self: Client): auto = self.username
proc `username=`*(self: Client; value: string) = self.username = value

proc new_client*(
  username: string;
  server_address: string;
  port: Port | uint16 = 7687;
  socket: AsyncSocket = newAsyncSocket();
  id: int = -1;
  is_connected: bool = false;
): Client = Client(
  server_address: server_address,
  port: Port(port),
  id: id,
  is_connected: is_connected,
  socket: socket,
  username: username,
)

proc `$`*(self: Client): string =
  fmt"[{self.username} - {self.id} - {self.server_address} :{self.port.int}]"

func server_address*(self: Client): auto = self.server_address
func id*(self: Client): auto = self.id
func port*(self: Client): auto = self.port
func socket*(self: Client): auto = self.socket

proc close*(self: Client; quiet: bool = false) =
  if not quiet:
    echo "Disconnecting..."
  self.socket.close()
  self.is_connected = false
  if not quiet:
    echo "Disconnected"

proc connect(self: Client) {.async.} =
  echo fmt"Connecting to {self.server_address}:{self.port.int}..."
  asyncCheck self.socket.connect(self.server_address, self.port)
  echo "Connected!"
  self.is_connected = true

  while true:
    try:
      let line = await self.socket.recvLine()
      let parsed = line.new_message()
      echo fmt"{parsed.username}: {parsed.message}"
    except:
      self.close()
      return

proc send*(self: Client; message: Message) {.async.} =
  await self.socket.send(message.stringify())

proc run*(self: Client) {.async.} =
  add_exit_proc(() => self.close())
  set_control_c_hook(() {.noconv.} => quit())
  asyncCheck self.connect()
  var message_flow = spawn stdin.readLine()
  
  while self.is_connected:
    if message_flow.is_ready():
      let msg = new_message(self.username, ^message_flow)
      asyncCheck self.send(msg)
      message_flow = spawn stdin.readLine()
    poll()
