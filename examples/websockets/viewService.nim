import nerve, nerve/promises

service ViewService, "/view":

  proc newMessage(msg: string): Future[string] =
    echo "Message: " & msg
    result = fwrap(msg)
