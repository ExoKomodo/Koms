from nativesockets import Port
from sugar import `=>`

import asyncdispatch
import asyncnet
import locks
import sequtils
import std/exitprocs
import strformat

import ./client
import ./protocol

proc next_client_id(): int =
  var client_id {.global.}: int = 0
  client_id.atomicInc()
  client_id

const ServerUsername = "SERVER"

type
  Server* = ref object
    address: string
    clients: seq[Client]
    client_lock: Lock
    port: Port
    socket: AsyncSocket
    is_running: bool

proc new_server*(
  address: string;
  port: Port = Port(7687);
): Server =
  result = Server(
    address: address,
    clients: @[],
    port: port,
    socket: newAsyncSocket(),
  )
  result.client_lock.init_lock()

proc stub_client(self: Server): Client =
  new_client(
    ServerUsername,
    self.address,
    self.port,
    nil,
  )

proc send(
  self: Server;
  msg: Message;
  sender: Client = self.stub_client();
) {.async.} =
  self.client_lock.acquire()
  for c in self.clients:
    if c.id == sender.id:
      c.username = msg.username
    elif c.is_connected:
      await c.send(msg)
  self.client_lock.release()

proc process_messages(
  self: Server;
  sender: Client;
) {.async.} =
  while true:
    let line = await sender.socket.recvLine()
    if line.len == 0:
      sender.close()
      let disconnect_msg = fmt"{sender} disconnected"
      echo disconnect_msg
      asyncCheck self.send(new_message(ServerUsername, disconnect_msg))
      return
    let msg = line.new_message()
    sender.username = msg.username
    echo fmt"{sender}: {msg.message}"
    asyncCheck self.send(msg, sender)

proc accept(self: Server) {.async.} =
  let (address, client_socket) = await self.socket.acceptAddr()
  let acceptance = "Someone has joined the server"
  let msg = new_message(ServerUsername, acceptance)
  echo acceptance
  await self.send(msg)
  
  let client = new_client(
    "",
    address,
    socket=client_socket,
    id=next_client_id(),
    is_connected=true,
  )

  self.client_lock.acquire()
  self.clients &= client
  self.clients = self.clients.filter((c => c.is_connected))
  self.client_lock.release()

  asyncCheck self.process_messages(client)

proc close(self: Server) {.noconv.} =
  echo "Closing server..."
  for c in self.clients:
    c.close(quiet=true)
  echo "Server closed"

proc run*(self: Server) {.async.} =
  add_exit_proc(() => self.close())
  set_control_c_hook(() {.noconv.} => quit())
  echo "Starting server..."
  self.socket.bindAddr(
    self.port,
    self.address,
  )
  self.socket.listen()
  echo fmt"Listening at {self.address}:{self.port.int}"

  self.is_running = true
  while self.is_running:
    echo "Waiting for connection..."
    await self.accept()
