import json


type
  Message* = object
    username*: string
    message*: string

const message_suffix* = "\c\l"

proc stringify*(self: Message): string =
  $(
    %{
      "username": %self.username,
      "message": %self.message,
    }
  ) & message_suffix

proc new_message*(data: string): Message =
  let data_json = data.parse_json()
  result = Message(
    username: data_json["username"].get_str(),
    message: data_json["message"].get_str(),
  )

proc new_message*(username: string, message: string): Message =
  Message(
    username: username,
    message: message,
  ).stringify().new_message()
