import os
import parseopt
import strformat
import threadpool


type
  Args = tuple
    address: string
    is_valid: bool

proc connect(address: string): bool =
  echo fmt"Connecting to {address}"
  true

proc send(message: string): bool =
  echo fmt"Sending: {message}"
  true

proc handle_message: bool =
  let message = spawn stdin.read_line()
  result = (^message).send()

proc parse_args: Args =
  if paramCount() == 0:
    quit("Please specify the server address (e.g. ./client localhost)")
  
  var parser = initOptParser()
  while (parser.next(); true):
    case parser.kind
    of cmdShortOption, cmdLongOption:
      case parser.val
      of "":
        echo "Option: ", parser.key
      else:
        result = (parser.val.string, true)
    of cmdEnd:
      break
    else:
      continue

when isMainModule:
  let args = parseArgs()
  
  if not args.is_valid:
    quit()
  
  echo "Koms has started..."
  if not args.address.connect():
    quit("Failed to connect!")
  echo fmt"Connected to {args.address}"

  while handle_message():
    continue
