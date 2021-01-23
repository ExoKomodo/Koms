import json
import komslib/protocol
import unittest

    
const message = "hello"
const username = "james"
const example = "{\"username\":\"" & username & "\",\"message\":\"" & message & "\"}" & message_suffix

test "General test":
  checkpoint("Parsing...")
  let parsed = example.new_message()
  checkpoint("Parsed")

  checkpoint("username validation...")
  assert parsed.username == username
  checkpoint("username validated")

  checkpoint("message validation...")
  assert parsed.message == message
  checkpoint("message validated")

test "Stringify message":  
  checkpoint("Parsing...")
  let data = new_message(username, message)
  checkpoint("Parsed")
  
  checkpoint("Stringifying and checking against expected value...")
  assert example == data.stringify()
  checkpoint("Checked")

test "Bad JSON":
  let data = """foobar"""
  try:
    checkpoint("Parsing...")
    discard data.new_message()
    checkpoint("Parsed")
    
    assert false
  except JsonParsingError:
    assert true
  except:
    assert false
