import os
import parseopt
import strformat

type
  Args = tuple
    address: string

proc connect(address: string) =
  echo fmt"Connecting to {address}"

proc parseArgs: Args =
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
        result = (parser.val.string,)
    of cmdEnd:
      break
    else:
      continue

when isMainModule:
  echo "Koms has started..."
  let args = parseArgs()
  
  args.address.connect()