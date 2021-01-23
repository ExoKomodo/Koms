import asyncdispatch
import asyncnet
import os
import parseopt

import komslib


type
  Args = tuple
    address: string
    is_server: bool
  
func is_valid(self: Args): bool = self.address != ""

proc parse_args: Args =
  if paramCount() == 0:
    quit("Please specify the server address (e.g. ./client --address=localhost)")
  
  var parser = initOptParser()
  while (parser.next(); true):
    case parser.kind
    of cmdLongOption:
      case parser.key
        of "address":
          result.address = parser.val.string
        of "server":
          result.is_server = true
    of cmdEnd:
      break
    else:
      continue


when isMainModule:
  let args = parseArgs()
  if not args.is_valid:
    quit("Failed to have valid args")
  
  echo "Koms has started..."
  if args.is_server:
    let server = new_server(
      args.address,
    )
    wait_for server.run()
  else:
    let client = new_client(
      args.address,
    )
    wait_for client.run()
